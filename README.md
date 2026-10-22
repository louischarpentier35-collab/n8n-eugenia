# claude-skills

Skills, agents et hooks Claude Code de Louis. Chaque dossier qui contient un `SKILL.md` est un skill, relié à `~/.claude/skills/` par un lien symbolique : on modifie ici, c'est actif partout.

**Louis ne choisit jamais de skill.** Un hook rappelle à chaque message la règle de tri, et le skill `autopilot` enchaîne tout seul :

```
message de Louis
  ├─ question / discussion ............ réponse normale
  ├─ tâche courte (< ~30 min) ......... doubt-driven-dev → hostile-review (mode léger) → verdict
  └─ longue tâche ..................... interview si flou (sinon miroir) → brief → « go » de Louis
                                         → doubt-driven-dev (ou /dev si projet de code à plusieurs composants)
                                         → hostile-review → verdict → notification
```

| Dossier | Rôle |
|---|---|
| [autopilot](autopilot/SKILL.md) | Point d'entrée de toute tâche : tri, enchaînement, état par session, hooks, tableau de bord |
| [interview](interview/SKILL.md) | Interview jusqu'à zéro doute, puis brief et validation |
| [doubt-driven-dev](doubt-driven-dev/SKILL.md) | Construire en doutant : vérifications PASS/FAIL écrites avant d'agir, recherche de briques existantes, revue d'optimalité |
| [hostile-review](hostile-review/SKILL.md) | Revue stricte du travail fini : 4 relecteurs neufs (ou 1 en mode léger), chaque point vérifié, erreurs corrigées, verdict + REVIEW.md |
| [dev](dev/SKILL.md) + [agents](agents/) | Équipe d'agents de développement (explorateur, product, architecte, builders, relecteur, debuggeur, déployeur) |

## Garanties (hooks dans `~/.claude/settings.json`)

- **UserPromptSubmit** : injecte la règle de tri, l'identifiant de session et l'état de la tâche en cours.
- **SessionStart** (après compaction ou reprise) : réinjecte l'état de la tâche.
- **Stop** : une tâche lancée (phase construction ou revue) ne peut pas se terminer sans verdict de revue hostile, sauf si elle attend une décision de Louis. Anti-boucle : après 5 blocages sans progrès, la tâche passe « bloquée » et une notification part.

État : un fichier JSON par session dans `~/.claude/autopilot/tasks/`, géré par `autopilot/scripts/state.py`. Tableau de bord : URL dans `~/.claude/autopilot/config.json`.

## Installer (nouvelle machine, ou après un `git pull`)

```bash
git clone https://github.com/louischarpentier35-collab/claude-skills.git ~/Documents/IA\ work/claude-skills
bash ~/Documents/IA\ work/claude-skills/install.sh --dashboard-url https://claude.ai/artifact/MhkCT9iqJLiqKegTrxBprJ
```

Le script est relançable sans risque : il remplace les liens, déplace tout fichier réel qu'il remplacerait dans `~/.claude/backups/`, sauvegarde `settings.json` et n'ajoute qu'un seul hook autopilot par événement, en gardant les autres réglages. Prérequis : `python3`.

Pour les longues tâches, mets la session en **mode auto** (réglage de permissions de l'app) : sans lui, la tâche attend tes validations de commandes.

## Tests

```bash
bash autopilot/tests/test_scripts.sh
```

```bash
bash autopilot/tests/test_install.sh
```

```bash
bash autopilot/tests/test_e2e.sh routing
```

Les deux premiers sont gratuits. Le troisième lance de vraies sessions Claude (quelques dollars) ; `all` ajoute la chaîne complète après « go » (plus long et plus cher).

## Organisation du repo

- `skills/` : les skills Claude (autopilot, dev, doubt-driven-dev, hostile-review, interview). `install.sh` crée leurs liens dans `~/.claude/skills`.
- `agents/` : les sous-agents de /dev.
- `workflows/` : le workflow n8n rendu pour le cours « Veille carrousels TikTok Shop » (export `.workflow.ts`, à importer avec n8n-cli).
