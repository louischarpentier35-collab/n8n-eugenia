# Brief — Système skills/agents économe en tokens (v2)

- **Projet :** claude-skills (outillage Claude Code de Louis) · **Type :** code / config (mixte)
- **Date :** 2026-10-22 · **Statut :** brouillon

## Objectif
Garder la logique du système (interview, doute, revue hostile, /dev) mais diviser son coût en tokens par ~7 sur les petites tâches : une petite tâche comme « changer le prompt d'un nœud n8n » doit coûter ≤ 3 % de la limite au lieu de ~20 %.

## Pour qui
Louis, seul utilisateur. Il doit pouvoir travailler normalement sans choisir de skill, voir en une ligne à quel niveau Claude traite sa demande, et forcer le niveau en disant « niveau X ».

## Diagnostic de départ (session `6f5b2372`, prompt XML Gemini, 2026-10-22)
- 3 vrais messages de Louis → 410 tours de la conversation principale, tous sur Opus.
- Contexte relu à chaque tour : ~280k tokens en moyenne (max 454k), soit 114 M tokens relus en cache.
- ~15 réveils forcés par le hook Stop (« pas encore de verdict ») pendant que les relecteurs tournaient en arrière-plan.
- 5 relecteurs `general-purpose` hérités d'Opus : ~7 M tokens, soit ~6 % seulement du total.
- 119 commandes Bash, 12 interrogations d'exécution n8n.
→ Le coût vient surtout de la conversation principale sur Opus qui s'étire, pas des sous-agents.

## Périmètre
**Dedans :**
- Dépôt `claude-skills/` : skills (autopilot, interview, doubt-driven-dev, hostile-review, dev), agents, scripts de hooks, `install.sh`, README, tests existants.
- `CLAUDE.md` racine d'« IA work » (section Skills).
- `~/.claude/settings.json` : modèle par défaut + hooks (via `install.sh` de préférence).
- Tableau de bord Autopilot (Artifact existant, même URL).
- Commit + push sur le GitHub privé `louischarpentier35-collab/claude-skills` à la fin de chaque lot, **après accord de Louis**.

**Dehors (pas cette fois) :**
- Les projets, `_brain/`, les workflows `n8n/`.
- Les skills Anthropic synchronisés (`~/.claude/skills/synced`).

## Composants
1. **Routeur à 4 niveaux** — annoncé en une ligne en début de réponse, forçable par « niveau X ».
2. **Modèles** — Sonnet en principal, Haiku pour exécuter, Opus pour la réflexion lourde ; plus aucun sous-agent qui hérite d'Opus.
3. **Hooks** — Stop sans boucle ; injection du `UserPromptSubmit` raccourcie (règle des 4 niveaux).
4. **Allègement des skills** — process proportionné au niveau, textes plus courts.
5. **Hygiène des conversations** — alerte 150k, pas de ré-interrogation en boucle, exploration large déléguée à Haiku.
6. **Commande de mesure** — conso par session, par modèle, et où.
7. **Tableau de bord** — refonte graphique.

## Le routeur (composant 1)
| Niveau | Quoi | Process |
|---|---|---|
| **1** | Question, conversation | Réponse directe. Aucun skill. |
| **2** | Petite tâche claire (un fichier, un nœud, une modif localisée) | Je fais. Vérifications PASS/FAIL dans ma tête, pas de `DOUBTS.md`, pas de recherche web, pas de sous-agent, pas de suivi d'état, pas de revue hostile par sous-agent (auto-vérification). |
| **3** | Tâche moyenne (plusieurs fichiers / étapes, ou un choix à faire) | Miroir en 3 lignes + « go ». doubt-driven-dev complet (recherche de briques comprise). 1 relecteur Sonnet. Suivi d'état + tableau de bord. |
| **4** | Vrai projet (plan, architecture, nouvelle app, refonte) | Interview → brief → « go » → doubt-driven-dev ou /dev → revue hostile 4 relecteurs (Sonnet, Opus pour la sécurité). Suivi + tableau de bord. Je conseille de passer la conversation en Opus. |

