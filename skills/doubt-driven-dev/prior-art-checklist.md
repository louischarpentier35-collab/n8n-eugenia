# Prior-art checklist

Used for axis 2 ("is it the best way?"). Answer each line yes/no, with the proof (command output, registry page, docs URL). Compare 2 to 3 candidates max, then decide.

## 1. Is it already there? (stop at the first yes)

- [ ] The project already does this somewhere (search the code: `rg`, Grep) → **reuse**.
- [ ] An installed dependency already covers it (check `package.json` / lockfile / `requirements.txt` and that library's docs) → **reuse**.
- [ ] A native n8n node, an n8n template, a framework built-in, an installed MCP server or skill, or a feature of a service already in use covers it → **reuse / adopt**.

## 2. Candidate brick (library, service, template)

A candidate must answer **yes** to every line marked ●, or be rejected. Lines marked ○ are tie-breakers.

| | Question | How to check |
|---|---|---|
| ● | It exists on the official registry under this **exact** name (not hallucinated, not a typosquat of a popular name). | `npm view <name>` / `pip index versions <name>` / registry page; compare spelling with the well-known package. |
| ● | It is maintained: last release less than ~18 months ago, issues get answers. | Registry page, GitHub releases. |
| ● | Licence is permissive (MIT, Apache-2.0, BSD, ISC). GPL/AGPL → ask Louis. | Registry page / LICENSE file. |
| ● | No known critical vulnerability. | `npm audit` / `pip-audit` after a dry install, or the GitHub security tab. |
| ● | Compatible with the project's stack and versions (runtime, framework version, Expo/React Native, n8n version). | Docs for the installed versions, peer dependencies. |
| ● | Free, or already paid for. Otherwise → **ask Louis** (cost, account, API key). | Pricing page. |
| ● | No data sent to a new third party. Otherwise → **ask Louis**. | Docs. |
| ○ | Usable as-is or behind a thin wrapper (< ~50 lines). | Docs examples vs our need. |
| ○ | Light: few transitive dependencies (< ~20 for a small utility), size proportionate to the need. | `npm view <name> dependencies`, bundlephobia. |
| ○ | Widely used (downloads, stars) and well documented. | Registry, GitHub. |
| ○ | Easy to replace later (no lock-in). | Our code only touches it through one place. |

## 3. Decision (log it)

- **Reuse** / **Adopt** / **Build**, with one line per rejected option and why.
- If **Build**: write the gap ("aucune brique ne gère X sans Y").
- Cite the docs URL used for the version actually installed.

## Over-engineering / reinvention signals (yes = red flag)

- [ ] A generic utility written by hand while a dependency or built-in does it.
- [ ] An abstraction, factory or interface with a single implementation.
- [ ] Code with no caller today ("au cas où").
- [ ] A wrapper that only forwards calls.
- [ ] A function over ~50 lines, nesting 3+ levels, 5+ duplicated lines.
- [ ] More code than the official docs example for the same thing.
- [ ] n8n: several nodes rebuilding what one native node or a template does.
- [ ] Repeated API calls that cost credits where one call or a cache would do.
