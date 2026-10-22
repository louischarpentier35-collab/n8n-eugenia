#!/bin/bash
# Tests of the autopilot scripts with simulated hook input. Usage: bash autopilot/tests/test_scripts.sh
# Uses a temporary AUTOPILOT_HOME, never the real ~/.claude/autopilot.

DIR="$(cd "$(dirname "$0")/.." && pwd)"
STATE() { python3 "$DIR/scripts/state.py" "$@"; }
STOP() { python3 "$DIR/scripts/hook_stop.py"; }
PROMPT() { python3 "$DIR/scripts/hook_prompt.py"; }
export AUTOPILOT_HOME="$(mktemp -d)"
export AUTOPILOT_NO_DESKTOP_NOTIF=1
PASS=0; FAIL=0

check() { # name, condition result (0 = pass)
  if [ "$2" -eq 0 ]; then PASS=$((PASS+1)); echo "PASS  $1"; else FAIL=$((FAIL+1)); echo "FAIL  $1"; fi
}
stop_in() { printf '{"session_id":"%s","hook_event_name":"Stop","stop_hook_active":%s,"cwd":"/tmp"}' "$1" "${2:-false}"; }
prompt_in() { printf '{"session_id":"%s","hook_event_name":"UserPromptSubmit","prompt":"%s","cwd":"/tmp"}' "$1" "$2"; }
golive() { STATE phase --session "$1" awaiting_go >/dev/null; prompt_in "$1" go | PROMPT >/dev/null; STATE phase --session "$1" building >/dev/null; }
blocks() { echo "$1" | grep -q '"decision": *"block"'; }

# --- Stop hook
OUT=$(stop_in A | STOP); [ -z "$OUT" ]; check "C3 no task -> stop allowed (normal conversation)" $?

STATE init --session A --title "Tache A" --project /tmp/projA >/dev/null
OUT=$(stop_in A | STOP); [ -z "$OUT" ]; check "phase interview -> allowed" $?

STATE phase --session A building >/dev/null 2>&1; [ $? -ne 0 ]; check "go gate: interview -> building refused" $?
STATE phase --session A awaiting_go >/dev/null
OUT=$(stop_in A | STOP); [ -z "$OUT" ]; check "phase awaiting_go -> allowed" $?
STATE phase --session A building >/dev/null 2>&1; [ $? -ne 0 ]; check "go gate: building refused before Louis writes again" $?
prompt_in A "go" | PROMPT >/dev/null
STATE phase --session A building >/dev/null; check "go gate: building accepted after a new message from Louis" $?
OUT=$(stop_in A | STOP); blocks "$OUT"; check "C3 building without verdict -> blocked" $?
echo "$OUT" | python3 -c 'import sys,json; d=json.load(sys.stdin); assert d["reason"]' 2>/dev/null; check "block output is valid JSON with a reason" $?

OUT=$(stop_in B | STOP); [ -z "$OUT" ]; check "C7 other session B not blocked by A" $?
STATE init --session B --title "Tache B" --project /tmp/projB >/dev/null
golive B
STATE wait --session A --reason "attend Louis" >/dev/null
OUT=$(stop_in A | STOP); [ -z "$OUT" ]; check "C4 waiting on Louis -> allowed" $?
OUT=$(stop_in B | STOP); blocks "$OUT"; check "C7 B still blocked while A waits" $?
STATE resume --session A >/dev/null
OUT=$(stop_in A | STOP); blocks "$OUT"; check "resume -> blocked again" $?

STATE ask --session A "Quel compte utiliser ?" >/dev/null
N=$(STATE show --session A | python3 -c 'import sys,json; print(len([q for q in json.load(sys.stdin)["questions"] if not q.get("answer")]))')
[ "$N" = "1" ]; check "C4 question queued" $?
OUT=$(stop_in A | STOP); blocks "$OUT"; check "C4 a queued question alone does not stop the work" $?
STATE answer --session A Q1 "le compte perso" >/dev/null
N=$(STATE show --session A | python3 -c 'import sys,json; print(len([q for q in json.load(sys.stdin)["questions"] if not q.get("answer")]))')
[ "$N" = "0" ]; check "answer recorded" $?

STATE finish --session A >/dev/null 2>&1; [ $? -ne 0 ]; check "finish refused without verdict" $?
STATE verdict --session A "À LIVRER" --review /nonexistent/REVIEW.md >/dev/null 2>&1; [ $? -ne 0 ]; check "verdict refused if REVIEW file missing" $?
STATE verdict --session A "PEUT-ETRE" --review /etc/hosts >/dev/null 2>&1; [ $? -ne 0 ]; check "unknown verdict refused" $?
REV="$AUTOPILOT_HOME/REVIEW.md"; echo "review" > "$REV"
STATE verdict --session A "À LIVRER" --review "$REV" >/dev/null; check "verdict accepted with REVIEW file" $?
STATE finish --session A >/dev/null; check "finish accepted after verdict" $?
OUT=$(stop_in A | STOP); [ -z "$OUT" ]; check "C3 done -> stop allowed" $?

# Anti-loop: repeated blocks without any state update end in 'stalled'
for i in 1 2 3 4 5; do stop_in B true | STOP >/dev/null; done
OUT=$(stop_in B true | STOP); [ -z "$OUT" ]; check "anti-loop: 6th consecutive block without progress -> allowed" $?
P=$(STATE show --session B | python3 -c 'import sys,json; print(json.load(sys.stdin)["phase"])')
[ "$P" = "stalled" ]; check "anti-loop: phase set to stalled" $?

