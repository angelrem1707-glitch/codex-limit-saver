# Experiments and rollback

Principle: every change is one step, logged, measured, and reversible.

## What can be rolled back, and how
| Change | Backup | Rollback |
|---|---|---|
| `~/.codex/config.toml`, `~/.codex/AGENTS.md`, the skill itself | `scripts/install.sh` copies originals to `~/.codex/backups/codex-limit-saver-<timestamp>/` (and remembers if a file did not exist) | `bash scripts/install.sh uninstall` (removes only our marked blocks and the skill), or `restore <backup-dir>` (puts the saved originals back) |
| Project files (code, docs, project AGENTS.md) | `scripts/checkpoint.sh save <name>`: snapshot commit under `refs/codex-checkpoints/`, includes untracked files, does not touch branches, index or working tree | `checkpoint.sh restore <name>`: first snapshots the current state as `<name>-before-restore-<time>`, shows a summary, asks, then restores files and deletes files created since |
| Commits you made after the checkpoint | normal git | `git revert` (shared branch) or `git reset` to the checkpoint's parent (own branch) after saving a checkpoint |

Checkpoints are local refs: they are not pushed, not shown in `git log`, but kept by git (do not run `git gc --prune=now` right after). `checkpoint.sh drop <name>` removes one. Ignored files (`.gitignore`, e.g. `.env`, `node_modules`) are neither saved nor deleted.

## Experiment loop
1. `checkpoint.sh save exp-<short-name>`.
2. Write the hypothesis in `EXPERIMENTS.md` (template): "turning off MCP X will cut start-of-session context by ~N tokens".
3. Make **one** change.
4. Measure on 3+ comparable tasks: context at session start and at end (`/status`), turns per task, failures/retries. One run proves nothing.
5. Decide: keep (log it) or revert (`restore`/`uninstall`), and log why.

## Safe order of experiments (most value, least risk first)
1. Session rules (free, no config).
2. Output limits (`tool_output_token_limit`) and `.ignore`.
3. Disable unused MCP servers/plugins/skills.
4. Shorten AGENTS.md.
5. Auto-compaction threshold (`model_auto_compact_token_limit`, about 40 % of the window from `/status`): can drop details, so test on a non-critical task first.
6. Effort/model changes.

## Verifying config after a change
Start `codex` in a scratch folder. A TOML error is printed at startup; if so, run `install.sh uninstall` (or restore) immediately. Check `/status` for the effective values.

## Never
- Delete the backup directory before a week of normal use.
- Edit global config and project files in the same step.
- Hand the agent an uncommitted dirty tree and no checkpoint.
