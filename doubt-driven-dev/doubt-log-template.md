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

### Briques (réutiliser / adopter / construire)
| # | Besoin | Cherché où | Candidats (2-3) | Décision | Pourquoi / manque qui justifie de construire |
|---|---|---|---|---|---|
| B1 | … | projet, nodes n8n, npm, web | lib-a ✅, lib-b ❌ (abandonnée) | adopter lib-a | … |

### Revue d'optimalité
- <composant> — plus simple possible ? oui/non — action : refait (checks PASS) / noté pour plus tard

### Hypothèses prises seul (réversibles, à relire)
- H1 — <choix> — pourquoi : …

### Bilan
- Prouvé : …
- Non prouvé : …
- Briques : réutilisé / adopté / construit
- Échecs / remises en cause : …
```
