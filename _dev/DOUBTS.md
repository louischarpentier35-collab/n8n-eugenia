## Pilote automatique de la chaîne — 2026-10-22

### Suppositions lourdes (au départ)
| # | Je suppose que… | Si c'est faux… | Statut |
|---|---|---|---|
| S1 | Un hook UserPromptSubmit peut injecter du contexte que Claude lit, et reçoit `session_id`, `cwd`, `prompt` | Pas de déclenchement fiable ni d'état par session | VÉRIFIÉ (test réel : TOKEN-ZEBRA relu par Claude ; entrée contient aussi `permission_mode`) |
| S2 | Un hook Stop qui renvoie `decision: block` + `reason` relance Claude avec la raison, et `stop_hook_active` vaut true au 2e arrêt | Pas de garantie de fin | VÉRIFIÉ (test réel : PELICAN, 2 appels, 2e avec stop_hook_active=true) |
| S3 | Claude ne connaît pas son propre `session_id` : il faut le lui injecter via le hook UserPromptSubmit | État par session impossible → collisions en parallèle | CONTOURNÉ (injection via le hook, vérifiée en S1) |
| S4 | `claude -p --settings <fichier>` charge hooks + skills utilisateur → tests de bout en bout possibles sans toucher aux réglages globaux | Tests seulement à la main dans l'app | VÉRIFIÉ |
| S5 | Un « skill pilote » qui lit les 3 skills suffit (pas besoin qu'un skill en appelle un autre) | Revoir l'enchaînement | HYPOTHÈSE (doc muette sur skill → skill) |

### Critères de fini (binaires)
- [ ] C1 — flou → interview ; clair → miroir + go ; question simple → rien — vérifié par : `claude -p` sur 3 messages types
- [ ] C2 — après go → verdict hostile sans intervention — vérifié par : run `claude -p` sur tâche factice, état final = verdict présent
- [ ] C3 — hook Stop bloque sans verdict, laisse passer sinon — vérifié par : tests unitaires du script (stdin simulé) + run réel
- [ ] C4 — question bloquante → push + continue — vérifié par : run factice avec question imposée, file d'attente non vide + travail terminé
- [ ] C5 — tout versionné + installation sur machine vierge simulée — vérifié par : `install.sh` dans un HOME temporaire, fichiers et réglages attendus présents
- [ ] C6 — tableau de bord à jour au changement de phase — vérifié par : lecture des données de la page après un changement de phase
- [ ] C7 — 2 sessions parallèles indépendantes — vérifié par : tests du script avec 2 session_id

### Doutes
| # | Doute | Vérification (écrite avant d'agir) | Prédiction | Avant | Après | Décision |
|---|---|---|---|---|---|---|
| D1 | Le hook Stop bloque sans verdict, laisse passer sinon, sans gêner les autres sessions | `tests/test_scripts.sh` (stdin simulé) | FAIL puis PASS | 17 FAIL | 35 PASS | continue |
| D2 | Les chemins avec espace (« IA work ») cassent les commandes | même test | — | FAIL (python ouvrait « /Users/lui/Documents/IA ») | PASS | chemins entre guillemets partout ; hooks installés via le lien sans espace |
| D3 | Une boucle infinie de blocages est possible | test anti-boucle : 6 blocages sans progrès | 6e laissé passer + phase « stalled » | — | PASS | MAX_IDLE_BLOCKS = 5 (Claude Code coupe à 8) |
| D4 | Une sauvegarde laissée dans skills/ serait chargée comme un 2e skill « dev » | lecture du script d'install | — | risque réel | corrigé | sauvegardes dans ~/.claude/backups/ |
| D5 | L'installation écrase les réglages ou les hooks de Louis | `tests/test_install.sh` (config vierge simulée + hook perso existant, 2 passages) | PASS | 2 FAIL (dev/agents absents du dépôt) | 12 PASS | continue |
| D6 | Le tableau de bord (type Dashboard) ne lit pas les fichiers locaux | doc du type | — | confirmé | — | export `dashboard.json` + chargement en asset par Claude à chaque phase |
| D7 | Le tableau de bord accepte un fichier vide | vue de Louis + document `runs` | PASS | FAIL (« no rows ») | PASS | ligne marqueur masquée par la page |
| D8 | Claude classe bien une tâche longue | e2e (outil de dépenses) | long | FAIL : classée courte (il se juge rapide) | PASS (classée longue au 2e run) | tri sur le périmètre (3 fonctionnalités, nouveau projet, fiabilité, > 2 fichiers), jamais sur la durée |
| D9 | La revue hostile utilise un relecteur neuf | e2e : sous-agent dans la transcription | ≥ 1 | FAIL (auto-relecture) | PASS | `verdict` refusé sans sous-agent relecteur dans la transcription (vérifié sur 2 vraies transcriptions : 5 et 0) |
| D10 | Claude attend le go | e2e | awaiting_go | FAIL ×2 (demande détaillée prise pour un go) | e2e en cours | verrou : `phase building` refusé tant que Louis n'a pas écrit après la demande de go (posé par le hook de message) |
| D11 | pytest échoue dans le projet construit | relance manuelle | — | 115 tests passent avec `python -m pytest` | — | bug du test (binaire pytest du venv), corrigé |

### Briques (réutiliser / adopter / construire)
| # | Besoin | Cherché où | Candidats (2-3) | Décision | Pourquoi / manque qui justifie de construire |
|---|---|---|---|---|---|
| B1 | Continuer jusqu'à la fin | doc Claude Code, web | `/goal` (natif), plugin Ralph Loop (hook Stop + fichier d'état + max itérations) | construire, en reprenant le principe de Ralph | les deux se lancent par une commande tapée par Louis ; pas de phases ni d'état par session |
| B2 | Choix automatique du skill | web | superpowers (hook SessionStart qui force la vérification des skills) | adopter l'idée, sur UserPromptSubmit | SessionStart seul se perd après de longues conversations ; UserPromptSubmit rappelle à chaque message (+ SessionStart après compaction) |
| B3 | Tableau de bord | quickstart Artifact | type Dashboard (imposé), page maison | type Dashboard | type recommandé par la plateforme pour un tableau de suivi |
| B4 | Notifications | outils de la session | PushNotification (app + téléphone via Remote Control), osascript | PushNotification par Claude + osascript en secours depuis le hook quand une tâche est bloquée | — |

### Revue d'optimalité

### Hypothèses prises seul (réversibles, à relire)

### Bilan
