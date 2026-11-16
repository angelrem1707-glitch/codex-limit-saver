# Sessions: when to compact, when to start fresh

## Why
A long thread is re-read on every turn. A fresh session starts with only AGENTS.md + skill catalog. Measured on a real workload (Claude Code, same mechanics): keeping context under ~350k tokens cut the median call context from 311k to 219k and total usage noticeably; fresh-session start was ~100k lower than a bloated one.

## Decision table
| Situation | Action |
|---|---|
| New, unrelated task | `/new` |
| Same task, a step just finished, context > ~50 % of window | handoff, then `/new` (or `/compact` if the next step needs the exact wording of earlier turns) |
| Mid-edit, tests failing | finish/stabilize first, then decide |
| Two failed attempts on the same problem | stop, write hypothesis, `/new` with the handoff |
| Need a detail from an old thread | open the old thread read-only, copy the 3-5 relevant lines into the handoff, do not resume it |
| Task is a big investigation (lots of reading) | do it in a separate session, bring back only a summary file |

`/compact` summaries are lossy: paths, exact error text and decisions can vanish. Anything important goes to the handoff file, not into hope.

## Handoff procedure
1. Facts from the tree, not memory: `git status --short | head -n 40`, last test result, running processes.
2. Insert a section at the TOP of `PROGRESS.md` (newest first), about 15 lines, no pasted logs, no secrets:
   see `templates/PROGRESS.template.md`.
3. A decision with its reason (one paragraph) goes to `DECISIONS.md`.
4. End the reply with the prompt for the next session:
   `Read the top section of PROGRESS.md and continue from "Next step". Do not read older sections.`
5. Stop. Do not keep working in the old session.

## Starting from a handoff
Read only the top section. Verify the "Done" claims cheaply (`git status`, one test command) before building on them.
