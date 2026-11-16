#!/usr/bin/env bash
# Install / remove codex-limit-saver. macOS, Linux, Windows (Git Bash).
#   install.sh install [--dry-run] [--compact-limit N]
#   install.sh uninstall
#   install.sh restore BACKUP_DIR
#   install.sh status
# Everything we add sits between markers, so uninstall removes exactly that.
# Originals are copied to $CODEX_HOME/backups/codex-limit-saver-<time>/ first.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
SKILLS="$HOME/.agents/skills"
DEST="$SKILLS/codex-limit-saver"
CFG="$CODEX_HOME/config.toml"
AGENTS="$CODEX_HOME/AGENTS.md"
A_BEGIN='<!-- codex-limit-saver:begin -->'; A_END='<!-- codex-limit-saver:end -->'
C_BEGIN='# >>> codex-limit-saver >>>';      C_END='# <<< codex-limit-saver <<<'

cmd="${1:-status}"; shift || true
dry=0; compact=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) dry=1 ;;
    --compact-limit) compact="${2:-}"; shift ;;
    *) ARG="$1" ;;
  esac; shift
done

strip_block() { # file begin end -> stdout without the block
  awk -v b="$2" -v e="$3" '$0==b{s=1} !s{print} $0==e{s=0}' "$1"
}
run() { if [ "$dry" = 1 ]; then echo "[dry-run] $*"; else "$@"; fi; }

case "$cmd" in
  install)
    [ -f "$SRC/SKILL.md" ] || { echo "SKILL.md not found next to scripts/." >&2; exit 1; }
    [ -z "$compact" ] || [[ "$compact" =~ ^[0-9]+$ ]] || { echo "--compact-limit needs a number" >&2; exit 1; }
    B="$CODEX_HOME/backups/codex-limit-saver-$(date +%Y%m%d-%H%M%S)"
    echo "Backup dir: $B"
    run mkdir -p "$B" "$CODEX_HOME" "$SKILLS"
    for f in config.toml AGENTS.md; do
      if [ -f "$CODEX_HOME/$f" ]; then run cp -p "$CODEX_HOME/$f" "$B/$f"; else run touch "$B/$f.absent"; fi
    done
    if [ -d "$DEST" ]; then run mv "$DEST" "$B/skill-previous"; fi
    run cp -R "$SRC" "$DEST"
    run rm -rf "$DEST/.git"

    # AGENTS.md: append the short block (idempotent)
    base=""; [ -f "$AGENTS" ] && base="$(strip_block "$AGENTS" "$A_BEGIN" "$A_END")"
    new="$base"$'\n'"$A_BEGIN"$'\n'"$(cat "$SRC/templates/AGENTS.global.md")"$'\n'"$A_END"$'\n'
    if [ "$dry" = 1 ]; then echo "[dry-run] would write AGENTS block to $AGENTS"; else printf '%s' "$new" > "$AGENTS"; fi

    # config.toml: top-level keys must come BEFORE any [table], so prepend. Skip keys the user already set.
    rest=""; [ -f "$CFG" ] && rest="$(strip_block "$CFG" "$C_BEGIN" "$C_END")"
    block="$C_BEGIN"$'\n'"# Added by codex-limit-saver. Remove with: install.sh uninstall"$'\n'
    has() { printf '%s\n' "$rest" | grep -Eq "^[[:space:]]*$1[[:space:]]*="; }
    if has tool_output_token_limit; then block+="# tool_output_token_limit: already set by you, left alone"$'\n'
    else block+="tool_output_token_limit = 5000"$'\n'; fi
    if [ -n "$compact" ]; then
      if has model_auto_compact_token_limit; then block+="# model_auto_compact_token_limit: already set by you, left alone"$'\n'
      else block+="model_auto_compact_token_limit = $compact"$'\n'; fi
    else
      block+="# model_auto_compact_token_limit = 0   # set ~40% of the model window shown in /status, then uncomment"$'\n'
    fi
    block+="$C_END"$'\n'
    if [ "$dry" = 1 ]; then echo "[dry-run] would prepend to $CFG:"; printf '%s' "$block"
    else printf '%s\n%s\n' "$block" "$rest" > "$CFG"; fi
    echo "Installed. Restart Codex, run it in a scratch folder: a config error would be printed at startup."
    echo "If anything looks wrong: bash $DEST/scripts/install.sh uninstall"
    ;;
  uninstall)
    for pair in "$AGENTS|$A_BEGIN|$A_END" "$CFG|$C_BEGIN|$C_END"; do
      IFS='|' read -r f b e <<<"$pair"
      if [ -f "$f" ] && grep -qF "$b" "$f"; then
        out="$(strip_block "$f" "$b" "$e")"
        if [ -z "$(printf '%s' "$out" | tr -d '[:space:]')" ]; then rm -f "$f"; echo "Removed $f (was only our block)"
        else printf '%s\n' "$out" > "$f"; echo "Cleaned $f"; fi
      fi
    done
    if [ -d "$DEST" ]; then rm -rf "$DEST"; echo "Removed $DEST"; fi
    echo "Done. Originals are still in $CODEX_HOME/backups/ if you need 'restore'."
    ;;
  restore)
    B="${ARG:-}"; [ -d "$B" ] || { echo "Usage: install.sh restore BACKUP_DIR" >&2; exit 1; }
    for f in config.toml AGENTS.md; do
      if [ -f "$B/$f" ]; then cp -p "$B/$f" "$CODEX_HOME/$f"; echo "Restored $f"
      elif [ -f "$B/$f.absent" ]; then rm -f "$CODEX_HOME/$f"; echo "Removed $f (did not exist before)"; fi
    done
    [ -d "$DEST" ] && rm -rf "$DEST"
    [ -d "$B/skill-previous" ] && cp -R "$B/skill-previous" "$DEST" && echo "Restored previous skill"
    ;;
  status)
    echo "CODEX_HOME=$CODEX_HOME"
    [ -d "$DEST" ] && echo "skill: installed at $DEST" || echo "skill: not installed"
    grep -qF "$A_BEGIN" "$AGENTS" 2>/dev/null && echo "AGENTS.md block: present" || echo "AGENTS.md block: absent"
    grep -qF "$C_BEGIN" "$CFG" 2>/dev/null && echo "config.toml block: present" || echo "config.toml block: absent"
    ls -1d "$CODEX_HOME"/backups/codex-limit-saver-* 2>/dev/null | tail -n 5 || true
    ;;
  *) sed -n '2,7p' "$0" ;;
esac
