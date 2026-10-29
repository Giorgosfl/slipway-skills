#!/bin/sh
# SessionStart: both Claude Code and Codex add plain stdout to the model's context.
# A new session gets the full start instructions; a resumed or compacted one only the pointer.

. "$(dirname "$0")/lib.sh"

input=$(cat)
slipway_cd "$input"
source=$(slipway_field "$input" source)
session=$(slipway_field "$input" session_id)
root=${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}

new=1
case $source in resume | compact) new=0 ;; esac


echo "slipway rules apply in this project. They live in $root/rules: one file per stage (start, develop, test, review, ship, maintain, working-style), plus sub files such as develop.ui.md that apply only to one kind of project."
echo "Each time the stage changes, use the slipway-rules skill to pick that stage's file, then read the whole file and follow every rule in it; a search of the files doesn't count."
echo "A slipway hook pauses outward git and GitHub commands. Put SLIPWAY_OK=1 in front of one only when the rules allow it: the owner asked for it; or, for a push, merge or branch clean-up, reviews are clean and every required case passes; or, for a skipped git hook, a deliberate reason is stated in the commit message."
echo "A push or merge, even one the owner named, also waits for the reviewers in review.md and their saved report (Review report)."
# Remember the repo's state at session start, so the Stop hook asks only about this session's changes.
# It runs in the background, after the rules are printed, so a large repo can't delay them.
if dir=$(slipway_data_dir); then
  (
    slipway_repo >/dev/null || exit 0
    mark=$(slipway_mark "$dir" start "$session")
    trees=$(slipway_mark "$dir" trees "$session")
    [ "$new" = 1 ] || [ ! -f "$trees" ] && slipway_write "$trees" "$(slipway_trees)"
    sum=$(slipway_tree_sum "$trees") || exit 0
    [ "$new" = 1 ] || [ ! -f "$mark" ] && slipway_write "$mark" "$sum"
    find "$dir" -type f \( -name 'start-*' -o -name 'stop-*' -o -name 'trees-*' \) -mtime +14 -exec rm -f {} + 2>/dev/null
  ) </dev/null >/dev/null 2>&1 &
fi

[ "$new" = 1 ] || exit 0

echo "Now, at session start, follow $root/rules/start.md: Repo working memory, Session status, Own worktree, See what landed."

codex_home=${CODEX_HOME:-$HOME/.codex}
claude_home=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
claude_json=${CLAUDE_CONFIG_DIR:+$CLAUDE_CONFIG_DIR/.claude.json}

# A quick look for the resources the rules build on; slipway-setup does the full check and asks before installing.
found() {
  for dir in \
    "$claude_home/skills/$1" "$HOME/.agents/skills/$1" "$codex_home/skills/$1" \
    ".claude/skills/$1" ".agents/skills/$1" ".codex/skills/$1"; do
    [ -d "$dir" ] && return 0
  done
  for dir in "$claude_home"/plugins/cache/*/"$1" "$codex_home"/plugins/cache/*/"$1"; do
    [ -d "$dir" ] && return 0
  done
  return 1
}

context7() {
  command -v ctx7 >/dev/null 2>&1 || found find-docs || found context7 || found context7-plugin ||
    grep -qs '^\[mcp_servers\.context7\]' "$codex_home/config.toml" ||
    grep -qs '"context7"' "$HOME/.claude.json" ${claude_json:+"$claude_json"} .mcp.json
}

missing=""
found ponytail || missing="$missing ponytail,"
found mattpocock-skills || found grilling || missing="$missing Matt Pocock's skills,"
found impeccable || missing="$missing impeccable,"
context7 || missing="$missing Context7,"
found security-audit || missing="$missing security-audit-skill,"
found i-have-adhd || missing="$missing i-have-adhd,"
grep -qs '^# DOX framework' AGENTS.md || missing="$missing DOX (in this project's AGENTS.md),"

if [ -n "$missing" ]; then
  echo "These resources the slipway rules build on look missing:${missing%,}. Offer the owner the slipway-setup skill, which checks properly and asks before installing anything."
fi
exit 0
