# REVIEW.md template

Write it in French. Newest review on top. Short lines: Louis must get the verdict in 10 seconds and the details in 2 minutes.

```markdown
## Revue hostile — <sujet> — AAAA-MM-JJ

**Verdict : À LIVRER | À CORRIGER → corrigé | À REVOIR** — <une phrase pourquoi>

- **Contrat utilisé :** <chemin du brief / spec / demande>
- **Périmètre relu :** <diff, fichiers, workflow, document>
- **Angles :** Conformité · Bugs et cas limites · Sécurité et coûts · Simplicité et maintenabilité
- **Tours :** <1 ou 2> · **Points remontés :** <n> · **Confirmés :** <n> · **Réfutés :** <n>

### Corrigé (BLOQUANT / MAJEUR confirmés)
| # | Gravité | Angle | Emplacement | Problème (scénario d'échec) | Correctif | Vérif après |
|---|---|---|---|---|---|---|
| R1 | BLOQUANT | Conformité | src/x.ts:42 | … | … | `npm test` PASS |

### À choisir par Louis
| # | Type | Emplacement | Proposition | Gain | Coût | Choix |
|---|---|---|---|---|---|---|
| A1 | AMÉLIORATION | … | … | … | … | à faire / non / plus tard |
| S1 | SUGGESTION | … | … | … | … | … |

### Encore ouvert / invérifiable
- …

### Réfuté (pour mémoire)
- <point> — réfuté parce que …

### Ce qui a été vérifié sans problème
- <par angle, une ligne : ce qui a été testé et tient>
```
