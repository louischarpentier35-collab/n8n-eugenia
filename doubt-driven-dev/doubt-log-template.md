# Doubt log template

Write the log in French. One section per task. Short lines, no prose: Louis must be able to scan it in 30 seconds.

```markdown
## <Tâche> — AAAA-MM-JJ

### Suppositions lourdes (au départ)
| # | Je suppose que… | Si c'est faux… | Statut |
|---|---|---|---|
| S1 | … | … | VÉRIFIÉ (preuve) / À VÉRIFIER / HYPOTHÈSE / NON VÉRIFIÉ (raison) |

### Critères de fini (binaires)
- [ ] C1 — <critère> — vérifié par : <commande / test / ligne de checklist>
- [ ] …

### Doutes
| # | Doute | Vérification (écrite avant d'agir) | Prédiction | Avant | Après | Décision |
|---|---|---|---|---|---|---|
| D1 | … | `commande` / critère | FAIL puis PASS | FAIL | PASS | continue |
| D2 | … | … | … | … | FAIL ×3 | remise en cause : … |

### Hypothèses prises seul (réversibles, à relire)
- H1 — <choix> — pourquoi : …

### Sceptique (si gros chantier)
- Remarque → classée valide / mauvaise lecture / compromis / bruit → action

### Bilan
- Prouvé : …
- Non prouvé : …
- Échecs / remises en cause : …
```
