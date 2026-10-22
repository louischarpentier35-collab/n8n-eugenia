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

# Anti-loop: B was blocked once (above) with no progress since -> next stop allowed, task stalled
OUT=$(stop_in B true | STOP); [ -z "$OUT" ]; check "anti-loop: 2nd stop without progress -> allowed" $?
P=$(STATE show --session B | python3 -c 'import sys,json; print(json.load(sys.stdin)["phase"])')
[ "$P" = "stalled" ]; check "anti-loop: phase set to stalled" $?

# Background jobs still running -> never block (their notification wakes Claude up)
STATE init --session G --title "Tache G" --project /tmp/projG >/dev/null; golive G
TG="$AUTOPILOT_HOME/g.jsonl"
cat > "$TG" <<'JSONL'
{"type":"assistant","message":{"content":[{"type":"tool_use","id":"tu1","name":"Agent","input":{"prompt":"revue"}}]}}
{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"tu1","content":"Async agent launched"}]},"toolUseResult":{"isAsync":true,"status":"async_launched"}}
{"type":"assistant","message":{"content":[{"type":"tool_use","id":"tu2","name":"Bash","input":{"command":"sleep 9","run_in_background":true}}]}}
JSONL
sg() { printf '{"session_id":"G","hook_event_name":"Stop","stop_hook_active":false,"transcript_path":"%s"}' "$TG" | STOP; }
OUT=$(sg); [ -z "$OUT" ]; check "background agent + command running -> stop allowed" $?
echo '{"type":"user","message":{"content":"<task-notification> <task-id>a1</task-id> <tool-use-id>tu1</tool-use-id> <status>completed</status>"}}' >> "$TG"
OUT=$(sg); [ -z "$OUT" ]; check "one job still running -> stop allowed" $?
echo '{"type":"user","message":{"content":"<task-notification> <task-id>b2</task-id> <tool-use-id>tu2</tool-use-id> <status>completed</status>"}}' >> "$TG"
OUT=$(sg); blocks "$OUT"; check "all jobs notified, no verdict -> blocked" $?

# A stopped job (TaskStop, no notification) no longer counts as running
TK="$AUTOPILOT_HOME/k.jsonl"
cat > "$TK" <<'JSONL'
{"type":"assistant","message":{"content":[{"type":"tool_use","id":"tu9","name":"Agent","input":{"prompt":"x"}}]}}
{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"tu9","content":"agentId: wc7abc"}]},"toolUseResult":{"isAsync":true,"status":"async_launched","agentId":"wc7abc"}}
{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"tu10","content":"Successfully stopped task: wc7abc"}]}}
JSONL
python3 -c "import sys; sys.path.insert(0,'$DIR/scripts'); import common; assert common.background_pending('$TK')==0"; check "stopped job -> not running anymore" $?

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
STATE init --session V --title "Tache V" --project /tmp/v --level 3 >/dev/null
printf '{"session_id":"V","hook_event_name":"Stop","stop_hook_active":false,"transcript_path":"%s"}' "$TR" | STOP >/dev/null
STATE verdict --session V "À LIVRER" --review "$REV" >/dev/null 2>&1; [ $? -ne 0 ]; check "verdict refused when no reviewer subagent ran (self-review)" $?
echo '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Agent","input":{"description":"Revue hostile","prompt":"Tu es un relecteur hostile..."}}]}}' >> "$TR"
STATE verdict --session V "À LIVRER" --review "$REV" >/dev/null 2>&1; check "verdict accepted once a reviewer subagent ran" $?
OUT=$(printf '{"session_id":"V","hook_event_name":"UserPromptSubmit","prompt":"x","transcript_path":"/new/path.jsonl"}' | PROMPT)
[ "$(STATE show --session V | python3 -c 'import sys,json; print(json.load(sys.stdin)["transcript"])')" = "/new/path.jsonl" ]; check "prompt hook records the transcript path" $?

