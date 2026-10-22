---
name: autopilot
description: Chain for level 3 (medium task) and level 4 (real project) requests - Claude chooses the chain on its own (interview if unclear, else a 3-line mirror and a go; then doubt-driven-dev, /dev for multi-component code, hostile-review), tracks the task state so long tasks run for hours unattended, notifies Louis when it needs him, and updates the Autopilot dashboard. Use it for level 3-4 work, or when the [autopilot] context says a task is active. Not for a question (level 1) nor a small localized change (level 2).
---

# Autopilot — Louis never picks a skill

Louis describes what he wants; you pick and chain everything, spending tokens in proportion to the level. The only things that stop on him are: the interview questions (when his request is unclear), his "go" on the brief, decisions that are costly / irreversible, and the improvements he chooses at the end. Everything else runs on its own, possibly for hours.

**Language:** this skill is in English; talk to Louis in French.

**Tools of this skill** (no spaces in these paths):
- State: `python3 ~/.claude/skills/autopilot/scripts/state.py <cmd> --session <SID> …` — run it with no command to see the list. `<SID>` is the `session_id` given in the `[autopilot]` context of the latest message.
- The state file is what the Stop hook reads: in phases `building` and `reviewing`, you cannot end your turn until a hostile-review verdict is recorded (or the task waits on Louis).
- Dashboard: see "Dashboard" below.

## Step 0 — Triage (every message)

Every answer starts with one line: **« Niveau N — <ce que tu fais> »**. The level sets how much process (and how many tokens) the request gets. The `[autopilot]` hook brings you here only for levels 3 and 4; levels 1 and 2 never load this skill.

| Level | Message | What you do |
|---|---|---|
| **1** | Question, discussion, quick look | Answer directly. No skill, no state. |
| **2** | Small clear task: one localized change (one file, one n8n node, one function, a short text) | Do it yourself with the binary checks of doubt-driven-dev in mind (run the check, read the output), no `DOUBTS.md`, no web search, no subagent, no state, no reviewer: a short self-check before handing over. |
| **3** | Medium task: several files or steps, or a choice to make, on something existing | Steps 1 → 4 with `--level 3`: 3-line mirror + go (interview only if unclear), doubt-driven-dev in full, hostile-review **light mode** (one Sonnet reviewer). State + dashboard. |
| **4** | Real project: plan, architecture, new app / tool / workflow, redesign, 3+ components, something Louis or a client relies on | Steps 1 → 4 with `--level 4`: interview, brief, go, doubt-driven-dev or /dev, full hostile-review. State + dashboard. Tell Louis in one line that switching this conversation to Opus is recommended (model picker); never block on it. |

- **In doubt, the lower level.** Louis writing « niveau N » forces it; « projet », « /dev », « interview » mean level 4.
- **Scope decides, not time**: you work fast, so "how long would it take me" says nothing.
- A task that turns out bigger than its level: say so in one line (« Je passe en niveau 3 : … ») and switch.
- Unclear small task: ask the 1 to 3 questions you need (with recommendations), stay at its level.
- Answer to a pending question, "stop", "pause", "reprends" for the active task → Resume section first.

## Step 1 — Clarify (levels 3-4)

1. `state.py init --session <SID> --title "<short title>" --project <project folder> --level <3|4>` (phase `interview`). If the project is in `_brain/`, read its `CLAUDE.md` first (global rule).
2. Is the request clear? It is clear only if you can state, from the request and what you can look up, the **goal, the scope (in and out) and a checkable definition of done**.
   - **Not clear** → run the interview: read and follow `~/.claude/skills/interview/SKILL.md` from its step 1. Its brief is the contract.
   - **Clear** → silent exploration (interview step 1), then a **3-line mirror** to Louis (goal / in-out / definition of done) and write the brief with `~/.claude/skills/interview/brief-template.md` (decisions mostly marked as yours, "hypothèse").
3. `state.py set --session <SID> brief <path>` then `state.py phase --session <SID> awaiting_go`.
4. Ask for the go: "Je lance ?". Before that, check the `[autopilot]` context: if it says the permission mode isn't auto, remind Louis in one line to switch the session to auto mode, since the task will run without him. Never change it yourself.
5. Update the dashboard, then **end your turn**. Louis's initial request is never the go, however detailed or "en autonomie" it is: the go is his next message. `state.py phase … building` refuses until he has written again.

## Step 2 — Go → build (levels 3-4)

Only an explicit go ("go", "lance", "oui vas-y"…) counts; "cool", "ok noté" or an emoji does not.

