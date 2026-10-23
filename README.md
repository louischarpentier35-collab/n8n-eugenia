# claude-skills

Skills, agents et hooks Claude Code de Louis. Chaque dossier qui contient un `SKILL.md` est un skill, relié à `~/.claude/skills/` par un lien symbolique : on modifie ici, c'est actif partout.

**Louis ne choisit jamais de skill.** Un hook rappelle à chaque message le routeur à 4 niveaux ; Claude annonce le niveau (« Niveau N — … ») et Louis peut le forcer (« niveau 3 ») :

```
message de Louis
  ├─ niveau 1  question / discussion ........ réponse directe, aucun skill
  ├─ niveau 2  petite tâche localisée ....... faite + vérifiée par Claude seul (pas de skill, sous-agent ni suivi)
  ├─ niveau 3  tâche moyenne ................ autopilot : miroir + « go » → doubt-driven-dev → 1 relecteur Sonnet
  └─ niveau 4  vrai projet .................. autopilot : interview → brief → « go » → doubt-driven-dev ou /dev
                                               → revue hostile complète (Opus conseillé pour la conversation)
```

Économie de tokens : conversation principale sur Sonnet par défaut (`model` dans `settings.json`), `model` explicite pour chaque sous-agent (Haiku pour chercher, Sonnet pour construire/relire, Opus pour l'architecte et la sécurité), lecture large déléguée à Haiku, pas de vérification en boucle, alerte de handoff au-delà de ~150k tokens de contexte (calculée par le hook).

| Dossier | Rôle |
|---|---|
| [autopilot](autopilot/SKILL.md) | Point d'entrée de toute tâche : tri, enchaînement, état par session, hooks, tableau de bord |
| [interview](interview/SKILL.md) | Interview jusqu'à zéro doute, puis brief et validation |
| [doubt-driven-dev](doubt-driven-dev/SKILL.md) | Construire en doutant : vérifications PASS/FAIL écrites avant d'agir, recherche de briques existantes, revue d'optimalité |
| [hostile-review](hostile-review/SKILL.md) | Revue stricte du travail fini : 4 relecteurs neufs (ou 1 en mode léger), chaque point vérifié, erreurs corrigées, verdict + REVIEW.md |
| [dev](dev/SKILL.md) + [agents](agents/) | Équipe d'agents de développement (explorateur, product, architecte, builders, relecteur, debuggeur, déployeur) |

## Garanties (hooks dans `~/.claude/settings.json`)

- **UserPromptSubmit** : injecte le routeur à 4 niveaux, l'identifiant de session, l'état de la tâche en cours et, au-delà de ~150k tokens de contexte, une alerte de handoff.
- **SessionStart** (après compaction ou reprise) : réinjecte l'état de la tâche.
- **Stop** (niveaux 3-4) : une tâche lancée (phase construction ou revue) ne peut pas se terminer sans verdict de revue hostile, sauf si elle attend une décision de Louis. Il ne bloque jamais pendant qu'un sous-agent ou une commande tourne en arrière-plan (la notification réveille Claude), et bloque une seule fois : un second arrêt sans progrès fait passer la tâche « bloquée », avec notification.

État : un fichier JSON par session dans `~/.claude/autopilot/tasks/`, géré par `autopilot/scripts/state.py`. Tableau de bord : URL dans `~/.claude/autopilot/config.json`.

## Installer (nouvelle machine, ou après un `git pull`)

```bash
git clone https://github.com/louischarpentier35-collab/claude-skills.git ~/Documents/IA\ work/claude-skills
bash ~/Documents/IA\ work/claude-skills/install.sh --dashboard-url https://claude.ai/artifact/MhkCT9iqJLiqKegTrxBprJ
```

Le script est relançable sans risque : il remplace les liens, déplace tout fichier réel qu'il remplacerait dans `~/.claude/backups/`, sauvegarde `settings.json` et n'ajoute qu'un seul hook autopilot par événement, en gardant les autres réglages. Prérequis : `python3`.

Pour les longues tâches, mets la session en **mode auto** (réglage de permissions de l'app) : sans lui, la tâche attend tes validations de commandes.

## Tests

```bash
bash autopilot/tests/test_scripts.sh
```

```bash
bash autopilot/tests/test_install.sh
```

```bash
bash autopilot/tests/test_e2e.sh routing
```

Les deux premiers sont gratuits. Le troisième lance de vraies sessions Claude (quelques dollars) ; `all` ajoute la chaîne complète après « go » (plus long et plus cher).

## Organisation du repo

- `skills/` : les skills Claude (autopilot, dev, doubt-driven-dev, hostile-review, interview). `install.sh` crée leurs liens dans `~/.claude/skills`.
- `agents/` : les sous-agents de /dev.
- `workflows/` : le workflow n8n rendu pour le cours « Veille carrousels TikTok Shop » (export `.workflow.ts`, à importer avec n8n-cli).

## Projet de cours n8n : « Veille carrousels TikTok Shop »

Workflow : [`workflows/Veille carrousels TikTok Shop.workflow.ts`](workflows/Veille%20carrousels%20TikTok%20Shop.workflow.ts) (version du 23/10/2026, 60 nœuds). Il repère les créateurs TikTok français qui vendent par carrousels photo liés à TikTok Shop, classe leurs carrousels (vitesse × surperformance) dans un Google Sheet et envoie un récapitulatif par email (top 10 + analyse rédigée par Gemini).

- **Qualification des candidats** (formulaire) : 1 crédit ScrapeCreators par candidat, le compte devient « suivi » s'il publie assez de carrousels shoppables.
- **Collecte** (manuelle) : 30 posts populaires par compte suivi, filtre carrousels shoppables puis légendes en français, scores, mise à jour du classement, bilan, email.

**Vidéo de démonstration** : _lien à ajouter_. Transcript : _à ajouter_.

### Standards du cours

| Standard | État |
|---|---|
| Cards qui expliquent le workflow | 9 notes sur le canevas : 1 par déclencheur, 1 par étape (7) |
| Nœuds renommés | Oui, tous |
| Credentials renommés | ScrapeCreatorsAPI, GoogleSheetsAPI, GmailAPI, Gemini |
| Pas de nœud Code | Aucun nœud Code : nœuds natifs (Set, Filter, If, Sort, Limit, Summarize, Merge, HTML…) et expressions `{{ }}` |
| Pas de nœud HTTP sauf si indispensable | 2 nœuds HTTP, indispensables (voir ci-dessous) |

**Pourquoi 2 nœuds HTTP Request ?** « Posts populaires du candidat » et « Posts populaires du compte suivi » appellent l'API ScrapeCreators, qui n'a pas de nœud natif dans n8n. Le nœud HTTP Request est donc le seul moyen de l'appeler. La clé API n'est pas dans le workflow : elle est dans un credential d'en-tête (`x-api-key`). La pagination (`max_cursor`) utilise l'option native du nœud HTTP, sans code. La card « Étape 2 » du canevas le rappelle.

### Importer et tester avec n8n-cli

```bash
n8ncli validate "workflows/Veille carrousels TikTok Shop.workflow.ts"
```

```bash
n8ncli test "workflows/Veille carrousels TikTok Shop.workflow.ts" --pin-data <données-simulées.json> --trigger "Lancer la collecte"
```

`n8ncli test` exécute le workflow avec les sorties de nœuds fournies dans le fichier JSON (par exemple les réponses d'une vraie collecte) : les nœuds simulés n'appellent pas l'API, donc 0 crédit ScrapeCreators.