# --- Level 3 tasks
STATE init --session S --title "Tache moyenne" --project /tmp/s --level 3 >/dev/null
P=$(STATE show --session S | python3 -c 'import sys,json; print(json.load(sys.stdin)["phase"])')
[ "$P" = "interview" ]; check "level 3 task starts in interview (mirror + go)" $?
golive S
OUT=$(stop_in S | STOP); blocks "$OUT" && echo "$OUT" | grep -q "léger"; check "level 3 without verdict -> blocked, asks for light review" $?
STATE init --session X --title "Ancien mode" --project /tmp/x --mode short >/dev/null 2>&1; [ $? -ne 0 ]; check "old short mode refused" $?
STATE init --session X --title "Mauvais mode" --project /tmp/x --mode bidon >/dev/null 2>&1; [ $? -ne 0 ]; check "unknown mode refused" $?

# --- Dashboard export
python3 - "$AUTOPILOT_HOME/dashboard.json" <<'EOF'
import json, sys
rows = {r["title"]: r for r in json.load(open(sys.argv[1]))["rows"]}
assert rows["Tache A"]["phase"] == "Terminée" and rows["Tache A"]["verdict"] == "À LIVRER"
assert rows["Tache B"]["phase"] == "Bloquée"
assert rows["Tache C"]["phase"] == "Attend ton go" and rows["Tache C"]["pending_count"] == 1
assert "Budget ?" in rows["Tache C"]["pending_text"]
assert "Tache moyenne" in rows, "level 3 tasks are on the dashboard"
EOF
check "C6 dashboard.json reflects phases, verdicts and pending questions" $?

OUT=$(STATE dashboard-asset aaa); echo "$OUT" | grep -q "Aucun"; check "first dashboard asset -> nothing to delete" $?
OUT=$(STATE dashboard-asset bbb); echo "$OUT" | grep -q "aaa"; check "next dashboard asset -> previous id to delete" $?
STATE config dashboard_url https://example.test/x >/dev/null; STATE config | grep -q "example.test"; check "config stores dashboard_url" $?
STATE | grep -q "state.py init"; check "no command -> usage" $?

# Router text + context alert
prompt_in Z "bonjour" | PROMPT | grep -q "Niveau N"; check "routing rule asks to announce the level" $?
TC="$AUTOPILOT_HOME/ctx.jsonl"
echo '{"type":"assistant","message":{"usage":{"input_tokens":10,"cache_read_input_tokens":200000,"cache_creation_input_tokens":5000}}}' > "$TC"
OUT=$(printf '{"session_id":"Z","hook_event_name":"UserPromptSubmit","prompt":"x","transcript_path":"%s"}' "$TC" | PROMPT)
echo "$OUT" | grep -q "handoff"; check "context > 150k -> handoff alert" $?
echo '{"type":"assistant","message":{"usage":{"input_tokens":10,"cache_read_input_tokens":20000}}}' > "$TC"
OUT=$(printf '{"session_id":"Z","hook_event_name":"UserPromptSubmit","prompt":"x","transcript_path":"%s"}' "$TC" | PROMPT)
echo "$OUT" | grep -q "handoff"; [ $? -ne 0 ]; check "small context -> no alert" $?
echo '{"type":"assistant","message":{"model":"<synthetic>","usage":{"input_tokens":0}}}' >> "$TC"
python3 -c "import sys; sys.path.insert(0,'$DIR/scripts'); import common; assert common.context_tokens('$TC')==20010"; check "synthetic zero-usage message ignored" $?
STATE init --session L --title "Tache L" --project /tmp/l --level 2 >/dev/null 2>&1; [ $? -ne 0 ]; check "level 2 is never tracked" $?

# --- Robustness
OUT=$(echo "not json" | STOP); [ $? -eq 0 ] && [ -z "$OUT" ]; check "garbage input -> stop allowed, no crash" $?
OUT=$(echo "not json" | PROMPT); [ $? -eq 0 ]; check "garbage input -> prompt hook exits 0" $?
STATE list | python3 -c 'import sys,json; d=json.load(sys.stdin); assert len(d)==6' 2>/dev/null; check "list returns all tasks" $?

rm -rf "$AUTOPILOT_HOME"
echo "---"; echo "$PASS passed, $FAIL failed"; [ $FAIL -eq 0 ]
