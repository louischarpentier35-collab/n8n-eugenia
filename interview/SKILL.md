---
name: interview
description: Structured interview of Louis before a project or an under-specified task, until zero doubt remains, then a written brief, validation and launch. Started automatically (by the autopilot skill, or /dev) whenever a task's goal, scope or definition of done is unclear - Louis never has to ask for it. Also when Louis types /interview, says "interview", "interviewe-moi", "pose-moi des questions avant de commencer".
---

# /interview — Remove every doubt before launching

Goal: at the end, you must be able to launch the project or task **without guessing anywhere**. Anything Louis has not decided is either found by you, or written down explicitly as an assumption he has validated.

Optional argument: the topic ("/interview refonte onboarding navarre-app"). Without an argument, the topic is Louis's latest request in the conversation; if there is none, your first question is "Sur quoi on travaille ?".

**Language:** this skill is written in English, but always talk to Louis in French and write the brief in French. Use plain language, no unexplained jargon (Louis is not an expert developer).

## Principles

- **Facts are your job, decisions are Louis's.** Anything in `_brain/`, the code, the `n8n/` workflows, the project files or earlier in the conversation: you look it up, you don't ask. You only ask about choices, or information that exists only in his head.
- **Always a recommendation.** Every question comes with your recommended answer and a one-sentence reason. Phrase it so that "oui" / "ok" means accepting it.
- **Dependency order.** Never ask a question whose answer depends on a decision still open. Settle the top of the tree first (why, for whom, scope), then go down.
- **Impact × uncertainty.** Start with what changes the outcome the most and what you are least sure about. Skip cosmetic details you can decide yourself (and say so in the brief).
- **Separate what Louis said from what you propose.** In recaps and in the brief, never present one of your suggestions as his decision.
- **No cap on the number of questions**, but no useless question: each one must remove a real doubt that would otherwise force you to guess.

## Step 1 — Silent exploration (before any question)

1. Identify the project. If it is in `_brain/`, read `_brain/[project]/CLAUDE.md` (and `memoire.md` for shiseido). Also read previous briefs in `_brain/[project]/briefs/` or `_dev/BRIEF.md` if they exist.
2. Depending on the type of topic, explore:
   - **App / code**: folder structure, README, `package.json` or equivalent, `_dev/` if it exists, the code the task touches.
   - **n8n workflow**: the files of the workflow concerned in `n8n/` (read only, no `n8ncli exec`), credentials already in use, neighbouring workflows that could be reused.
   - **Non-code deliverable**: source documents, instructions, previous deliverables of the same kind.
   - **School project**: course instructions, grading scale, imposed constraints (e.g. beginner level, no Code node).
   If the exploration is broad, launch an Explore subagent and keep only its conclusions.
3. Fill in the coverage grid mentally (see `coverage-grid.md` in this folder): each line is **Clear** (found or said), **Partial**, or **Missing**.

## Step 2 — Mirror

First message to Louis, short:
- **What I understood**: 3 to 6 bullets (goal, context found, citing the file when the information comes from one).
- **The pieces of the topic**: the list of components / sub-parts you see (e.g. "1. fetch the videos, 2. analysis, 3. send the report"). It prevents forgetting one component because another one is better described.
- **The grid**: a compact table of the grid lines with their status (✅ clear / 🟡 partial / ❌ missing).
- Then: "Qu'est-ce qui est faux ou qui manque ?" and go straight into the first round of questions in the same message.

## Step 3 — Question rounds

Each round, take the **frontier**: the open questions whose prerequisites are all settled. Then:

- **Closed, independent questions** (clear options) → `AskUserQuestion`, 2 to 4 questions per call. Recommended option first, suffixed "(Recommandé)", with a description giving the consequence of each choice.
- **Open or structuring question** (the why, the end user, an idea to bring out) → a single question, in text, in this format:
  > **Question :** …
  > **Pourquoi ça compte :** … (what it concretely changes)
  > **Ma recommandation :** … (and the trade-off)