# --- Prompt hook
OUT=$(prompt_in Z "bonjour" | PROMPT)
echo "$OUT" | python3 -c 'import sys,json; c=json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"]; assert "session_id=Z" in c and "autopilot" in c' 2>/dev/null
check "C1 prompt hook injects routing rule + session id (no task)" $?
STATE init --session C --title "Tache C" --project /tmp/projC >/dev/null
golive C
STATE ask --session C "Budget ?" >/dev/null
OUT=$(prompt_in C "oui 20 euros" | PROMPT)
echo "$OUT" | python3 -c 'import sys,json; c=json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"]; assert "Tache C" in c and "building" in c and "Budget ?" in c' 2>/dev/null
check "prompt hook shows active task, phase and pending question" $?
LEN=$(prompt_in Z "x" | PROMPT | python3 -c 'import sys,json; print(len(json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"]))')
[ "$LEN" -lt 900 ]; check "routing context stays short (<900 chars, got $LEN)" $?
OUT=$(printf '{"session_id":"C","hook_event_name":"SessionStart","source":"compact"}' | PROMPT)
echo "$OUT" | python3 -c 'import sys,json; d=json.load(sys.stdin)["hookSpecificOutput"]; assert d["hookEventName"]=="SessionStart" and "Tache C" in d["additionalContext"]' 2>/dev/null
check "after compaction, SessionStart re-injects the active task" $?

STATE phase --session C awaiting_go >/dev/null
OUT=$(printf '{"session_id":"C","hook_event_name":"UserPromptSubmit","prompt":"x","permission_mode":"default"}' | PROMPT)
echo "$OUT" | grep -q "mode auto"; check "awaiting_go + default permissions -> reminder to enable auto mode" $?
OUT=$(printf '{"session_id":"C","hook_event_name":"UserPromptSubmit","prompt":"x","permission_mode":"auto"}' | PROMPT)
echo "$OUT" | grep -q "mode auto"; [ $? -ne 0 ]; check "auto mode already on -> no reminder" $?
OUT=$(stop_in C | STOP); [ -z "$OUT" ]; check "awaiting_go -> stop allowed (waiting for go)" $?

# --- Verdict needs a fresh reviewer subagent in the transcript
TR="$AUTOPILOT_HOME/t.jsonl"
echo '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"pytest"}}]}}' > "$TR"
STATE init --session V --title "Tache V" --project /tmp/v --mode short >/dev/null
printf '{"session_id":"V","hook_event_name":"Stop","stop_hook_active":false,"transcript_path":"%s"}' "$TR" | STOP >/dev/null
STATE verdict --session V "À LIVRER" --review "$REV" >/dev/null 2>&1; [ $? -ne 0 ]; check "verdict refused when no reviewer subagent ran (self-review)" $?
echo '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Agent","input":{"description":"Revue hostile","prompt":"Tu es un relecteur hostile..."}}]}}' >> "$TR"
STATE verdict --session V "À LIVRER" --review "$REV" >/dev/null 2>&1; check "verdict accepted once a reviewer subagent ran" $?
OUT=$(printf '{"session_id":"V","hook_event_name":"UserPromptSubmit","prompt":"x","transcript_path":"/new/path.jsonl"}' | PROMPT)
[ "$(STATE show --session V | python3 -c 'import sys,json; print(json.load(sys.stdin)["transcript"])')" = "/new/path.jsonl" ]; check "prompt hook records the transcript path" $?

# --- Short tasks
STATE init --session S --title "Tache courte" --project /tmp/s --mode short >/dev/null
P=$(STATE show --session S | python3 -c 'import sys,json; print(json.load(sys.stdin)["phase"])')
[ "$P" = "building" ]; check "short task starts in building (no interview, no go)" $?
OUT=$(stop_in S | STOP); blocks "$OUT" && echo "$OUT" | grep -q "léger"; check "short task without verdict -> blocked, asks for light review" $?
STATE init --session X --title "Mauvais mode" --project /tmp/x --mode bidon >/dev/null 2>&1; [ $? -ne 0 ]; check "unknown mode refused" $?

# --- Dashboard export
python3 - "$AUTOPILOT_HOME/dashboard.json" <<'EOF'
import json, sys
rows = {r["title"]: r for r in json.load(open(sys.argv[1]))["rows"]}
assert rows["Tache A"]["phase"] == "Terminée" and rows["Tache A"]["verdict"] == "À LIVRER"
assert rows["Tache B"]["phase"] == "Bloquée"
assert rows["Tache C"]["phase"] == "Attend ton go" and rows["Tache C"]["pending_count"] == 1
assert "Budget ?" in rows["Tache C"]["pending_text"]
assert "Tache courte" not in rows, "short tasks stay off the dashboard"
EOF
check "C6 dashboard.json reflects phases, verdicts and pending questions" $?

OUT=$(STATE dashboard-asset aaa); echo "$OUT" | grep -q "Aucun"; check "first dashboard asset -> nothing to delete" $?
OUT=$(STATE dashboard-asset bbb); echo "$OUT" | grep -q "aaa"; check "next dashboard asset -> previous id to delete" $?
STATE config dashboard_url https://example.test/x >/dev/null; STATE config | grep -q "example.test"; check "config stores dashboard_url" $?
STATE | grep -q "state.py init"; check "no command -> usage" $?

# --- Robustness
OUT=$(echo "not json" | STOP); [ $? -eq 0 ] && [ -z "$OUT" ]; check "garbage input -> stop allowed, no crash" $?
OUT=$(echo "not json" | PROMPT); [ $? -eq 0 ]; check "garbage input -> prompt hook exits 0" $?
STATE list | python3 -c 'import sys,json; d=json.load(sys.stdin); assert len(d)==5' 2>/dev/null; check "list returns all tasks" $?

rm -rf "$AUTOPILOT_HOME"
echo "---"; echo "$PASS passed, $FAIL failed"; [ $FAIL -eq 0 ]
