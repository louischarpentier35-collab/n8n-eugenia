---
name: interview
description: Interview structurée de Louis avant un projet ou une tâche pas assez clarifiée, jusqu'à zéro doute, puis brief écrit, validation et lancement. À utiliser quand Louis tape /interview, dit « interview », « interviewe-moi », « pose-moi des questions avant de commencer ». Si Louis donne une tâche manifestement floue (objectif, périmètre ou critère de fin absents) sans demander l'interview, ne la lance pas : propose-la en une ligne.
---

# /interview — Lever tous les doutes avant de lancer

But : à la fin, tu dois pouvoir lancer le projet ou la tâche **sans deviner nulle part**. Tout ce qui n'est pas tranché par Louis est soit trouvé par toi, soit écrit noir sur blanc comme hypothèse qu'il a validée.

Argument optionnel : le sujet (« /interview refonte onboarding navarre-app »). Sans argument, le sujet est la dernière demande de Louis dans la conversation ; s'il n'y en a pas, ta première question est « Sur quoi on travaille ? ».

## Principes

- **Les faits sont ton travail, les décisions sont celles de Louis.** Ce qui se trouve dans `_brain/`, le code, les workflows `n8n/`, les fichiers du projet ou plus haut dans la conversation : tu le cherches, tu ne le demandes pas. Tu ne demandes que ce qui relève d'un choix ou d'une info qui n'existe que dans sa tête.
- **Toujours une recommandation.** Chaque question vient avec ta réponse recommandée et pourquoi en une phrase. Formule-la pour que « oui » / « ok » vaille acceptation.
- **Ordre des dépendances.** Ne pose jamais une question dont la réponse dépend d'une décision encore ouverte. Tranche d'abord le haut de l'arbre (pourquoi, pour qui, périmètre), puis descends.
- **Impact × incertitude.** Commence par ce qui change le plus le résultat et dont tu es le moins sûr. Ignore le cosmétique que tu peux trancher seul (et dis-le dans le brief).
- **Distingue ce que Louis a dit de ce que tu proposes.** Dans les récaps et le brief, jamais une de tes suggestions présentée comme sa décision.
- **Pas de limite de nombre de questions**, mais aucune question inutile : chaque question doit lever un doute réel qui t'obligerait sinon à deviner.
- Langage simple, en français, sans jargon non expliqué (Louis n'est pas développeur expert).

## Étape 1 — Exploration silencieuse (avant toute question)

1. Identifie le projet. S'il est dans `_brain/`, lis `_brain/[projet]/CLAUDE.md` (et `memoire.md` pour shiseido). Lis aussi les briefs précédents dans `_brain/[projet]/briefs/` ou `_dev/BRIEF.md` s'ils existent.
2. Selon le type de sujet, explore :
   - **App / code** : structure du dossier, README, `package.json` ou équivalent, `_dev/` s'il existe, le code touché par la tâche.
   - **Workflow n8n** : les fichiers du workflow concerné dans `n8n/` (lecture seule, pas de `n8ncli exec`), les credentials déjà utilisés, les workflows voisins réutilisables.
   - **Livrable non-code** : les documents sources, consignes, livrables précédents du même type.
   - **Projet scolaire** : consignes du cours, barème, contraintes imposées (ex. niveau débutant, pas de nœud Code).
   Si l'exploration est large, lance un sous-agent Explore et garde seulement ses conclusions.
3. Remplis mentalement la grille de couverture (voir `grille.md` dans ce dossier) : pour chaque ligne, **Clair** (trouvé ou dit), **Partiel**, ou **Manquant**.

## Étape 2 — Miroir

Premier message à Louis, court :
- **Ce que j'ai compris** : 3 à 6 puces (objectif, contexte trouvé, en citant le fichier quand l'info vient de là).
- **Les morceaux du sujet** : la liste des composants / sous-parties que tu vois (ex. « 1. récupération des vidéos, 2. analyse, 3. envoi du rapport »). Elle sert à ne pas oublier un composant parce qu'un autre est mieux décrit.
- **La grille** : tableau compact des lignes de la grille avec leur statut (✅ clair / 🟡 partiel / ❌ manquant).
- Puis : « Qu'est-ce qui est faux ou qui manque ? » et enchaîne directement sur le premier round de questions dans le même message.

## Étape 3 — Rounds de questions

À chaque round, prends le **front** : les questions ouvertes dont tous les prérequis sont tranchés. Puis :

