#!/usr/bin/env bash
# Non-destructive project snapshots for safe experiments.
# Works on macOS, Linux and Windows (Git Bash). Needs only git.
#   checkpoint.sh save NAME | list | diff NAME | restore NAME [--yes] | drop NAME
set -euo pipefail

REF=refs/codex-checkpoints
cmd="${1:-help}"; name="${2:-}"; yes="${3:-}"

git rev-parse --show-toplevel >/dev/null 2>&1 || { echo "Not a git repo. Run 'git init' first." >&2; exit 1; }
cd "$(git rev-parse --show-toplevel)"

valid_name() { [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "Bad name '$1' (use letters, digits, . _ -)" >&2; exit 1; }; }

# Prints the sha of a commit holding the full working tree (tracked + untracked, minus ignored).
# Does not touch HEAD, branches, the real index or the working tree.
snapshot() {
  local d tree parent=() sha
  d="$(mktemp -d)"
  export GIT_INDEX_FILE="$d/index"
  if git rev-parse -q --verify HEAD >/dev/null; then git read-tree HEAD; parent=(-p HEAD); fi
  git add -A
  tree="$(git write-tree)"
  if [ -z "$(git config user.name || true)" ]; then export GIT_AUTHOR_NAME=codex-checkpoint GIT_COMMITTER_NAME=codex-checkpoint; fi
  if [ -z "$(git config user.email || true)" ]; then export GIT_AUTHOR_EMAIL=checkpoint@localhost GIT_COMMITTER_EMAIL=checkpoint@localhost; fi
  sha="$(git commit-tree "$tree" ${parent[@]+"${parent[@]}"} -m "codex checkpoint: $1")"
  unset GIT_INDEX_FILE
  rm -rf "$d"
  echo "$sha"
}

case "$cmd" in
  save)
    valid_name "$name"
    sha="$(snapshot "$name")"
    git update-ref "$REF/$name" "$sha"
    echo "Saved checkpoint '$name' ($(git rev-parse --short "$sha"))."
    ;;
  list)
    git for-each-ref --format='%(refname:strip=2)  %(objectname:short)  %(creatordate:iso)' "$REF" || true
    ;;
  diff)
    valid_name "$name"
    snap="$(git rev-parse -q --verify "$REF/$name")" || { echo "No checkpoint '$name'." >&2; exit 1; }
    now="$(snapshot "diff-now")"
    git diff --stat --no-renames "$snap" "$now" | tail -n 40
    ;;
  restore)
    valid_name "$name"
    snap="$(git rev-parse -q --verify "$REF/$name")" || { echo "No checkpoint '$name'." >&2; exit 1; }
    now="$(snapshot "before-restore-$name")"
    backup="$name-before-restore-$(date +%Y%m%d-%H%M%S)"
    git update-ref "$REF/$backup" "$now"
    echo "Current state saved as '$backup' (restore it to undo this restore)."
    echo "Changes that will be reverted (checkpoint -> now is shown reversed):"
    git diff --stat --no-renames "$now" "$snap" | tail -n 40
    if [ "$yes" != "--yes" ]; then
      read -r -p "Restore working tree to '$name'? [y/N] " a
      [ "$a" = "y" ] || { echo "Cancelled. Nothing changed."; exit 0; }
    fi
    while IFS= read -r -d '' st && IFS= read -r -d '' f; do
      case "$st" in
        A) rm -f -- "$f" ;;                              # created after the checkpoint
        *) git restore --source="$snap" --worktree -- "$f" ;;  # modified or deleted since
      esac
    done < <(git diff --no-renames --name-status -z "$snap" "$now")
    echo "Restored to '$name'. Staged state was not changed; check 'git status'."
    ;;
  drop)
    valid_name "$name"
    git update-ref -d "$REF/$name" && echo "Dropped '$name'."
    ;;
  *)
    sed -n '2,5p' "$0"
    ;;
esac
