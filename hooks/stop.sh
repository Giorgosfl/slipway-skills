#!/bin/sh
# Stop: asks for one verification pass whenever the repo, in any of its worktrees,
# changed during this session and hasn't been checked since.
# Claude Code takes non-error feedback through additionalContext; Codex accepts only {"decision":"block"}.

. "$(dirname "$0")/lib.sh"

input=$(cat)
slipway_cd "$input"

dir=$(slipway_data_dir) || exit 0
slipway_repo >/dev/null || exit 0
session=$(slipway_field "$input" session_id)
start=$(slipway_mark "$dir" start "$session")
last=$(slipway_mark "$dir" stop "$session")
sum=$(slipway_tree_sum "$(slipway_mark "$dir" trees "$session")") || exit 0

# The continuation that follows our own ask: whatever it fixed counts as checked.
# A continuation another Stop hook started gets the normal check below.
case "$input" in
  *'"stop_hook_active":true'* | *'"stop_hook_active": true'*)
    if [ -f "$last.asked" ]; then
      rm -f "$last.asked"
      slipway_write "$last" "$sum"
      exit 0
    fi
    ;;
esac
rm -f "$last.asked"

if [ ! -f "$start" ]; then
  slipway_write "$start" "$sum"
  exit 0
fi
[ "$(cat "$start")" = "$sum" ] && exit 0
[ -f "$last" ] && [ "$(cat "$last")" = "$sum" ] && exit 0
slipway_write "$last" "$sum"
: >"$last.asked"

reason="Before you finish, check the slipway rules for what changed in this session:"
reason="$reason the project's checks ran on it (Check before done);"
reason="$reason every 'works' points to a test or evidence, and anything untested is named (No untested claims);"
reason="$reason anything merged or pushed was reviewed first, even when the owner named it, and the owner saw the table (Review report);"
reason="$reason nothing outward happened beyond what the Outward actions rule allows."
reason="$reason If all of it holds, finish as planned."

if [ "$(slipway_host)" = codex ]; then
  printf '{"decision":"block","reason":"%s"}\n' "$reason"
else
  printf '{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"%s"}}\n' "$reason"
fi
