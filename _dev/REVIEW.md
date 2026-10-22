## Revue hostile — Pilote automatique — 2026-10-22 (EN COURS, interrompue : limite d'usage)

**Verdict provisoire : À CORRIGER** — 2 angles sur 4 terminés (bugs/cas limites, sécurité/coûts) ; conformité et simplicité interrompus, à relancer.

### Corrigé
- R1 BLOQUANT (sécurité) — hook_stop.py desktop_notif : titre injecté dans le script AppleScript → exécution shell possible. Corrigé : texte passé en argument (`on run argv`).

### À corriger (points remontés, PAS ENCORE VÉRIFIÉS par un vérificateur)
- R2 MAJEUR — verdict accepté sans relecteur si le chemin de transcription est inconnu (tâche courte créée dans le tour) : refuser si None, retrouver la transcription via ~/.claude/projects/*/<session>.jsonl.
- R3 MAJEUR — détection du relecteur trop large (« preview » contient « review », agent `relecteur` de /dev, revue d'une tâche précédente) : mots entiers, exclure `relecteur`, ne compter qu'après le passage en reviewing.
- R4 MAJEUR — `init` écrase une longue tâche active de la même session : refuser sauf phase done ou --force.
- R5 MAJEUR — anti-boucle : met en `stalled` une tâche qui avance (compteur remis à zéro seulement par state.py) ET se contourne (n'importe quel `state.py set` remet à zéro) : mesurer le progrès réel (taille de la transcription), remise à zéro seulement sur changement de phase/verdict/réponse, plafond absolu.
- R6 MAJEUR — rien n'empêche mécaniquement push / envoi d'email / n8ncli exec pendant une tâche non surveillée : hook PreToolUse qui refuse ces actions en phase building/reviewing et renvoie vers `state.py ask`.
- R7 MAJEUR — test_e2e non isolé (vrai tableau de bord, push sur le téléphone, budget max 37 $) : CLAUDE_CONFIG_DIR temporaire + variable qui coupe tableau de bord et push ; chemins du skill via `state.py config`.
- R8 AMÉLIORATION — verrou du go contournable (`set go_seen`, `set mode short`, chemins via reviewing/paused/resume) : liste blanche des clés de `set`, go_seen exigé pour toute entrée en building/reviewing.
- R9 AMÉLIORATION — `answer` ne vide pas `waiting_reason` → le hook Stop reste désactivé.
- R10 AMÉLIORATION — assets du tableau de bord : course entre sessions, ancien id perdu si la suppression échoue.
- R11 SUGGESTION — couper titre/raison réinjectés (~100 caractères) ; écriture atomique de settings.json dans install.sh.

### Reste à faire
1. Vérifier R2-R11 (reproduire), corriger, tests unitaires pour chacun (les tests actuels ne les détectent pas).
2. Relancer les angles Conformité et Simplicité.
3. Re-revue ciblée, verdict final, puis push GitHub (non fait).
