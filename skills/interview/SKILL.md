---
name: interview
description: Interview Louis until zero doubt remains, then a written brief, validation and launch. Automatic (autopilot, /dev) when a task's goal, scope or definition of done is unclear; also on /interview, "interview", "interviewe-moi", "pose-moi des questions avant de commencer".
---

# /interview — Remove every doubt before launching

At the end you can launch **without guessing anywhere**: what Louis hasn't decided is either found by you or written as an assumption he validated. Topic: the argument, else his latest request, else « Sur quoi on travaille ? ». French and plain words (he isn't an expert developer).

## Principles

- **Facts are your job, decisions are his.** Anything in `_brain/`, the code, `n8n/` or the conversation: look it up, don't ask.
- **Every question carries your recommendation** and a one-line reason, phrased so that « oui » accepts it.
- **Dependency order**: never ask what depends on an open decision; settle why / for whom / scope first.
- **Impact × uncertainty first**; decide cosmetic details yourself (and say so in the brief).
- Never present your suggestion as his decision. No cap on questions, no useless one.

## Step 1 — Silent exploration

1. Project in `_brain/` → read its `CLAUDE.md` (+ `memoire.md` for shiseido) and earlier briefs (`briefs/`, `_dev/BRIEF.md`).
2. Explore by type: code (structure, README, deps, `_dev/`, the code touched); n8n (the workflow files in `n8n/`, read only, credentials in use, reusable neighbours); document (sources, instructions, previous deliverables); school project (instructions, grading, imposed constraints such as no Code node).
   Broad read (several files, unknown folder, whole workflow, > ~20k tokens) → Explore subagent with `model: "haiku"`, keep its conclusions. Targeted read → yourself.
3. Fill the grid of `coverage-grid.md`: each line ✅ clear / 🟡 partial / ❌ missing.

## Step 2 — Mirror

Short first message: **what I understood** (3-6 bullets, citing files) · **the pieces of the topic** (numbered components, so none gets forgotten) · **the grid** (compact table) · « Qu'est-ce qui est faux ou qui manque ? » and the first round of questions in the same message.

## Step 3 — Question rounds

Each round, ask the frontier (open questions whose prerequisites are settled):
- Closed, independent → `AskUserQuestion`, 2-4 per call, recommended option first with « (Recommandé) », consequence in each description.
- Open or structuring → one question in text: **Question :** … / **Pourquoi ça compte :** … / **Ma recommandation :** … (and the trade-off).

Rules:
- Never leave 🟡 / ❌ on Louis's blind spots: the why and end user, scope and out of scope, definition of done, technical constraints (accounts, API keys, costs, credits, imposed tools, data really available).
- Vague words (« simple », « rapide », « propre », « automatique », « comme X », « fini ») → ask what it means, with a checkable proposal.
- « Je ne sais pas » / « fais comme tu penses » → your default as an **assumption**, « ok ? », move on. Never ask twice.
- An answer changes everything → update components and grid, drop obsolete questions.
- Once, when framed: « Quelle est la version minimale qui te serait déjà utile ? » or « Et si on ne faisait pas X ? ».
- Recap every ~5 answers (2-4 bullets + grid). « stop » → open lines become listed assumptions (your recommendations).

## Step 4 — Stop condition

Both: every grid line (core + topic module) ✅ or a validated assumption; and the launcher test — going through each component, is there one place where you'd have to guess? If yes, another round.
Big project or > ~15 questions: have the draft brief checked by a fresh subagent (`model: "sonnet"`): « Liste chaque endroit où quelqu'un qui exécute ce brief devrait deviner. » Gaps: already answered (ignore), minor (decide, note it), Louis's call (last round).

## Step 5 — Brief

From `brief-template.md`. Code folder (app, task for /dev) → `<project>/_dev/BRIEF.md` (archive an existing one to `_dev/briefs/YYYY-MM-DD-topic.md` first). Otherwise → `_brain/[project]/briefs/YYYY-MM-DD-topic.md`. Outside `_brain/` → working folder unless Louis wants it there. Add to `_brain/[project]/CLAUDE.md`: `- Brief <topic> (YYYY-MM-DD) → <path>`.

## Step 6 — Validation, launch

1. Summary: goal in one sentence, in / out, definition of done, assumptions, link.
2. Explicit validation (« Je lance ? »); « cool » or an emoji isn't one. Corrections → update, show only what changed.
3. Launch (under autopilot, follow its step 2 instead): big code project → offer `/dev`; n8n → `.agents/skills/n8n/SKILL.md` (pull, edit, validate, test; Louis's approval before a real `n8ncli exec` or a publication); else do it from the brief. Very long conversation → offer a `handoff` with the brief as entry point.

## Never

Ask what's already findable; ask without a recommendation; send a block of dependent questions; build before the brief is validated; stop while a line is ❌; keep decisions only in the chat.
