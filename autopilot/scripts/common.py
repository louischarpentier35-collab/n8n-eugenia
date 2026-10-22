"""Shared helpers for the autopilot state files (one JSON file per Claude Code session)."""
import json
import os
import tempfile
import time

HOME = os.environ.get("AUTOPILOT_HOME") or os.path.expanduser("~/.claude/autopilot")
TASKS = os.path.join(HOME, "tasks")

# Phases where the Stop hook lets Claude end its turn.
STOP_ALLOWED = {"interview", "awaiting_go", "done", "paused", "stalled"}
# Phases of autonomous work: stopping is blocked until a hostile-review verdict exists.
WORKING = {"building", "reviewing"}
PHASES = STOP_ALLOWED | WORKING
VERDICTS = {"À LIVRER", "À CORRIGER", "À REVOIR"}
MAX_IDLE_BLOCKS = 5


def now():
    return time.strftime("%Y-%m-%dT%H:%M:%S")


def path(session):
    safe = "".join(c for c in session if c.isalnum() or c in "-_")
    return os.path.join(TASKS, f"{safe}.json")


def load(session):
    try:
        with open(path(session), encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def save(task, touch=True):
    """Atomic write. touch=True means real progress: resets the anti-loop counter."""
    os.makedirs(TASKS, exist_ok=True)
    if touch:
        task["updated_at"] = now()
        task["idle_blocks"] = 0
    _write_json(path(task["session_id"]), task)
    export_dashboard()


def _write_json(target, obj):
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(target), suffix=".tmp")
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)
    os.replace(tmp, target)


PHASE_LABELS = {
    "interview": "Interview", "awaiting_go": "Attend ton go", "building": "En construction",
    "reviewing": "Revue hostile", "done": "Terminée", "paused": "En pause", "stalled": "Bloquée",
}
DASHBOARD = os.path.join(HOME, "dashboard.json")
DONE_KEEP_DAYS = 14


MONTHS = ["janv.", "févr.", "mars", "avr.", "mai", "juin", "juil.", "août", "sept.", "oct.", "nov.", "déc."]


def _label(stamp):
    try:
        t = time.strptime(stamp, "%Y-%m-%dT%H:%M:%S")
        return f"{t.tm_mday} {MONTHS[t.tm_mon - 1]} {t.tm_hour:02d}:{t.tm_min:02d}"
    except ValueError:
        return stamp


def export_dashboard():
    """Rows for the Autopilot dashboard (uploaded by Claude after each phase change)."""
    rows = []
    cutoff = time.strftime("%Y-%m-%dT%H:%M:%S", time.localtime(time.time() - DONE_KEEP_DAYS * 86400))
    for t in all_tasks():
        if t.get("mode") == "short":
            continue
        if t.get("phase") == "done" and t.get("updated_at", "") < cutoff:
            continue
        qs = pending(t)
        rows.append({
            "session": t["session_id"][:8],
            "title": t.get("title", ""),
            "project": os.path.basename(t.get("project", "").rstrip("/")),
            "phase": PHASE_LABELS.get(t.get("phase"), t.get("phase", "")),
            "waiting": t.get("waiting_reason", ""),
            "pending_count": len(qs),
            "pending_text": " | ".join(f"{q['id']} {q['text']}" for q in qs),
            "for_you": " | ".join(f"{q['id']} {q['text']}" for q in qs) or t.get("waiting_reason", ""),
            "verdict": t.get("verdict", ""),
            "updated": t.get("updated_at", ""),
            "updated_label": _label(t.get("updated_at", "")),
        })
    rows.sort(key=lambda r: r["updated"], reverse=True)
    for r in rows:
        r["placeholder"] = False
    if not rows:
        # the Dashboard type refuses a file with no rows: one marker row, hidden by the page
        rows = [{"session": "-", "title": "", "project": "", "phase": "", "waiting": "",
                 "pending_count": 0, "pending_text": "", "for_you": "", "verdict": "",
                 "updated": "", "updated_label": "", "placeholder": True}]
    _write_json(DASHBOARD, {"rows": rows})


CONFIG = os.path.join(HOME, "config.json")


def load_config():
    try:
        with open(CONFIG, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def save_config(cfg):
    os.makedirs(HOME, exist_ok=True)
    _write_json(CONFIG, cfg)


def reviewer_agents(transcript_path):
    """Number of subagents launched for a review in the session transcript (None if unreadable).
    A hostile-review verdict needs at least one: reviewing your own work is not a hostile review."""
    try:
        f = open(transcript_path, encoding="utf-8")
    except (OSError, TypeError):
        return None
    n = 0
    with f:
        for line in f:
            if '"tool_use"' not in line:
                continue
            try:
                content = json.loads(line).get("message", {}).get("content", [])
            except ValueError:
                continue
            for c in content if isinstance(content, list) else []:
                if c.get("type") == "tool_use" and c.get("name") in ("Agent", "Task"):
                    text = json.dumps(c.get("input", {}), ensure_ascii=False).lower()
                    if any(k in text for k in ("hostile", "relecteur", "revue", "review")):
                        n += 1
    return n


def pending(task):
    return [q for q in task.get("questions", []) if not q.get("answer")]


def all_tasks():
    out = []
    if os.path.isdir(TASKS):
        for name in sorted(os.listdir(TASKS)):
            if name.endswith(".json"):
                t = load(name[:-5])
                if t:
                    out.append(t)
    return out
