# Brief — Pilote automatique de la chaîne interview → doubt-driven-dev → hostile-review

- **Projet :** claude-skills (outillage Claude Code de Louis) · **Type :** code / config (mixte)
- **Date :** 2026-10-22 · **Statut :** validé par Louis le 2026-10-22

## Objectif
Louis ne choisit plus jamais un skill : Claude décide seul quand interviewer, enchaîne le travail en mode doute puis la revue hostile, et peut ainsi mener des tâches de plusieurs heures sans lui.

## Pour qui
Louis, sur toutes ses sessions Claude Code (app desktop, sur son Mac). Il décrit une tâche, valide le brief, part ; il revient à un travail vérifié et relu.

## Périmètre
**Dedans :**
- Déclenchement automatique : interview lancée d'office si la demande est floue ; sinon miroir de 3 lignes + demande de « go ».
- Enchaînement automatique après le « go » : travail en mode doubt-driven-dev → hostile-review → bilan, sans intervention de Louis. Choix automatique de `/dev` pour un projet de code à plusieurs composants.
- Garde-fou déterministe : un hook empêche de terminer une longue tâche lancée tant que la revue hostile n'a pas rendu son verdict ; il n'intervient jamais dans une conversation normale.
- Questions bloquantes pendant le travail : notification push, question mise en file, le travail continue sur ce qui n'en dépend pas.
- Plusieurs longues tâches en parallèle dans des sessions indépendantes, chacune avec son propre état.
- Tableau de bord simple (page privée) : longues tâches, phase, questions en attente, verdict, liens.
- Versionnage sur GitHub de tout le système (3 skills, pilote, hooks, `/dev` et ses 7 agents) + procédure d'installation.

**Dehors (pas cette fois) :**
- Exécution dans le cloud et tâches planifiées.
- Un chef d'orchestre qui découpe une demande en plusieurs sessions pilotées.

## Composants
1. **Skill pilote `autopilot`** — point d'entrée unique choisi par Claude : trie la demande (conversation / tâche courte / longue tâche), lance interview ou miroir, attend le « go », crée l'état, enchaîne les phases.
2. **Hook UserPromptSubmit** — rappel court de la chaîne injecté à chaque message, pour que le choix ne dépende pas du seul flair de Claude.
3. **Fichier d'état par tâche** — une tâche lancée = un fichier d'état (par session) : phase, brief, journal, questions en attente, verdict.
4. **Hook Stop** — bloque l'arrêt si une tâche lancée dans cette session n'a pas de verdict de revue hostile ; laisse passer sinon ; anti-boucle.
5. **Notifications** — push à chaque question bloquante et à la fin.
6. **Tableau de bord** — page privée mise à jour à chaque changement de phase.
7. **Ajustements des 3 skills et de `/dev`** — passage de « proposer » à « lancer », branchement sur le pilote et l'état.
8. **Dépôt et installation** — `/dev` + agents + hooks dans `claude-skills`, script ou procédure d'installation.