1. `state.py phase --session <SID> building`. Choose the mode and record it: `state.py set --session <SID> mode dev|direct`.
   - **dev**: a code project with several components (an app, a feature spanning front + back + data). Follow `~/.claude/skills/dev/SKILL.md` with the brief (it skips its own clarification). **Autopilot override**: /dev's validations of SPEC and ARCHITECTURE do not wait for Louis — present each one to him as a question with `state.py ask` + push notification, and go on; if he later disagrees, adjust.
   - **direct**: everything else (n8n workflow, document, script, config, single-component change). Work yourself in doubt-driven-dev mode (`~/.claude/skills/doubt-driven-dev/SKILL.md`): doubt log, binary checks, search before building.
2. Ask the desktop app to keep the Mac awake for the task if that tool is available (`request_keep_awake`).
3. Update the dashboard. Then work. Long silences are normal; the Stop hook brings you back once if you try to stop early.
4. **Background work** (reviewer subagents, long commands, n8n executions): once launched, end your turn; the completion notification wakes you up. Never poll or loop on a status check (the Stop hook lets you stop while background jobs run).

**During the build**
- **A decision only Louis can take** (not settled by the brief, not reversible, or costly): `state.py ask --session <SID> "<question + ta recommandation>"`, send a push notification (`PushNotification`, one line: what you need and your recommendation), update the dashboard, and **continue everything that doesn't depend on it**. If you take a reversible default meanwhile, say so in the question.
- **Everything left depends on Louis**: `state.py wait --session <SID> --reason "<what>"`, push notification, dashboard. Then you may stop.
- Costly / irreversible actions (real `n8ncli exec`, sending, push, deploy, paid service, data deletion) are always questions, never done unattended.
- Context compaction: the `[autopilot]` context is re-injected after compaction; re-read the brief and the doubt log, and `state.py show` to know where you are.

## Step 3 — Hostile review

When doubt-driven-dev's final gate passes (or /dev reaches its phase 3 review):
1. `state.py phase --session <SID> reviewing`, dashboard.
2. Run `~/.claude/skills/hostile-review/SKILL.md` on the work, with the brief as the contract: **light mode at level 3**, full at level 4. It fixes the confirmed BLOQUANT / MAJEUR items itself.
3. Record the final verdict: `state.py verdict --session <SID> "<À LIVRER|À CORRIGER|À REVOIR>" --review <REVIEW.md path>`. It is refused if no reviewer subagent ran in this session: reviewing your own work is not a hostile review, in light mode too.
   - **À REVOIR** (the approach itself is wrong) → `state.py wait … --reason "Revue hostile : approche à revoir"`, push notification with the one-line reason, stop.
   - Otherwise → `state.py finish --session <SID>`.

## Step 4 — Hand over

1. Push notification: "<titre> : terminé, verdict <X>, <n> amélioration(s) à choisir" (only if Louis may be away: long task).
2. Dashboard.
3. In the chat, short (French): what was done, the verdict, the proven / not proven list (doubt-driven-dev final report), then hostile-review's "À toi de choisir" via `AskUserQuestion`. Applying what he picks happens in doubt-driven-dev mode; it doesn't reopen the task unless he asks for more work.

## Resume (Louis writes while a task is active)

- **He answers a pending question** → `state.py answer --session <SID> Q<n> "<answer>"`, then `state.py resume` if the task was waiting, apply the answer, continue.
- **"stop" / "pause"** → `state.py phase --session <SID> paused`, dashboard, confirm in one line. **"reprends"** → `state.py resume`.
- **A new, unrelated long task in the same session** → finish or pause the current one first (one active task per session; parallel tasks go in separate sessions).
- **Phase `stalled`** (the Stop hook gave up after several stops with no progress) → tell Louis what blocked you, ask how to proceed.

## Dashboard

URL: in `~/.claude/autopilot/config.json` (`dashboard_url`). Every `state.py` change rewrites `~/.claude/autopilot/dashboard.json`. To publish it (after each phase change, question, verdict, finish — not after every small step):
1. `Artifact` publish with `url` = dashboard_url, `file_path` = `~/.claude/autopilot/dashboard.json` (absolute path), `asset: true`. Note the returned `url` (`/_blob/<id>`) and id.
2. `ArtifactData` `update` on the same artifact, collection `datasets`, doc `tasks`: `{"source": {"kind": "file", "url": "<returned url>", "name": "dashboard.json", "format": "json"}, "updated": {"at": "<ISO now>", "by": "Claude (autopilot)"}}`.
3. `state.py dashboard-asset <new id>`: it prints the previous asset id, which you then delete (`Artifact` delete with `url` and `path` = that id).
If the dashboard is unreachable (no URL, tool missing, refused), skip it and say so once; it never blocks the task.

## Don'ts

- Asking Louis which skill, mode or tool to use.
- Starting to build before an explicit go.
- Ending a long task's turn while building / reviewing without a verdict or a `wait` (the hook will block you anyway).
- Using `wait` to escape work that doesn't depend on Louis.
- Touching another session's state file.
- Changing permission modes, security settings, or doing a costly / irreversible action unattended.
