# Evidence table

What counts as proof for each kind of claim. If the evidence in the right column is not in front of you, fresh, the claim is not proven.

## Code

| Claim | Evidence required |
|---|---|
| "The feature works" | A test that failed before the change and passes after, plus the real behaviour observed once (app launched, request sent, screen seen). |
| "The bug is fixed" | The original symptom reproduced first (FAIL), then gone after the fix (PASS), with the same reproduction steps. |
| "I didn't break anything" | The **whole** test suite + typecheck/lint + production build, exit code 0, full output read. |
| "X is the cause" | A prediction "if X is the cause, changing Y removes the bug", then the experiment confirming it. |
| "This API / library does X" | The installed version (lockfile) + the official docs for that version (URL cited), or a minimal call that shows it. |
| "This value can't be empty / this function is only called here" | A grep / search across the codebase, or a guard + test covering the case. |
| "The subagent / builder finished" | Its diff read, and its checks re-run by you. |
| "The regression test is real" | Red → green → revert the fix → red → green. |

## n8n workflows

| Claim | Evidence required |
|---|---|
| "The workflow is valid" | `n8ncli validate` exit 0. |
| "It produces the right output" | Expected output written **before** the test (JSON or field list), then `n8ncli test` with mock data, output compared. |
| "It handles errors" | A test with empty input and one with invalid input, each taking the expected branch. |
| "No item is lost" | Item count in and out of each key node, on the test run. |
| "It follows the rules" | Search the workflow file: no Code node, no credential or token in clear text, in the right folder (Projects/Sandbox). |
| "It works for real" | Only a real `n8ncli exec`, which costs credits → **ask Louis first**. Until then: NON VÉRIFIÉ. |

## Documents and other deliverables

Write the yes/no checklist **before** writing the deliverable, from the request / brief / grading scale. Typical lines:

| Claim | Evidence required |
|---|---|
| "Everything requested is covered" | One checklist line per requirement, each with the section / line that satisfies it. |
| "The figures are right" | Each figure has a source, and the source was opened and the figure found in it. |
| "It respects the format" | Word / page / slide count measured, required sections present, language and tone checked against the brief. |
| "It's finished" | No TODO, no placeholder, no "[…]" left (searched), links answer. |
| "It meets the expectation" | A fresh subagent given only the request and the deliverable answers PASS/FAIL per criterion. |