## Décisions
| Sujet | Décision | Tranché par |
|---|---|---|
| Longue tâche | Plusieurs heures de travail autonome, sans Louis | Louis |
| Interview | Lancée d'office si la demande est floue ; sinon miroir + go | Louis |
| Feu vert | Le « go » sur le brief est le dernier point de contrôle | Louis |
| Question bloquante | Notification + file d'attente + le travail continue | Louis |
| Lieu d'exécution | App desktop sur le Mac (accès _brain, n8n, hooks) | Louis |
| Permissions | Mode auto pendant les longues tâches, réglé par Louis lui-même | Louis |
| `/dev` | Choisi automatiquement pour un projet de code à plusieurs composants | Louis |
| Parallèle | Sessions indépendantes, état séparé par session | Louis |
| Tableau de bord | Oui, page simple | Louis |
| Mécanisme de déclenchement | Hook UserPromptSubmit + description du skill pilote | Claude (technique) |
| Garantie de fin | Hook Stop de type commande (script), lisant le fichier d'état — déterministe et gratuit, plutôt qu'un hook « agent » | Claude (technique) |
| Enchaînement des skills | Un skill pilote qui lit et applique les 3 skills (l'appel d'un skill par un autre n'est pas garanti par la doc) | Claude (technique) |
| Emplacement de ce brief | `claude-skills/_dev/BRIEF.md` | Claude (mineur) |
| Nom du skill pilote | `autopilot` | Claude (mineur) |

## Contraintes
- Techniques : Claude Code 2.1.306, app desktop ; aucun hook existant dans `~/.claude/settings.json` ; hooks dans les réglages utilisateur (toutes sessions locales) ; le mode de permissions et les réglages de sécurité restent à Louis ; garde-fou anti-boucle du hook Stop (`stop_hook_active`, plafond de 8 blocages consécutifs côté Claude Code).
- Coûts : le hook UserPromptSubmit ajoute un court texte à chaque message (à garder bref) ; pas d'appel de modèle dans les hooks.
- Délai : aucun imposé.
- Autres : les actions coûteuses / irréversibles (exec n8n réel, envoi, push, déploiement, service payant) restent soumises à Louis, même en pilote automatique.

## Critères de fini
- [ ] C1 — Un message flou, sans nommer de skill, déclenche l'interview ; un message clair déclenche un miroir + demande de « go » ; une simple question ne déclenche rien.
- [ ] C2 — Après le « go », la tâche va jusqu'au verdict de revue hostile sans intervention de Louis.
- [ ] C3 — Le hook Stop bloque la fin d'une tâche lancée sans verdict, et ne gêne jamais une conversation normale (testé dans les deux sens).
- [ ] C4 — Une question bloquante produit une notification push et le travail continue sur le reste.
- [ ] C5 — Tout est versionné sur GitHub (3 skills, pilote, hooks, `/dev` et ses agents) avec une procédure d'installation qui marche sur une installation vierge (simulée).
- [ ] C6 — Le tableau de bord affiche les longues tâches, leur phase, les questions en attente et le verdict, et se met à jour quand la phase change.
- [ ] C7 — Deux sessions en parallèle ont chacune leur état, le hook de l'une ne bloque pas l'autre.

## Hypothèses
- Le hook UserPromptSubmit s'applique à toutes les sessions locales (tous projets) : c'est voulu, puisque Louis veut ne jamais choisir.
- Tests de bout en bout faits avec `claude -p` sur une petite tâche factice dans un dossier de test : quelques appels de modèle, pas de crédit d'API tiers.

## Risques et premières vérifications
- Hook Stop trop zélé qui bloque des conversations normales → vérifier d'abord C3 dans les deux sens.
- Le choix automatique du skill reste un jugement du modèle → le hook UserPromptSubmit le rend systématique ; mesurer sur plusieurs messages types (C1).
- Format exact des entrées / sorties des hooks dans cette version → le vérifier par un test réel avant de bâtir dessus.
- `claude -p` charge-t-il bien les hooks et skills utilisateur ? → à vérifier en premier.

## Lancement
Travail en mode doubt-driven-dev directement dans cette session (pas `/dev` : c'est de la config et des scripts, pas une app), puis hostile-review. Première étape : vérifier par un test réel le format des hooks et le chargement par `claude -p`.

## Journal de l'interview
- Longue tâche ? → plusieurs heures sans Louis
- Qui lance l'interview ? → Claude, si c'est flou
- Lancer seul après le brief ? → après le « go » de Louis
- Question bloquante ? → notification + continuer le reste
- Lieu ? → sur le Mac, dans l'app
- Permissions ? → mode auto (réglé par Louis)
- `/dev` automatique ? → oui pour les projets de code à plusieurs composants
- Hors périmètre ? → cloud et tâches planifiées
- Parallèle ? → sessions indépendantes
- Tableau de bord ? → oui, page simple
- Critères de fini ? → validés (5) ; ajout C6 et C7 découlant des réponses parallèle et tableau de bord
