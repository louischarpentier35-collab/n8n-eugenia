#!/usr/bin/env python3
"""UserPromptSubmit + SessionStart hook: injects the autopilot routing rule, the session id,
and the state of the active task (if any). Short on purpose: it is added to every message."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402

ROUTING = (
    "[autopilot] session_id={sid}. Avant de répondre, classe le message de Louis : "
    "question ou conversation → réponds normalement ; tâche à réaliser (construire, corriger, "
    "rédiger, automatiser…) → charge d'abord le skill `autopilot`, qui choisit seul interview, "
    "doubt-driven-dev, /dev et hostile-review. Ne demande jamais à Louis quel skill utiliser."
)


def main():
    try:
        data = json.load(sys.stdin)
        sid = data["session_id"]
        event = data.get("hook_event_name", "UserPromptSubmit")
    except Exception:
        return
    ctx = ROUTING.format(sid=sid)
    task = common.load(sid)
    changed = False
    if task and data.get("transcript_path") and task.get("transcript") != data["transcript_path"]:
        task["transcript"] = data["transcript_path"]
        changed = True
    if task and event == "UserPromptSubmit" and task.get("phase") == "awaiting_go" and not task.get("go_seen"):
        # Louis wrote after the "Je lance ?": only now may the task move to building
        task["go_seen"] = True
        changed = True
    if changed:
        common.save(task, touch=False)
    if task and task.get("phase") not in ("done",):
        qs = common.pending(task)
        ctx += (
            f" TÂCHE AUTOPILOT ACTIVE : « {task['title']} », phase {task['phase']}"
            + (f", en attente : {task['waiting_reason']}" if task.get("waiting_reason") else "")
            + (". Questions en attente : " + " | ".join(f"{q['id']} {q['text'][:120]}" for q in qs[:3])
               if qs else "")
            + ". Applique le skill `autopilot` (reprise) : si ce message répond à une question ou "
              "dit stop/pause, mets l'état à jour d'abord."
        )
        mode = data.get("permission_mode", "")
        if task.get("phase") == "awaiting_go" and mode and mode not in ("auto", "bypassPermissions"):
            ctx += (f" Mode de permissions actuel : {mode}. Avant de lancer, rappelle à Louis "
                    "d'activer le mode auto (sinon la tâche attendra ses validations).")
    print(json.dumps({"hookSpecificOutput": {"hookEventName": event, "additionalContext": ctx}},
                     ensure_ascii=False))


if __name__ == "__main__":
    main()