- Je classe seul et j'annonce : « Niveau 2 — … ». **Dans le doute, le niveau le plus bas.**
- Louis force avec « niveau 1 / 2 / 3 / 4 » (« projet », « /dev », « interview » valent niveau 4).
- Une tâche peut monter de niveau en cours de route si elle s'avère plus grosse : je l'annonce.

## Décisions
| Sujet | Décision | Tranché par |
|---|---|---|
| Objectif | Petite tâche ≤ 3 % de la limite | Louis |
| Modèle principal | Sonnet par défaut (`model` dans `~/.claude/settings.json`) ; Opus à la main pour le niveau 4 | Louis |
| Routeur | 4 niveaux numérotés 1 à 4, je classe + Louis force par « niveau X » | Louis |
| Sous-agents | Haiku : explorateur, recherches, lectures larges, relecteurs simples. Sonnet : builder, product, déployeur, relecteur de code, débuggeur (1er essai). Opus : architecte, relecteur sécurité du niveau 4 (et débuggeur en 2e essai). Tout appel `Agent` passe un `model` explicite. | Louis (principe) / Claude (répartition fine) |
| Hook Stop | Gardé, mais bloque une seule fois par tâche et jamais pendant que des sous-agents tournent en arrière-plan ; seulement niveaux 3-4 | Louis |
| Revue hostile | Proportionnée : niveau 2 auto-vérification, niveau 3 1 relecteur Sonnet, niveau 4 4 relecteurs | Louis |
| Recherche de briques (doubt-driven-dev) | Niveaux 3 et 4 seulement | Louis |
| Suivi d'état / tableau de bord / notifications | Niveaux 3 et 4 seulement | Louis |
| Lecture large vs ciblée | Large (plusieurs fichiers, dossier inconnu, workflow n8n entier, > ~20k tokens) → agent Haiku qui renvoie un résumé. Ciblée (un fichier, une recherche, un nœud) → conversation principale. | Louis |
| Conversations longues | Vers ~150k tokens de contexte, je propose un handoff vers une conversation neuve | Louis |
| Ré-interrogations | Pas de boucle de vérification d'exécution n8n ou de tâche de fond : attendre la notification ; gros résultats lus par extraits | Louis |
| Mesure | Une commande locale (lecture des `.jsonl`), zéro token | Louis |
| Tableau de bord | Refait : « ce qui t'attend » en haut et en couleur, cartes des tâches en cours (titre, projet, niveau, étape, verdict), conso par session | Louis |
| Ordre | Lot 1 gros gains, lot 2 allègement + mesure + preuve, lot 3 tableau de bord | Louis |
| Périmètre | Système + config globale, push après accord | Louis |

## Lots
- **Lot 1 — gros gains :** modèle Sonnet par défaut ; hook Stop sans boucle ; routeur 4 niveaux (skill autopilot + texte injecté par `hook_prompt.py`) ; modèles des agents + `model` explicite dans chaque appel `Agent` des skills ; règles d'hygiène (150k, pas de polling, lecture large → Haiku) ; mise à jour du `CLAUDE.md` racine.
- **Lot 2 — allègement + mesure :** réécriture plus courte des skills selon les niveaux ; commande de mesure ; test de preuve (rejouer une petite tâche).
- **Lot 3 — tableau de bord :** refonte graphique de l'Artifact (même URL) avec les données de mesure.

## Contraintes
- Techniques : Claude Code ne change pas le modèle de la conversation principale en cours de session (seuls les sous-agents prennent un `model`) → le routeur conseille Opus, Louis bascule à la main. Le sélecteur de modèle de l'app desktop peut primer sur `settings.json` : à vérifier. Python 3 pour les scripts. Les tests existants (`skills/autopilot/tests/`) doivent rester verts.
- Coûts : pas d'exécution n8n réelle pour la preuve (Sandbox, sans `exec`).
- Délai : aucun imposé.
- Autres : tout en français côté Louis ; les skills restent rédigés en anglais (convention actuelle).

