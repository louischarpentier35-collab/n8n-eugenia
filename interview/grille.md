# Grille de couverture

Chaque ligne est ✅ clair, 🟡 partiel ou ❌ manquant. Le tronc commun s'applique toujours ; ajoute le module correspondant au type de sujet (plusieurs si le sujet est mixte, par ex. une app qui appelle un workflow n8n).

Les lignes marquées ★ sont les angles morts habituels de Louis : ne jamais les laisser ouvertes.

## Tronc commun

| Ligne | La question derrière |
|---|---|
| ★ Pourquoi | Quel problème on résout, qu'est-ce qui se passe si on ne le fait pas ? |
| ★ Pour qui | Qui utilise / lit / reçoit le résultat ? Louis lui-même, un client Capsule, un prof, une équipe Shiseido ? |
| ★ Dans le périmètre | La liste précise de ce qu'on fait. |
| ★ Hors périmètre | Ce qu'on ne fait pas cette fois (et éventuellement plus tard). |
| ★ Critères de fini | Comment on vérifie concrètement que c'est terminé et que ça marche (testable, observable). |
| ★ Contraintes techniques | Comptes, clés API, coûts et crédits, outils imposés, accès, données réellement disponibles. |
| Échéance | Pour quand, et y a-t-il des étapes intermédiaires ? |
| Existant | Ce qu'on réutilise (code, workflow, doc, template) et ce qu'on ne doit pas casser. |
| Vocabulaire | Les termes qui peuvent être compris de deux façons. |
| Risques / inconnues | Ce qui peut faire échouer le projet, ce qu'il faudra vérifier en premier. |

## Module App / code

| Ligne | La question derrière |
|---|---|
| Plateforme | Web, mobile (iOS/Android), desktop, extension ? Responsive ? |
| Stack | Imposée, déjà en place, ou libre (alors l'architecte de /dev propose) ? |
| Parcours principal | Les 1 à 3 parcours utilisateur indispensables, étape par étape. |
| Données | Quelles données, d'où elles viennent, où elles sont stockées, qui peut les voir ? |
| Comptes / connexion | Faut-il des utilisateurs, des rôles, une authentification ? |
| Mise en ligne | Local seulement, déployé (où), publié sur un store ? |
| Cas limites | Hors connexion, erreurs d'API, données vides, gros volumes. |

## Module Workflow n8n

| Ligne | La question derrière |
|---|---|
| Déclencheur | Planifié (fréquence), webhook, manuel, formulaire, email ? |
| Sources | Quelles API / apps en entrée, credentials déjà présents dans n8n ou à créer ? |
| Coût par exécution | Crédits consommés (ScrapeCreators, IA…), quota d'exécutions de production. |
| Sorties | Où va le résultat (email, Sheets, Slack, base…) et sous quelle forme exacte ? |
| Volume | Combien d'éléments par exécution, combien d'exécutions par jour ? |
| Erreurs | Que se passe-t-il quand une API échoue ou renvoie vide ? Qui est prévenu ? |
| Règles | Pas de nœud Code (nœuds natifs + expressions) ; rangement Projects/Sandbox. |
| Test | Peut-on tester avec des données simulées (`n8ncli test`) ? Quand un exec réel est-il nécessaire ? |

## Module Livrable non-code (doc, stratégie, cas pratique, mission Shiseido, business Capsule)

| Ligne | La question derrière |
|---|---|
| Lecteur | Qui lit, quel est son niveau, qu'attend-il pour être convaincu ? |
| Format | Doc, slides, tableur, email, page ? Longueur ? |
| Ton | Formel, pédagogique, commercial, interne ? Langue ? |
| Sources | Sur quoi on s'appuie, qu'est-ce qui est confidentiel ? |
| Message clé | La phrase que le lecteur doit retenir. |
| Évaluation | Comment le livrable sera jugé (barème, décision attendue, validation par un manager) ? |

## Module Projet scolaire

| Ligne | La question derrière |
|---|---|
| Consignes | Le texte exact des consignes, les éléments obligatoires. |
| Barème | Ce qui rapporte des points. |
| Niveau | Le code / livrable doit rester au niveau de Louis (explicable à l'oral) ? |
| Outils imposés | Technos, plateformes, règles du cours. |
| Rendu | Date, format, oral ou non, travail en groupe (qui fait quoi) ? |
