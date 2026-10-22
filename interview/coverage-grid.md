# Coverage grid

Each line is ✅ clear, 🟡 partial or ❌ missing. The common core always applies; add the module matching the topic type (several if the topic is mixed, e.g. an app that calls an n8n workflow).

Lines marked ★ are Louis's usual blind spots: never leave them open.

## Common core

| Line | The question behind it |
|---|---|
| ★ Why | What problem are we solving, what happens if we don't do it? |
| ★ For whom | Who uses / reads / receives the result? Louis himself, a Capsule client, a teacher, a Shiseido team? |
| ★ In scope | The precise list of what we do. |
| ★ Out of scope | What we don't do this time (and maybe later). |
| ★ Definition of done | How we concretely check that it is finished and that it works (testable, observable). |
| ★ Technical constraints | Accounts, API keys, costs and credits, imposed tools, access, data actually available. |
| Deadline | By when, and are there intermediate milestones? |
| Existing | What we reuse (code, workflow, doc, template) and what we must not break. |
| Vocabulary | Terms that could be understood two ways. |
| Risks / unknowns | What could make the project fail, what must be checked first. |

## App / code module

| Line | The question behind it |
|---|---|
| Platform | Web, mobile (iOS/Android), desktop, extension? Responsive? |
| Stack | Imposed, already in place, or free (then /dev's architect proposes one)? |
| Main flow | The 1 to 3 essential user flows, step by step. |
| Data | What data, where it comes from, where it is stored, who can see it? |
| Accounts / login | Are users, roles, authentication needed? |
| Going live | Local only, deployed (where), published on a store? |
| Edge cases | Offline, API errors, empty data, large volumes. |

## n8n workflow module

| Line | The question behind it |
|---|---|
| Trigger | Scheduled (frequency), webhook, manual, form, email? |
| Sources | Which APIs / apps as input, credentials already in n8n or to be created? |
| Cost per run | Credits consumed (ScrapeCreators, AI…), production execution quota. |
| Outputs | Where the result goes (email, Sheets, Slack, database…) and in exactly what form? |
| Volume | How many items per run, how many runs per day? |
| Errors | What happens when an API fails or returns nothing? Who gets notified? |
| Rules | No Code node (native nodes + expressions); Projects/Sandbox folders. |
| Testing | Can it be tested with mock data (`n8ncli test`)? When is a real exec needed? |

## Non-code deliverable module (doc, strategy, case study, Shiseido assignment, Capsule business)

| Line | The question behind it |
|---|---|
| Reader | Who reads it, what is their level, what do they need to be convinced? |
| Format | Doc, slides, spreadsheet, email, page? Length? |
| Tone | Formal, educational, sales, internal? Language? |
| Sources | What do we rely on, what is confidential? |
| Key message | The one sentence the reader must remember. |
| Evaluation | How the deliverable will be judged (grading scale, expected decision, manager approval)? |

## School project module

| Line | The question behind it |
|---|---|
| Instructions | The exact text of the instructions, the mandatory elements. |
| Grading | What earns points. |
| Level | Must the code / deliverable stay at Louis's level (explainable orally)? |
| Imposed tools | Technologies, platforms, course rules. |
| Submission | Date, format, oral or not, group work (who does what)? |