- **Questions fermées et indépendantes** (options nettes) → `AskUserQuestion`, 2 à 4 questions par appel. Option recommandée en premier, suffixée « (Recommandé) », avec une description qui donne la conséquence de chaque choix.
- **Question ouverte ou structurante** (le pourquoi, l'utilisateur final, une idée à faire émerger) → une seule question, en texte, dans ce format :
  > **Question :** …
  > **Pourquoi ça compte :** … (ce que ça change concrètement)
  > **Ma recommandation :** … (et le compromis)

Règles pendant les rounds :
- **Angles morts prioritaires de Louis** (ce qui lui a fait perdre du temps par le passé) : le pourquoi et l'utilisateur final, le périmètre et le hors-périmètre, les critères de « fini », les contraintes techniques (comptes, clés API, coûts, crédits, outils imposés, données réellement disponibles). Ne les laisse jamais en 🟡 ou ❌.
- **Mots flous** : dès que Louis dit « simple », « rapide », « propre », « joli », « automatique », « comme X », « fini »… demande ce que ça veut dire concrètement, avec une proposition chiffrée ou vérifiable.
- **« Je ne sais pas » / « fais comme tu penses »** : propose ta valeur par défaut, marque-la **hypothèse**, demande juste « ok ? » et passe à la suite. Ne repose jamais la même question.
- **Une réponse change tout ?** Mets à jour la liste des composants et la grille ; certaines questions deviennent caduques, n'y reviens pas.
- **Un tour de défi**, une seule fois, quand le sujet est cadré : « Quelle est la version minimale qui te serait déjà utile ? » ou « Et si on ne faisait pas X du tout ? ». Utile surtout pour les gros projets.
- **Récap tous les ~5 réponses** : 2 à 4 puces de ce qui a été décidé + la grille mise à jour. Courte, pas de pavé.
- Louis peut dire **« stop »** à tout moment : les lignes encore ouvertes deviennent des hypothèses explicites (tes recommandations), que tu lui listes avant d'écrire le brief.

## Étape 4 — Condition d'arrêt

Arrête les questions quand **les deux** conditions sont vraies :
1. Toutes les lignes de la grille (tronc commun + module du type de sujet) sont ✅, ou marquées hypothèse validée par Louis.
2. Test du lanceur : « Si je devais commencer maintenant, y a-t-il un seul endroit où je devrais deviner ? » Passe en revue chaque composant de la liste. Si oui → nouveau round.

Pour un projet gros ou une interview longue (plus de ~15 questions), rédige un brouillon de brief et fais-le relire par un sous-agent neuf (general-purpose) avec la consigne : « Liste chaque endroit où quelqu'un qui doit exécuter ce brief devrait deviner. » Trie ses trous : déjà répondu (ignore), mineur (tranche toi-même et note-le dans le brief), décision de Louis (un dernier round).

## Étape 5 — Brief

Écris le brief avec le modèle `brief-template.md` (dans ce dossier). Emplacement :
- **Projet avec un dossier de code** (app, ou tâche destinée à `/dev`) → `<dossier projet>/_dev/BRIEF.md`. S'il en existe déjà un, archive l'ancien en `_dev/briefs/AAAA-MM-JJ-sujet.md` avant de l'écraser.
- **Sinon** (n8n, livrable non-code, tâche ponctuelle) → `_brain/[projet]/briefs/AAAA-MM-JJ-sujet-court.md`.
- **Sujet hors `_brain/`** → `_brain/[nouveau-ou-divers]/briefs/…` uniquement si Louis le veut, sinon dans le dossier de travail.

Puis ajoute une ligne dans `_brain/[projet]/CLAUDE.md` (section tâches en cours, ou en fin de fichier) : `- Brief <sujet> (AAAA-MM-JJ) → <chemin du brief>`.

## Étape 6 — Validation puis lancement

1. Montre à Louis un résumé du brief : objectif en une phrase, ce qui est dedans / dehors, critères de fini, hypothèses prises, et le lien vers le fichier.
2. Demande une validation explicite (« Je lance ? »). Un « cool », « sympa » ou un emoji n'est pas une validation : redemande. S'il corrige, mets à jour le brief et re-montre seulement ce qui a changé.
3. Une fois validé, lance :
   - **App / gros chantier de code** → propose `/dev` (qui lira `_dev/BRIEF.md` et sautera sa propre clarification).
   - **Workflow n8n** → suis `.agents/skills/n8n/SKILL.md` (pull, modif, validate, test). Toujours l'accord de Louis avant un `n8ncli exec` réel ou une publication.
   - **Autre** → exécute directement la tâche en t'appuyant sur le brief.
   - Si la conversation est déjà très longue, propose plutôt de lancer dans une conversation neuve (skill `handoff`), avec le brief comme point d'entrée.

## Ce qu'il ne faut pas faire

- Demander quelque chose qui est dans `_brain/`, le code ou la conversation.
- Poser une question sans recommandation.
- Envoyer un pavé de 8 questions dont la moitié dépend de la première.
- Coder, modifier un workflow ou produire le livrable avant la validation du brief.
- S'arrêter « au feeling » alors qu'une ligne de la grille est encore ❌.
- Garder les décisions seulement dans le chat : tout finit dans le brief.
