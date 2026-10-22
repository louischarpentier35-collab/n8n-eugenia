#!/usr/bin/env python3
"""Stop hook: a launched autopilot task cannot end before a hostile-review verdict.

Silent (stop allowed) when: no task for this session, a phase where stopping is normal,
the task is waiting on Louis, or background jobs are still running (their notification wakes
Claude up: re-blocking meanwhile only re-reads the whole context for nothing). Blocks once;
a second stop with no progress marks the task stalled. Never crashes: any error lets the stop through.
"""
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402

STATE = f'python3 "{os.path.join(os.path.dirname(os.path.abspath(__file__)), "state.py")}"'


def desktop_notif(msg):
    if os.environ.get("AUTOPILOT_NO_DESKTOP_NOTIF"):
        return
    try:
        # the message is passed as an argument, never inside the script: a title can't inject AppleScript
        subprocess.run(["osascript", "-e", "on run argv", "-e",
                        'display notification (item 1 of argv) with title "Autopilot"', "-e", "end run",
                        msg], timeout=5, capture_output=True)
    except Exception:
        pass


def main():
    try:
        data = json.load(sys.stdin)
        session = data["session_id"]
    except Exception:
        return
    task = common.load(session)
    if not task:
        return
    if data.get("transcript_path") and task.get("transcript") != data["transcript_path"]:
        task["transcript"] = data["transcript_path"]
        common.save(task, touch=False)
    if task.get("phase") not in common.WORKING or task.get("waiting_reason"):
        return

    if common.background_pending(data.get("transcript_path") or task.get("transcript")):
        return

    if task.get("idle_blocks", 0) >= common.MAX_IDLE_BLOCKS:
        task["phase"] = "stalled"
        common.save(task, touch=False)
        desktop_notif(f"Tâche bloquée : {task['title'][:80]}")
        return

    task["idle_blocks"] = task.get("idle_blocks", 0) + 1
    common.save(task, touch=False)
    s = f"--session {session}"
    if task.get("level") == 3:
        step = ("termine la tâche en mode doubt-driven-dev, puis lance hostile-review en mode léger "
                "(~/.claude/skills/hostile-review/SKILL.md, section « Light mode ») et enregistre le verdict")
    elif task["phase"] == "building":
        step = ("continue le travail du brief en mode doubt-driven-dev, puis lance hostile-review "
                "(~/.claude/skills/hostile-review/SKILL.md) et enregistre le verdict")
    else:
        step = "termine hostile-review (corrections, re-revue), enregistre le verdict, puis finish"
    reason = (
        f"[autopilot] La tâche « {task['title']} » (phase {task['phase']}) n'est pas finie : "
        f"pas encore de verdict de revue hostile. Ne t'arrête pas : {step}. "
        f"Brief : {task.get('brief') or '?'}. État : {STATE} show {s}. "
        f"Si tout ce qui reste dépend d'une décision de Louis : {STATE} wait {s} --reason \"…\" "
        f"et envoie une notification push. Pour finir : {STATE} verdict {s} \"À LIVRER\" "
        f"--review <REVIEW.md> puis {STATE} finish {s}."
    )
    print(json.dumps({"decision": "block", "reason": reason}, ensure_ascii=False))


if __name__ == "__main__":
    main()
