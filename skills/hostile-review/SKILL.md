---
name: hostile-review
description: Adversarial review of finished work (code, n8n workflow, document) by fresh reviewers; findings verified, confirmed errors fixed, improvements left to Louis, verdict + REVIEW.md. Runs after doubt-driven-dev and at the end of /dev; also on /hostile-review, "revue hostile", "challenge ce travail".
---

# /hostile-review — Attack the finished work

Its author says it's done; assume it isn't. Strict = a **high bar of proof**, not a long list: one proven bug beats ten vague remarks, and "nothing serious" is fine if it says what was checked. Talk to Louis and write REVIEW.md in French. Optional argument: what to review; default = the current task's work.

## Step 1 — Contract and artefact

- **Contract**: the brief (`_dev/BRIEF.md`, `_brain/[project]/briefs/…`), `_dev/SPEC.md` / `TASKS.md`, or Louis's request; plus project rules (`CLAUDE.md`, `ARCHITECTURE.md`, n8n rules). None → write what was asked in 3-6 lines.
- **Artefact**: the task's diff (`git diff <start>..HEAD` or changed files), n8n workflow files, the document.
- **Author's claims**: the "Prouvé" list, as claims to re-check.
- Never pass the author's reasoning, conversation or doubt log to reviewers.

## Step 2 — Fresh reviewers

Every `Agent` call passes an explicit `model`. Launch in the background, end your turn, wait for notifications; never poll.

Lenses: **A. Conformité** (each requirement met, nothing missing or invented), **B. Bugs et cas limites**, **C. Sécurité et coûts** (secrets, data, unwanted sends, credits burnt), **D. Simplicité** (over-engineering, ignored existing brick). Prompts: `lenses.md` (common prompt: read-only, finding format, what not to report; per-lens checklists, code / non-code).

- **Level 4 (full)**: 4 subagents in one message, one per lens: `model: "sonnet"` for A, B, D, `"opus"` for C. Max 8 findings each.
- **Level 3 (light)**: **one** subagent (`model: "sonnet"`) with the common prompt + the 4 checklists, max 6 findings, lens A first (never skipped). You verify BLOQUANT / MAJEUR yourself by reproducing them (no verifier subagents), fix, re-run the full checks, no re-review round. Short REVIEW.md, same verdict rules.

Severities: **BLOQUANT** (wrong, broken, data loss, security hole, contract requirement not met) and **MAJEUR** (a realistic case fails, or fails silently) → fixed automatically; **AMÉLIORATION** (works but clearly weaker than it should be) and **SUGGESTION** (value beyond the contract) → Louis decides; **INVÉRIFIABLE** (not proven) → listed apart, never blocking.

## Step 3 — Verify every finding

1. Deduplicate (same root cause = one, highest severity).
2. BLOQUANT / MAJEUR (full mode): one verifier subagent (`model: "sonnet"`) per lens that produced any, in parallel: « Essaie de réfuter chaque point. Reproduis le scénario d'échec. Réponds CONFIRMÉ (preuve) ou RÉFUTÉ (raison). » Check their evidence yourself.
3. AMÉLIORATION / SUGGESTION: verify yourself (does the library exist and fit? is "simpler" really equivalent?).
4. Refuted → dropped, one line in REVIEW.md. Neither confirmed nor refuted → INVÉRIFIABLE.

## Step 4 — Verdict

**À LIVRER**: no confirmed BLOQUANT / MAJEUR. **À CORRIGER**: some, approach sound → step 5. **À REVOIR**: the approach itself is wrong (need misread, wrong architecture, a much simpler existing solution) → don't rework alone, present it to Louis with a recommendation.

## Step 5 — Fix and re-review

- Each confirmed BLOQUANT / MAJEUR: doubt-driven loop (check that reproduces it, FAIL, fix, PASS), then the full checks. Drop a finding that turns out wrong (say why). Irreversible or costly fix → ask Louis. Don't touch AMÉLIORATION / SUGGESTION.
- Full mode: one targeted re-review by a fresh subagent (`model: "sonnet"`) with the contract, the fix diff and the fixed list: really fixed? nothing broken nearby? **Max 2 fix → re-review rounds**; stop earlier if nothing new is confirmed, or if findings are mostly new each round (reviewers inventing). Still open after that → Louis.

## Step 6 — Report

`REVIEW.md` from `review-template.md`: `_dev/REVIEW.md` (new dated section on top), else `_brain/[project]/reviews/YYYY-MM-DD-topic.md`, else `REVIEW.md` in the working folder. In the chat, short: **verdict** + why · **Corrigé** (one line each, check now PASS) · **À toi de choisir** (AMÉLIORATION / SUGGESTION via `AskUserQuestion` multiSelect, recommended first, gain and cost each) · **Non vérifiable / ouvert** · link to REVIEW.md. Apply what Louis picks with the doubt-driven loop, update REVIEW.md.
