---
name: hostile-review
description: Strict, severe, adversarial review of work that has just been finished (code, n8n workflow, document, deliverable) - several fresh reviewers attack it from different angles, every finding is verified before it counts, confirmed errors are fixed, improvements and suggestions go to Louis, with a verdict and a REVIEW.md. Runs after doubt-driven-dev finishes a task (and at the end of /dev before delivery), and when Louis types /hostile-review or says "hostile review", "revue hostile", "challenge ce travail".
---

# /hostile-review — Attack the finished work

The work is "done" according to its author (you, a /dev builder, doubt-driven-dev). This skill assumes it is **not**. Its job is to re-check the work strictly and severely, find the errors, the weak points and what could be better, and always challenge what was done.

Strict means a **high bar of proof**, not a long list. One proven bug beats ten vague remarks. "Nothing serious found" is an acceptable outcome, as long as it says what was checked.

**Language:** this skill is in English, but talk to Louis in French and write REVIEW.md in French.

Optional argument: what to review (a path, a folder, a commit range, a workflow name). Without one, review the work of the current task.

## Step 1 — Gather the contract and the artefact

- **Contract** (what the work was supposed to do): the brief (`_dev/BRIEF.md`, `_brain/[project]/briefs/…`), `_dev/SPEC.md` and the task in `_dev/TASKS.md`, or Louis's request as written. Add the project rules (`_brain/[project]/CLAUDE.md`, `ARCHITECTURE.md`, n8n rules). If no contract exists, write down in 3 to 6 lines what was asked, from the conversation, and use that.
- **Artefact** (what was produced): the diff since the start of the task (`git diff <start>..HEAD`, or the list of files changed), the n8n workflow files, the document, the deliverable.
- **Author's claims**: the "Prouvé" list from the final report (doubt-driven-dev), as **claims to re-check**, not as facts.
- **Do not pass** the author's reasoning, the conversation, or the doubt log's explanations to the reviewers: they must not share the author's blind spots.

## Step 2 — Hostile reviewers in parallel

Launch **4 fresh subagents (general-purpose) in parallel, in one message**, one per lens. Prompts and per-lens checklists (code and non-code variants): `lenses.md` in this folder.

| Lens | Attacks |
|---|---|
| **A. Conformité** | Every requirement of the contract really met? Anything missing, half done, or invented on top? Read as a demanding client / strict teacher: what would make them refuse it? |
| **B. Bugs et cas limites** | What breaks: empty / duplicate / huge inputs, API errors, pagination, timeouts, silent failures, untested branches. Pre-mortem: "it failed in production, why?" |
| **C. Sécurité et coûts** | Secrets, personal data, injection, access control, unwanted sends (emails, posts), calls that burn API credits or execution quota, things that could cost money or reputation. |
| **D. Simplicité et maintenabilité** | Over-engineering, dead code, a native node / built-in / maintained library ignored (allowed to search the web), readable in 6 months, project conventions respected. |

Small task (one file, a few lines, a short document)? Use the **light mode** below instead.

### Light mode (short tasks)

For a short task (autopilot `mode short`, or a change of a few files / a short document): **one** fresh subagent covers the 4 lenses at once (common prompt from `lenses.md` + the 4 checklists, at most 6 findings in total, lens A first). Then verify each BLOQUANT / MAJEUR yourself by reproducing it (no verifier subagents), fix the confirmed ones with the doubt-driven loop, re-run the full checks, and skip the re-review round. REVIEW.md is still written (short) and the verdict rules are the same. Never skip lens A, even in light mode.

Each reviewer is **read-only** (it may run tests, `n8ncli validate`, `n8ncli test`, builds, greps, but changes nothing, and never runs a real `n8ncli exec`, a send, a push or a deploy). Each returns at most **8 findings**, each with:
- **severity** (scale below), **lens**, **location** (file:line, n8n node name, document section),
- **failure scenario**: concrete input or situation → wrong result (mandatory for BLOQUANT and MAJEUR),
- **proof**: command run and its output, quoted line, requirement text it breaks,
- **fix** proposed in one or two lines.

## Severity scale

| Level | Meaning | What happens |
|---|---|---|
| **BLOQUANT** | Wrong, broken, data loss, security hole, or a requirement of the contract not met. | Must be fixed before delivery. Fixed automatically. |
| **MAJEUR** | Works in the nominal case but fails in a realistic case, or fails silently. | Fixed automatically before delivery. |
| **AMÉLIORATION** | Works, but clearly weaker than it should be: maintainability, clarity, performance, simpler existing brick, technical debt. | Proposed to Louis. |
| **SUGGESTION** | An idea that would add value beyond the contract (feature, UX, next step). | Proposed to Louis. |
| **INVÉRIFIABLE** | A suspicion that could not be proven. | Listed apart, never blocking. |

