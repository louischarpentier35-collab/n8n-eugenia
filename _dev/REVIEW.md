# Revue hostile — Lot 1 (système économe en tokens)

- **Date :** 2026-10-22 · **Contrat :** `_dev/BRIEF.md`, lot 1 · **Mode :** léger (1 relecteur Sonnet, 4 angles)
- **Verdict :** À LIVRER (après corrections)

## Constats et suite donnée
| # | Gravité | Constat | Suite |
|---|---|---|---|
| 1 | MAJEUR | `background_pending` : un travail arrêté (TaskStop) sans notification restait « en cours » → le hook Stop ne bloquait plus jamais | Corrigé : un arrêt (« stopped task: <id> ») compte comme fin, et tout travail silencieux depuis plus de 2 h est ignoré. Vérifié sur la session réelle `7bb67597` (0) + test. |
| 2 | MINEUR | `context_tokens` : un message synthétique à usage nul masquait la taille du contexte | Corrigé (on remonte jusqu'à un usage non nul) + test |
| 3 | MINEUR | Fenêtre de 400 Ko : un énorme résultat d'outil cachait le dernier relevé | Corrigé (fenêtre élargie ×4 jusqu'à trouver) |
| 4 | MINEUR | Ancien mode `short` encore accepté, contradictoire avec les niveaux | Corrigé : supprimé, remplacé par `--level 3` (miroir + go, revue légère, visible au tableau de bord) ; tests adaptés |
| 5 | SUGGESTION | hostile-review décrivait le mode léger pour les « petites tâches » (niveau 2) | Corrigé : mode léger = niveau 3 ; niveaux 1-2 n'ont pas de relecteur |
| 6 | SUGGESTION | `install.sh` ne signalait pas un modèle autre que Sonnet conservé | Corrigé : une ligne l'affiche |

## Preuves
- `bash skills/autopilot/tests/test_scripts.sh` → 54/54 ; `test_install.sh` → 12/12.
- Rejeu de la session `6f5b2372` : aux ~15 blocages d'origine, le nouveau hook aurait laissé s'arrêter (2 à 5 travaux en cours à chaque fois).
- Session neuve en ligne de commande → `claude-sonnet-5-5`. « c'est quoi un webhook » → « Niveau 1 », 1 tour. « niveau 3 : … » → « Niveau 3 », skill autopilot chargé.

## Non prouvé
- Que l'app desktop respecte `model` de `settings.json` (le sélecteur de modèle de l'app peut primer).
- Le gain réel en % de limite : c'est la preuve du lot 2.