## Critères de fini
- [ ] Une question simple → réponse « Niveau 1 », aucun skill chargé, aucun sous-agent.
- [ ] « niveau 3 » dans un message force le niveau 3, et le niveau est annoncé.
- [ ] Le hook Stop ne bloque plus quand des sous-agents tournent en arrière-plan, et au plus une fois par tâche (test automatisé).
- [ ] Les tâches de niveau 1-2 n'écrivent rien dans `~/.claude/autopilot/tasks/`.
- [ ] Chaque agent de `agents/` a un `model:` et chaque appel `Agent` décrit dans les skills a un `model` explicite (vérifié par grep).
- [ ] `~/.claude/settings.json` a `model` = Sonnet, et une nouvelle session démarre bien sur Sonnet.
- [ ] La commande de mesure sort, pour une session donnée : tokens par modèle (entrée, cache, sortie), nombre de tours, sous-agents, réveils par hook, et un coût relatif.
- [ ] Preuve : une petite tâche rejouée (modifier un prompt dans un nœud n8n de Sandbox, sans exécution) coûte ≤ 15 % du coût de la session `6f5b2372` (≈ 3 % de la limite, puisque `6f5b2372` ≈ 20 %).
- [ ] Le tableau de bord s'ouvre à la même URL avec « ce qui t'attend » en haut, les cartes de tâches et la conso, lisible en mobile.
- [ ] Tests existants verts, `install.sh` relançable, README à jour.

## Hypothèses
- « % de la limite » n'est pas lisible directement : on l'estime par un coût relatif pondéré par modèle (tarifs publics Haiku/Sonnet/Opus), avec `6f5b2372` = 20 % comme référence. (Claude, découle de l'objectif validé.)
- La répartition fine des modèles par agent (tableau ci-dessus) est ma proposition dans le cadre « Haiku exécute, Opus réfléchit » validé par Louis.
- Les relecteurs de la revue hostile deviennent des appels `Agent` avec `model` explicite plutôt que de nouveaux fichiers d'agents. (Claude, mineur.)

## Risques et premières vérifications
- Sonnet en principal peut rater des subtilités : le niveau 4 conseille Opus ; si la qualité chute sur le niveau 3, on en reparle.
- Classement trop bas → travail bâclé ; classement trop haut → surcoût. Mitigé par l'annonce du niveau et le forçage.
- Vérifier d'abord que `model` dans `settings.json` est bien respecté par l'app desktop.
- Vérifier que le hook Stop peut savoir si des sous-agents tournent (sinon : ne bloquer qu'une fois et laisser les notifications réveiller).

## Lancement
Travail en mode doubt-driven-dev, lot par lot, revue hostile proportionnée à la fin de chaque lot, accord de Louis avant chaque commit + push. Première étape : vérifier comment l'app desktop applique le `model` de `settings.json`, puis corriger le hook Stop.

## Journal de l'interview
- Objectif de coût → ≤ 3 % pour une petite tâche.
- Modèle principal → Sonnet par défaut, Opus à la main.
- Hook Stop → gardé, sans boucle.
- Revue hostile → proportionnée.
- Routeur → 4 niveaux, numérotés 1 à 4 (idée de Louis : forcer par « niveau X » plutôt que par mots-clés).
- Déclencheur → je classe + Louis force.
- Sous-agents → Haiku exécute, Opus réfléchit.
- Mesure → une commande.
- Recherche de briques → niveaux 3-4.
- Hygiène → alerte 150k + pas de polling + exploration large par Haiku (règle large/ciblée fixée par Louis).
- Suivi/tableau de bord → niveaux 3-4, et refonte graphique du tableau de bord (aujourd'hui page blanche avec texte au centre).
- Périmètre → système + config globale, push après accord.
- Tableau de bord → ce qui t'attend, tâches en cours, conso par session.
- Preuve → rejouer une petite tâche.
- Ordre → gros gains d'abord, en 3 lots.
