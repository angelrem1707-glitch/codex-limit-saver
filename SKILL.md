---
name: codex-limit-saver
description: Save Codex usage limits and keep a weak laptop responsive. Use at the start of any non-trivial task, when the context grows (about half the window), when a task changes, after two failed attempts, before changing Codex config/AGENTS.md/skills, and before risky edits that may need a rollback.
---

# codex-limit-saver

Every token in the context is re-read on every later turn, so cost grows with context size, not only with output. Goal: more finished tasks per limit, without losing quality. Reply in the user's language.

## 1. Sessions (biggest lever)
- **One task = one session.** Task changed -> `/new`. Do not keep "while we are here" work in a long thread.
- `/compact` only at a natural boundary (a step is finished and verified), never in the middle of an edit. If the next task is unrelated, prefer `/new` over `/compact`.
- Hand off instead of dragging history: at about half of the context window (see `/status`), on a task change, or before stopping, write a handoff (see `references/sessions.md`, template `templates/PROGRESS.template.md`) and continue in a fresh session that reads only that section.
- Avoid resuming or forking a long old thread: it re-reads the whole history. Fresh session + handoff is cheaper.
- Finish the current step first; never hand off mid-edit.

## 2. Keep tool output small
- Count before dumping: `wc -l`; then `head -n 80`, `tail -n 80`, `rg -m 20`, `--quiet`. PowerShell: `Select-Object -First 80`, `Select-String -List`.
- Search first (`rg`, file search), then read only the needed line range. Do not re-read a file already in context unless it changed.
- Never print whole logs, JSON/CSV/XLSX, HTML, lockfiles, minified or generated files; filter or summarize with a script and read the summary.
- Tests/builds: run the narrow target with quiet flags and show only failures (first ~40 lines), not the full run.
- Prefer text over screenshots when text answers the question.
- Never print or store secrets (keys, tokens, cookies) in logs, docs or commits.

## 3. Small static context
- Global/project `AGENTS.md`: short, imperative, under ~1.5k tokens. Move long rules into skills' `references/` (loaded on demand).
- Turn off MCP servers, plugins and skills that are not used in this project: their descriptions and tool schemas are sent every turn. Check with `/mcp`, `/status`.
- Add a `.ignore` (see `templates/dot-ignore.txt`) so `rg` skips `node_modules`, build output, dumps.

## 4. Model, effort, helpers
- Default effort `medium`. `low` for mechanical edits and lookups; `high` only for hard debugging or design, then switch back.
- Do not spawn sub-agents for small work: each has its own context and multiplies cost. If used, give a narrow brief and a cheaper model.
- Deterministic work (parsing, arithmetic, diffs, format checks): write and run a short script instead of reasoning in text.

## 5. Prompting discipline
- State: goal, files/paths, acceptance check (a command that must pass). One task per prompt.
- **Two failed attempts -> stop.** Write the hypothesis in 3 lines, then change the approach or start a fresh session. No "try again" loops: each retry re-reads everything.
- Batch related edits into one turn instead of many tiny turns.

## 6. Weak hardware
Rules for a slow Windows laptop (and what a MacBook M5 can relax) are in `references/weak-hardware.md`. Core: run narrow tests, one heavy process at a time, no local LLMs on weak machines, `rg` instead of slow recursive search, keep repos out of cloud-sync folders.

## 7. Experiments must be reversible
Before changing `~/.codex/config.toml`, `AGENTS.md`, skills, or doing a risky refactor:
1. Snapshot: `bash <skill-dir>/scripts/checkpoint.sh save <name>` (non-destructive, covers untracked files). Config files are backed up by `scripts/install.sh`.
2. Change **one thing at a time**; log it in `EXPERIMENTS.md` (`templates/EXPERIMENTS.template.md`): date, change, metric, result.
3. Metric: finished tasks per limit % and context size at task end (`/status`), compared over a few comparable tasks, not one.
4. Worse or unclear -> `checkpoint.sh restore <name>` (it snapshots the current state first, so the restore itself is undoable) or `install.sh uninstall`.
Details: `references/experiments-rollback.md`.

## Done criteria
Say what was verified and what was not. Do not claim a saving without a before/after number.