**Not reported at all:** pure style and nitpicks, what a linter / validator already catches, problems that existed before this work (unless the contract asked to fix them), hypothetical issues with no realistic scenario, vague wording ("pourrait être amélioré") with no concrete fix.

## Step 3 — Verify every finding

Reviewers make mistakes and invent problems. Nothing reaches Louis or gets fixed unverified.

1. **Deduplicate** across lenses (same root cause = one finding, keep the highest severity).
2. **BLOQUANT and MAJEUR**: launch **one verifier subagent per lens that produced any** (in parallel), given the artefact, the contract and those findings, with the instruction: "Essaie de réfuter chaque point. Reproduis le scénario d'échec (lance la commande, le test, lis le code). Réponds pour chacun : CONFIRMÉ (avec la preuve) ou RÉFUTÉ (avec la raison)." Then check the verifiers' evidence yourself.
3. **AMÉLIORATION and SUGGESTION**: verify them yourself (does the suggested library exist and fit? is the "simpler" version really equivalent?). Drop what doesn't hold.
4. Refuted findings are dropped but kept in one line in REVIEW.md (to show what was checked). A finding that can be neither confirmed nor refuted becomes **INVÉRIFIABLE**.

## Step 4 — Verdict

- **À LIVRER**: no confirmed BLOQUANT or MAJEUR.
- **À CORRIGER**: confirmed BLOQUANT / MAJEUR exist, the overall approach is sound → fix them (step 5).
- **À REVOIR**: the approach itself is wrong (wrong understanding of the need, wrong architecture, a much simpler existing solution makes most of the work pointless). **Do not rework on your own**: stop and present it to Louis with your recommendation.

## Step 5 — Fix the confirmed errors

For each confirmed BLOQUANT and MAJEUR, apply the doubt-driven loop (`~/.claude/skills/doubt-driven-dev/SKILL.md`, axis 1): write the check that reproduces the failure, see it FAIL, fix, see it PASS, then re-run the full checks (tests, build, `n8ncli validate` / `test`) to make sure nothing else broke.
- Accept a finding on evidence, not because a reviewer said so. If, while fixing, it turns out to be wrong, drop it and note why.
- Anything irreversible or costly needed to fix (real exec, send, push, deploy, paid service, data deletion) → ask Louis first.
- Don't touch AMÉLIORATION or SUGGESTION items: they are Louis's call.

## Step 6 — Re-review (bounded)

After the fixes, one **targeted** re-review: a fresh subagent gets the contract, the fix diff and the list of fixed findings, and checks (a) each one is really fixed, (b) the fixes didn't break anything nearby. New confirmed BLOQUANT / MAJEUR → fix and re-check once more.

**Max 2 fix → re-review rounds.** Stop earlier if a round finds nothing confirmed. If findings keep being mostly new each round, the reviewers are inventing: stop. Whatever is still open after round 2 goes to Louis.

## Step 7 — Report

Write `REVIEW.md` with the `review-template.md` template. Location (same rules as the doubt log):
- Project with `_dev/` → `_dev/REVIEW.md` (new dated section on top for each review).
- Otherwise, project in `_brain/` → `_brain/[project]/reviews/YYYY-MM-DD-topic.md`.
- Otherwise → `REVIEW.md` in the working folder.

Then, in the chat, short:
1. **Verdict** and one sentence why.
2. **Corrigé** : the confirmed errors fixed, one line each, with the check now PASS.
3. **À toi de choisir** : AMÉLIORATION and SUGGESTION items. Use `AskUserQuestion` (multiSelect) when there are clear options, recommended ones first, so Louis picks which to apply. Each option says the gain and the cost.
4. **Non vérifiable / encore ouvert**, if any.
5. Link to REVIEW.md.

Once Louis has chosen, apply the selected items with the doubt-driven loop, and update REVIEW.md.

## Don'ts

- Giving the reviewers the author's reasoning or conversation.
- Reporting or fixing a finding that was not verified.
- Inflating the list to look severe: no nitpicks, no vague remarks, max 8 per lens.
- Applying AMÉLIORATION / SUGGESTION items without Louis's choice.
- Reworking the whole approach on your own after an À REVOIR verdict.
- Endless fix → review loops (max 2 rounds).
- Saying "rien à signaler" without listing what was checked.
