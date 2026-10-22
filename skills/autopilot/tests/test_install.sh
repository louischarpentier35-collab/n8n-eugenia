#!/bin/bash
# C5: install.sh on a blank (simulated) Claude config, then a second run (idempotence).
REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
export CLAUDE_CONFIG_DIR="$(mktemp -d)"
export AUTOPILOT_HOME="$CLAUDE_CONFIG_DIR/autopilot"
PASS=0; FAIL=0
check() { if [ "$2" -eq 0 ]; then PASS=$((PASS+1)); echo "PASS  $1"; else FAIL=$((FAIL+1)); echo "FAIL  $1"; fi; }

echo '{"enableWorkflows": true, "hooks": {"Stop": [{"hooks": [{"type": "command", "command": "echo mine"}]}]}}' > "$CLAUDE_CONFIG_DIR/settings.json"
bash "$REPO/install.sh" --dashboard-url https://example.test/dash >/dev/null; check "install runs on a blank config" $?
for s in interview doubt-driven-dev hostile-review autopilot dev; do
  [ -L "$CLAUDE_CONFIG_DIR/skills/$s" ] && [ -f "$CLAUDE_CONFIG_DIR/skills/$s/SKILL.md" ]; check "skill $s linked" $?
done
N=$(ls "$CLAUDE_CONFIG_DIR/agents/" | wc -l | tr -d ' '); [ "$N" = "7" ]; check "7 agents linked (got $N)" $?
bash "$REPO/install.sh" >/dev/null; check "second run succeeds" $?
python3 - "$CLAUDE_CONFIG_DIR/settings.json" <<'EOF'
import json, sys
s = json.load(open(sys.argv[1]))
assert s["enableWorkflows"] is True, "other settings kept"
cmds = {e: [h["command"] for g in s["hooks"][e] for h in g["hooks"]] for e in s["hooks"]}
assert "echo mine" in cmds["Stop"], "user's own Stop hook kept"
for e in ("UserPromptSubmit", "SessionStart", "Stop"):
    assert sum("autopilot/scripts/" in c for c in cmds[e]) == 1, f"exactly one autopilot hook on {e}"
EOF
check "settings merged: own settings and hooks kept, one autopilot hook per event" $?
ls "$CLAUDE_CONFIG_DIR"/settings.json.bak-* >/dev/null 2>&1; check "settings backed up" $?
grep -q "example.test" "$AUTOPILOT_HOME/config.json"; check "dashboard url stored" $?
# the installed hook command really runs (paths resolved by the shell, as Claude Code does)
CMD=$(python3 -c 'import json,sys; s=json.load(open(sys.argv[1])); print([h["command"] for g in s["hooks"]["UserPromptSubmit"] for h in g["hooks"]][0])' "$CLAUDE_CONFIG_DIR/settings.json")
OUT=$(echo '{"session_id":"T","hook_event_name":"UserPromptSubmit","prompt":"x"}' | bash -c "$CMD")
echo "$OUT" | grep -q "session_id=T"; check "installed hook command runs" $?

rm -rf "$CLAUDE_CONFIG_DIR"
echo "---"; echo "$PASS passed, $FAIL failed"; [ $FAIL -eq 0 ]
