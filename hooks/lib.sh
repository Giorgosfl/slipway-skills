#!/bin/sh
# Helpers shared by the slipway hooks. Sourced, not run.

# Only Codex sets PLUGIN_DATA; Claude Code sets CLAUDE_PLUGIN_DATA.
slipway_host() {
  if [ -n "$PLUGIN_DATA" ]; then echo codex; else echo claude; fi
}

# The plugin's own data folder; there is none outside a plugin install.
slipway_data_dir() {
  dir=${PLUGIN_DATA:-$CLAUDE_PLUGIN_DATA}
  [ -n "$dir" ] || return 1
  mkdir -p "$dir" 2>/dev/null || return 1
  [ -d "$dir" ] && [ ! -L "$dir" ] && [ -O "$dir" ] || return 1
  echo "$dir"
}

# One JSON string field from the hook's stdin, kept to safe file-name characters.
slipway_field() {
  printf '%s' "$1" | sed -nE "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"([^\"]*)\".*/\\1/p" | head -n 1 | tr -cd 'A-Za-z0-9_.-'
}

# Move to the session's directory, as the hook's stdin reports it.
slipway_cd() {
  dir=$(printf '%s' "$1" | sed -nE 's/.*"cwd"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p' | head -n 1 | sed -e 's/\\"/"/g' -e 's/\\\\/\\/g')
  [ -n "$dir" ] && cd "$dir" 2>/dev/null
  return 0
}

# The repo's shared git folder, the same for every worktree of it.
slipway_repo() {
  git rev-parse --path-format=absolute --git-common-dir 2>/dev/null
}

# Every worktree of the repo, one path per line.
slipway_trees() {
  git worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p'
}

# A checksum of the repo's state: commits, staged and unstaged edits, and
# untracked files (by size and time, to stay fast). It covers this checkout and
# every worktree not listed in the file $1, the worktrees that already existed
# when the session started; so a worktree this session makes counts, and other
# sessions' worktrees don't. No optional locks, so other sessions' git commands
# never meet our index.lock.
slipway_tree_sum() {
  GIT_OPTIONAL_LOCKS=0
  export GIT_OPTIONAL_LOCKS
  slipway_repo >/dev/null || return 1
  own=$(git rev-parse --show-toplevel 2>/dev/null)
  slipway_trees | while IFS= read -r tree; do
    [ "$tree" != "$own" ] && [ -n "$1" ] && grep -Fxqs -- "$tree" "$1" && continue
    (
      cd "$tree" 2>/dev/null || exit 0
      echo "$tree"
      git rev-parse HEAD 2>/dev/null
      git status --porcelain -z
      git -c core.quotePath=true diff --no-ext-diff --no-textconv --no-color
      git -c core.quotePath=true diff --cached --no-ext-diff --no-textconv --no-color
      count=$(git ls-files --others --exclude-standard -z | tr -cd '\0' | wc -c)
      if [ "$count" -eq 0 ]; then
        :
      elif [ "$count" -le 2000 ]; then
        git ls-files --others --exclude-standard -z | xargs -0 ls -lnd -- 2>/dev/null
      else
        git ls-files --others --exclude-standard -z
      fi
    )
  done | cksum | cut -d' ' -f1
}

# A file name for this session in this repo.
slipway_mark() {
  repo=$(slipway_repo | cksum | cut -d' ' -f1)
  echo "$1/$2-${3:-nosession}-$repo"
}

slipway_write() {
  tmp="$1.tmp.$$"
  printf '%s' "$2" >"$tmp" && mv -f "$tmp" "$1"
}
