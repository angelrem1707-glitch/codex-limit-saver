# Weak laptop (Windows) and MacBook M5

Two people, two machines. The token rules are identical; hardware rules differ.

## Windows, weak laptop (RAM <= 8-16 GB, HDD or slow SSD)
- **One heavy process at a time.** Do not run dev server + full tests + build + browser tabs together. Ask before starting a second heavy job.
- **Narrow checks:** run one test file or one package (`pytest path::test`, `npm test -- <file>`), type-check only changed files if the tool supports it. Full suite once, at the end, in quiet mode.
- **Search:** use `rg` (ripgrep), not recursive `findstr`/`Get-ChildItem -Recurse` over big trees. Add `.ignore` (templates/dot-ignore.txt). Ripgrep respects `.gitignore` too.
- **Where the repo lives:** a local folder (e.g. `C:\dev\...`), not OneDrive/Dropbox/network drive: sync and file locking make git and watchers slow and flaky.
- **Shell:** pick one and stay on it. Native PowerShell is fine; WSL2 reserves RAM (limit it in `%UserProfile%\.wslconfig`: `memory=4GB` for 8 GB machines) and is slow on files under `C:\`. Git for Windows ships Git Bash, which runs this skill's `.sh` scripts.
- **Antivirus:** real-time scanning of `node_modules` / build folders slows everything. Excluding the project folder is a security setting: decide it consciously, do not let an agent change it.
- **No local LLMs, no heavy media/3D jobs** on this machine. Use the hosted model; spend effort on shrinking context instead.
- **Watchers/IDE:** close unused IDE windows, disable file watchers on huge folders, keep only the extensions you use.
- **Disk:** keep >= 15 % free; clear package caches and build outputs when low.
- **Long outputs on Windows:** console encoding can break non-ASCII text; for scripts that print Russian text, set UTF-8 (`$OutputEncoding`, `chcp 65001`) and write to a file instead of dumping.
- **Line endings:** set `git config core.autocrlf true` (Windows) to avoid whole-file diffs that waste tokens when the agent reads `git diff`.

## MacBook M5 (Apple Silicon, plenty of RAM)
- Same token rules; hardware is not the bottleneck, limits are.
- Can run the full test suite more often and a local formatter/linter freely.
- Local LLMs (Ollama/MLX) are possible but are a separate project: they only pay off as an input compressor for big logs/pages, and they compete with the project for RAM. Do not enable them by default.
- Swap/SSD wear: avoid running several big models or builds at once; check memory pressure in Activity Monitor before heavy jobs.

## Both
- Keep `AGENTS.md` short; keep repo-specific commands (how to run one test, how to lint) in it so the agent does not search for them.
- Commit small and often on a branch: cheap rollback and small diffs to read.