Rules during the rounds:
- **Louis's priority blind spots** (what made him lose time in the past): the why and the end user, the scope and what is out of scope, the definition of done, the technical constraints (accounts, API keys, costs, credits, imposed tools, data actually available). Never leave them 🟡 or ❌.
- **Vague words**: as soon as Louis says "simple", "rapide", "propre", "joli", "automatique", "comme X", "fini"… ask what it concretely means, with a measurable or checkable proposal.
- **"Je ne sais pas" / "fais comme tu penses"**: propose your default, mark it as an **assumption**, just ask "ok ?" and move on. Never ask the same question twice.
- **An answer changes everything?** Update the component list and the grid; some questions become irrelevant, don't come back to them.
- **One challenge turn**, only once, when the topic is framed: "Quelle est la version minimale qui te serait déjà utile ?" or "Et si on ne faisait pas X du tout ?". Mostly useful for big projects.
- **Recap every ~5 answers**: 2 to 4 bullets of what has been decided + the updated grid. Short, no wall of text.
- Louis can say **"stop"** at any time: the lines still open become explicit assumptions (your recommendations), which you list for him before writing the brief.

## Step 4 — Stop condition

Stop asking when **both** conditions are true:
1. Every line of the grid (common core + the module for the topic type) is ✅, or marked as an assumption validated by Louis.
2. Launcher test: "If I had to start now, is there a single place where I would have to guess?" Go through each component of the list. If yes → new round.

For a big project or a long interview (more than ~15 questions), draft the brief and have it reviewed by a fresh subagent (general-purpose) with the instruction: "List every place where someone executing this brief would have to guess." Sort its gaps: already answered (ignore), minor (decide yourself and note it in the brief), Louis's decision (one last round).

## Step 5 — Brief

Write the brief with the `brief-template.md` template (in this folder). Location:
- **Project with a code folder** (app, or task meant for `/dev`) → `<project folder>/_dev/BRIEF.md`. If one already exists, archive the old one as `_dev/briefs/YYYY-MM-DD-topic.md` before overwriting it.
- **Otherwise** (n8n, non-code deliverable, one-off task) → `_brain/[project]/briefs/YYYY-MM-DD-short-topic.md`.
- **Topic outside `_brain/`** → `_brain/[new-or-misc]/briefs/…` only if Louis wants it, otherwise in the working folder.

Then add a line to `_brain/[project]/CLAUDE.md` (ongoing tasks section, or at the end of the file): `- Brief <topic> (YYYY-MM-DD) → <path to the brief>`.

## Step 6 — Validation then launch

1. Show Louis a summary of the brief: goal in one sentence, what is in / out, definition of done, assumptions taken, and the link to the file.
2. Ask for explicit validation ("Je lance ?"). A "cool", "sympa" or an emoji is not a validation: ask again. If he corrects something, update the brief and show only what changed.
3. Once validated, launch (when the autopilot skill is running this task, follow its step 2 instead of this list):
   - **App / big coding project** → offer `/dev` (which will read `_dev/BRIEF.md` and skip its own clarification).
   - **n8n workflow** → follow `.agents/skills/n8n/SKILL.md` (pull, edit, validate, test). Always get Louis's approval before a real `n8ncli exec` or a publication.
   - **Anything else** → carry out the task directly, based on the brief.
   - If the conversation is already very long, offer to launch in a fresh conversation instead (`handoff` skill), with the brief as the entry point.

## Don'ts

- Asking something that is in `_brain/`, the code or the conversation.
- Asking a question without a recommendation.
- Sending a block of 8 questions, half of which depend on the first one.
- Coding, editing a workflow or producing the deliverable before the brief is validated.
- Stopping "by feel" while a grid line is still ❌.
- Keeping decisions only in the chat: everything ends up in the brief.
