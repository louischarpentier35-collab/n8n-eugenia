#!/bin/bash
# Installs Louis's Claude Code skills, agents and autopilot hooks from this repo.
# Idempotent: safe to run again after a git pull. Backs up settings.json before changing it.
# Usage: bash install.sh [--dashboard-url URL]
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
DASHBOARD_URL=""
[ "${1:-}" = "--dashboard-url" ] && DASHBOARD_URL="${2:-}"

command -v python3 >/dev/null || { echo "python3 est requis (xcode-select --install)"; exit 1; }
mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/agents"

BACKUP="$CLAUDE_DIR/backups/install-$(date +%Y%m%d%H%M%S)"
link() { # source, target: replace an existing link; a real file/folder is moved to $BACKUP
  # (outside skills/ and agents/, where a copy would load as a duplicate skill or agent)
  if [ -L "$2" ]; then rm "$2"
  elif [ -e "$2" ]; then mkdir -p "$BACKUP"; mv "$2" "$BACKUP/"; echo "  sauvegardé : $2 → $BACKUP/"
  fi
  ln -s "$1" "$2"
}

echo "Skills :"
for d in "$REPO"/skills/*/; do
  name="$(basename "$d")"
  [ -f "$d/SKILL.md" ] || continue
  link "${d%/}" "$CLAUDE_DIR/skills/$name"; echo "  $name"
done

echo "Agents :"
for f in "$REPO"/agents/*.md; do
  link "$f" "$CLAUDE_DIR/agents/$(basename "$f")"; echo "  $(basename "$f" .md)"
done

echo "Hooks autopilot :"
python3 - "$CLAUDE_DIR/settings.json" <<'EOF'
import json, os, shutil, sys, time
path = sys.argv[1]
settings = {}
if os.path.exists(path):
    with open(path, encoding="utf-8") as f:
        settings = json.load(f)
    shutil.copy(path, f"{path}.bak-{time.strftime('%Y%m%d%H%M%S')}")
base = '"$HOME/.claude/skills/autopilot/scripts/'
if os.environ.get("CLAUDE_CONFIG_DIR"):
    base = '"' + os.environ["CLAUDE_CONFIG_DIR"] + '/skills/autopilot/scripts/'
wanted = {
    "UserPromptSubmit": (None, base + 'hook_prompt.py"'),
    "SessionStart": ("compact|resume", base + 'hook_prompt.py"'),
    "Stop": (None, base + 'hook_stop.py"'),
}
# Sonnet by default for the main conversation (Opus by hand for level-4 projects); keeps a model already chosen
if "model" not in settings:
    settings["model"] = "sonnet"
    print("  model = sonnet (par défaut)")
elif settings["model"] != "sonnet":
    print(f"  model = {settings['model']} (conservé ; Sonnet est conseillé par défaut)")
hooks = settings.setdefault("hooks", {})
for event, (matcher, script) in wanted.items():
    command = "python3 " + script
    groups = hooks.setdefault(event, [])
    # drop any previous autopilot entry, then add the current one
    for g in groups:
        g["hooks"] = [h for h in g.get("hooks", []) if "autopilot/scripts/" not in h.get("command", "")]
    groups[:] = [g for g in groups if g.get("hooks")]
    group = {"hooks": [{"type": "command", "command": command, "timeout": 10}]}
    if matcher:
        group["matcher"] = matcher
    groups.append(group)
    print(f"  {event}")
with open(path, "w", encoding="utf-8") as f:
    json.dump(settings, f, ensure_ascii=False, indent=2)
EOF

if [ -n "$DASHBOARD_URL" ]; then
  python3 "$REPO/skills/autopilot/scripts/state.py" config dashboard_url "$DASHBOARD_URL" >/dev/null
  echo "Tableau de bord : $DASHBOARD_URL"
fi
echo "OK. Les nouvelles sessions Claude Code utilisent maintenant l'autopilot."
