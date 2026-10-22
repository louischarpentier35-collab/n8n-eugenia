# Brief template

Fill in every section, in French (the brief is read and validated by Louis). An empty section is not acceptable: write "Aucun" or "Sans objet" when relevant. In "Décisions", each line says who decided.

```markdown
# Brief — <sujet>

- **Projet :** <projet> · **Type :** <app / n8n / livrable / scolaire / mixte>
- **Date :** AAAA-MM-JJ · **Statut :** brouillon | validé par Louis le AAAA-MM-JJ

## Objectif
<Une ou deux phrases : ce qu'on fait et pourquoi.>

## Pour qui
<Utilisateur / lecteur / destinataire, et ce qu'il doit pouvoir faire ou comprendre.>

## Périmètre
**Dedans :**
- …

**Dehors (pas cette fois) :**
- …

## Composants
1. <morceau> — <ce qu'il fait, en une ligne>
2. …

## Décisions
| Sujet | Décision | Tranché par |
|---|---|---|
| … | … | Louis / Claude (mineur) / hypothèse validée |

## Contraintes
- Techniques : <comptes, clés, coûts, crédits, outils imposés>
- Délai : …
- Autres : …

## Critères de fini
- [ ] <vérifiable : « quand je fais X, je vois Y »>
- [ ] …

## Hypothèses
<Ce qui n'a pas été tranché par Louis et qu'on a pris par défaut, avec la raison. « Aucune » si tout a été tranché.>

## Risques et premières vérifications
- …

## Lancement
<Ce qui se passe ensuite : /dev, workflow n8n, rédaction directe… et la première étape concrète.>

## Journal de l'interview
<Q → R, une ligne par question posée, dans l'ordre.>
```

Note for `/dev`: it detects a validated brief through the "Statut : validé" line, so keep that wording.
