#!/bin/bash
# End-to-end tests with real headless Claude sessions and the installed hooks (C1, C2).
# Costs model usage (several dollars for the chain). Isolated: temp project folders + temp AUTOPILOT_HOME.
# Usage: bash autopilot/tests/test_e2e.sh [routing|chain|all]   (default: all)
WHAT="${1:-all}"
STATE="$HOME/.claude/skills/autopilot/scripts/state.py"
export AUTOPILOT_HOME="$(mktemp -d)"
export AUTOPILOT_NO_DESKTOP_NOTIF=1
WORK="$(mktemp -d)"
PASS=0; FAIL=0
check() { if [ "$2" -eq 0 ]; then PASS=$((PASS+1)); echo "PASS  $1"; else FAIL=$((FAIL+1)); echo "FAIL  $1"; fi; }

run() { # name, prompt, [extra claude args...] -> session id; transcript appended to $WORK/<name>.jsonl
  local name="$1" prompt="$2"; shift 2
  mkdir -p "$WORK/$name"
  (cd "$WORK/$name" && claude -p --permission-mode auto --output-format stream-json --verbose "$@" "$prompt" >> "$WORK/$name.jsonl" 2>&1)
}
new_sid() { uuidgen | tr 'A-Z' 'a-z'; }
used_autopilot() { grep -q '"skill":"autopilot"' "$1"; }
field() { python3 "$STATE" show --session "$1" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('$2',''))" 2>/dev/null; }

LONG_SID=""
if [ "$WHAT" = routing ] || [ "$WHAT" = all ]; then
  SID=$(new_sid); run question "C'est quoi la différence entre une liste et un tuple en Python ? Réponds en deux phrases." --session-id "$SID" --max-budget-usd 1
  ! used_autopilot "$WORK/question.jsonl"; check "C1 question -> no autopilot" $?
  [ -z "$(field "$SID" phase)" ]; check "C1 question -> no task state" $?

  SID=$(new_sid); run vague "Il me faudrait un outil pour mieux gérer mes factures." --session-id "$SID" --max-budget-usd 3
  used_autopilot "$WORK/vague.jsonl"; check "C1 vague task -> autopilot chosen without naming it" $?
  P=$(field "$SID" phase); [ "$P" = "interview" ]; check "C1 vague task -> interview (got '$P')" $?
  [ -z "$(find "$WORK/vague" -name '*.py' -o -name '*.js' -o -name '*.html' | head -1)" ]; check "C1 vague task -> nothing built" $?

  LONG_SID=$(new_sid); run long "Dans ce dossier, construis un outil Python en ligne de commande de suivi de dépenses personnelles : import d'un relevé bancaire CSV (date, libellé, montant), catégorisation automatique par règles de mots-clés modifiables dans un fichier YAML, ajout manuel de dépenses, rapport mensuel par catégorie exporté en CSV et en graphique PNG, et détection des abonnements récurrents. Données stockées en SQLite. Tests pytest pour chaque fonction. C'est fini quand pytest passe et qu'un rapport est généré à partir d'un relevé d'exemple fourni dans le dossier." --session-id "$LONG_SID" --max-budget-usd 4
  used_autopilot "$WORK/long.jsonl"; check "C1 clear long task -> autopilot chosen" $?
  P=$(field "$LONG_SID" phase); [ "$P" = "awaiting_go" ]; check "C1 clear long task -> waiting for go (got '$P')" $?
  [ -z "$(find "$WORK/long" -name '*.py' -not -path '*/.venv/*' | head -1)" ]; check "C1 clear long task -> no code before the go" $?

  SID=$(new_sid); run short "Ajoute dans ce dossier un script Python slug.py avec une fonction slugify(texte) (minuscules, sans accents, espaces remplacés par des tirets) et ses tests pytest." --session-id "$SID" --max-budget-usd 4
  used_autopilot "$WORK/short.jsonl"; check "C1 short task -> autopilot chosen" $?
  [ "$(field "$SID" mode)" = "short" ]; check "C1 short task -> tracked as short (no go asked)" $?
  P=$(field "$SID" phase); V=$(field "$SID" verdict); [ "$P" = "done" ] && [ -n "$V" ]; check "short task -> ends with a hostile-review verdict (phase '$P', verdict '$V')" $?
  R=$(field "$SID" review); [ -f "$R" ]; check "short task -> REVIEW file exists" $?
fi

if [ "$WHAT" = chain ] || [ "$WHAT" = all ]; then
  if [ -z "$LONG_SID" ]; then echo "chain needs the routing stage in the same run"; exit 1; fi
  run long "go" --resume "$LONG_SID" --max-budget-usd 25
  P=$(field "$LONG_SID" phase); V=$(field "$LONG_SID" verdict); W=$(field "$LONG_SID" waiting_reason)
  { [ "$P" = "done" ] && [ -n "$V" ]; } || [ -n "$W" ]; check "C2 after go -> verdict reached without help, or waiting on a real decision (phase '$P', verdict '$V', waiting '$W')" $?
  R=$(field "$LONG_SID" review); [ -f "$R" ]; check "C2 REVIEW file exists" $?
  (cd "$WORK/long" && { [ -x .venv/bin/python ] && .venv/bin/python -m pytest -q >/dev/null 2>&1 || python3 -m pytest -q >/dev/null 2>&1; }); check "C2 pytest passes in the built project" $?
  grep -c '"name":"Agent"' "$WORK/long.jsonl" | { read n; [ "$n" -ge 2 ]; }; check "C2 hostile review used fresh subagents" $?
fi

echo "Transcripts: $WORK"
echo "---"; echo "$PASS passed, $FAIL failed"; [ $FAIL -eq 0 ]
