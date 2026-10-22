# claude-skills

Skills Claude Code de Louis. Chaque dossier est un skill (`SKILL.md` + fichiers de référence), relié à `~/.claude/skills/` par un lien symbolique : on modifie ici, c'est actif partout.

| Skill | Rôle | Statut |
|---|---|---|
| [interview](interview/SKILL.md) | Interview avant un projet ou une tâche floue, jusqu'à zéro doute, puis brief, validation, lancement | v1 |
| [doubt-driven-dev](doubt-driven-dev/SKILL.md) | Construire en mode doute : « est-ce juste ? » (vérifications PASS/FAIL écrites avant d'agir) et « est-ce la meilleure façon ? » (recherche de briques existantes, revue d'optimalité), journal des doutes, puis passe la main à hostile-review | v2 |
| [hostile-review](hostile-review/SKILL.md) | Revue stricte du travail fini : 4 relecteurs neufs en parallèle, chaque point vérifié, erreurs corrigées d'office, améliorations soumises à Louis, verdict + REVIEW.md | v1 |

Enchaînement : `interview` → travail en mode `doubt-driven-dev` → `hostile-review` → livraison.

## Installer sur une nouvelle machine

```bash
git clone <url-du-depot> ~/Documents/IA\ work/claude-skills
for d in ~/Documents/IA\ work/claude-skills/*/; do ln -s "$d" ~/.claude/skills/"$(basename "$d")"; done
```
