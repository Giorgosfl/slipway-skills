#!/bin/sh
# Runs each hook the way Claude Code and Codex call it, and checks what it prints.
# Needs python3 to build and read the hook JSON. Usage: sh tests/hooks.test.sh

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fails=0

check() {
  if [ "$2" = "$3" ]; then
    echo "ok   $1"
  else
    echo "FAIL $1"
    echo "     expected: $3"
    echo "     got:      $2"
    fails=$((fails + 1))
  fi
}

field() {
  python3 -c 'import json, sys
text = sys.stdin.read().strip()
if not text:
    print("(empty)")
    sys.exit()
value = json.loads(text)
for key in sys.argv[1].split("."):
    value = value.get(key) if isinstance(value, dict) else None
print(value)' "$1"
}

# run_guard <env> <command>: the guard's raw output for a Bash call.
run_guard() {
  python3 -c 'import json, sys
print(json.dumps({"session_id": "s1", "tool_name": "Bash", "tool_input": {"command": sys.argv[1], "description": "Prepare for git push origin"}}))' "$2" |
    env -u PLUGIN_DATA -u CLAUDE_PLUGIN_DATA $1 CLAUDE_PLUGIN_ROOT="$root" sh "$root/hooks/guard.sh"
}

# kind <command>: which reason Claude Code's guard gives, by its owner-facing text.
kind() {
  case $(run_guard "CLAUDE_PLUGIN_DATA=$work/c" "$1" | field hookSpecificOutput.permissionDecisionReason) in
    "(empty)") echo none ;;
    "slipway: this pushes to the remote and skips"*) echo pushnoverify ;;
    "slipway: this pushes"*) echo push ;;
    "slipway: this acts on GitHub"*) echo owner ;;
    "slipway: this rewrites"*) echo force ;;
    "slipway: this skips git hooks"*) echo noverify ;;
    *) echo other ;;
  esac
}

expect() {
  want=$1
  shift
  for cmd in "$@"; do check "$want: $(printf '%s' "$cmd" | tr '\n\t' '  ')" "$(kind "$cmd")" "$want"; done
}

expect push \
  'git push' 'git push origin main' 'git -C /repo push' 'git -c user.name=x push' 'git --git-dir /r/.git push' \
  'cd repo && git push' 'git push;ls' 'git push&&ls' '(git push)' 'ls
git push' "$(printf 'git\tpush')" 'echo $(git push)' 'x="$(git push)"' 'echo "done: `git push`"' \
  'bash -c "git push origin main"' 'bash -e -c "git push"' 'sudo git push' 'sudo -u deploy git push' \
  'timeout 120 git push origin main' 'nice -n 5 git push' 'stdbuf -oL git push' 'noglob git push' \
  'echo main | xargs git push origin' 'if true; then git push; fi' 'git push \
  origin main' 'gh pr merge 12 --squash' 'gh pr update-branch 3' 'git push --delete origin old' \
  'git push -d origin old' 'git push origin :old' 'git commit -m "$(cat <<'"'"'EOF'"'"'
Fix (it) properly
EOF
)" && git push'
expect owner \
  'gh pr create --fill' 'gh pr new' 'gh pr review 3 --approve' 'gh pr comment 3 -b hi' 'gh issue create -t x' \
  'gh issue new' 'gh issue comment 3 --body hi' 'gh -R o/r issue close 4' 'gh release create v1.0.0' \
  'gh api -X POST repos/o/r/issues' 'gh api repos/o/r/issues/1/comments -f body=hi' 'gh api --method=PATCH repos/o/r' \
  'gh api graphql -f query="mutation { addStar(input: {}) { clientMutationId } }"' 'gh secret set TOKEN' \
  'gh workflow run ci.yml' 'gh repo edit --description x'
expect force \
  'git push --force origin main' 'git push -f' 'git push -uf origin main' 'git push origin +main' \
  'git push --force-with-lease' 'git push --mirror' 'gh repo delete o/r --yes' 'gh release delete v1' \
  'gh issue delete 4' 'gh repo edit --visibility public'
expect noverify \
  'git commit --no-verify -m x' 'git commit -n -m x' 'git commit -anm x' \
  'git -c core.hooksPath=/dev/null commit -m x' 'git merge --no-verify feature'
expect none \
  'ls -la' 'git status' 'git stash push -m wip' 'git log --grep push' 'git commit -m "fix git push docs"' \
  'grep -rn -- --no-verify .' 'echo "git push later"' 'git push-helper' 'gh issue list' 'gh pr view 3' \
  'gh api repos/o/r/pulls' 'gh api -X GET repos/o/r' 'git commit -m "skip --no-verify docs"' 'git merge feature' \
  'git push --dry-run' 'git push -n origin main' 'gh api graphql -f query="query { viewer { login } }"' \
  'SLIPWAY_OK=1 git push origin main' 'SLIPWAY_OK=1 gh pr merge 3' 'SLIPWAY_OK=1 git push --force' \
  'env SLIPWAY_OK=1 git push' 'npm test' '# Don'"'"'t push yet
ls' 'cat > notes.md <<EOF
git push origin main
gh pr create
EOF' 'cat > notes.md <<-EOF
	git push
	EOF'
expect owner 'gh api repos/{owner}/{repo}/issues/1/comments -f body=hi' 'gh api -X POST repos/{owner}/{repo}/labels'
expect owner 'gh api -X DELETE repos/{owner}/{repo}/git/refs/heads/old'
expect push 'git -C ${REPO} push' 'git push origin ${BRANCH}' '{ git push; }'
expect force 'git push origin ${BRANCH} --force'
expect noverify 'git commit -m ${MSG} --no-verify'
expect pushnoverify 'git push --no-verify' 'git -c core.hooksPath=/dev/null push'
expect none 'git commit -m "$(cat <<'"'"'EOF'"'"'
Fix two things:
1) the list
2) mention `git push --force` in docs
EOF
)"' '{ ls; }' 'echo {a,b}'
expect push 'git subtree push --prefix dist origin gh-pages' 'git -C $(git rev-parse --show-toplevel) push' \
  'git push origin $(git branch --show-current)' 'git push origin `git branch --show-current`'
expect force 'git push origin $(git branch --show-current) --force'
expect owner 'gh api $(echo repos/o/r/issues) -f title=x'
expect noverify 'HUSKY=0 git commit -m x' 'LEFTHOOK=0 git merge feature'
expect pushnoverify 'HUSKY=0 git push'
expect none 'git commit -m"Init"' 'git commit -mdone' 'git status -uno' 'git commit -uno -m x' 'echo $((1 + 2))'
expect owner 'gh api graphql -f query="$(cat <<'"'"'EOF'"'"'
mutation { resolveReviewThread(input: {threadId: "x"}) { thread { isResolved } } }
EOF
)"' 'gh api graphql -f query="$Q"' 'gh api graphql -f query="$(cat m.graphql)"' 'gh api graphql -F query=@m.graphql'
expect none 'gh api graphql -f query="{ viewer { login } }"' 'gh api graphql -f query="fragment f on User { login }"'
expect push 'SLIPWAY_OK=1 git status && git push' '# Don'"'"'t forget
git push' 'cat <<EOF
text
EOF
git push'

# What each app gets back.
check "claude asks" "$(run_guard "CLAUDE_PLUGIN_DATA=$work/c" 'git push' | field hookSpecificOutput.permissionDecision)" "ask"
check "claude tells the agent about the marker" "$(run_guard "CLAUDE_PLUGIN_DATA=$work/c" 'git push' | field hookSpecificOutput.additionalContext | grep -c SLIPWAY_OK=1)" "1"
check "codex denies" "$(run_guard "PLUGIN_DATA=$work/x" 'git push' | field hookSpecificOutput.permissionDecision)" "deny"
check "codex's reason is for the agent" "$(run_guard "PLUGIN_DATA=$work/x" 'git push' | field hookSpecificOutput.permissionDecisionReason | grep -c 'SLIPWAY_OK=1 in front')" "1"
check "codex passes a marked push" "$(run_guard "PLUGIN_DATA=$work/x" 'SLIPWAY_OK=1 git push' | field x)" "(empty)"
check "codex passes a grep for --no-verify" "$(run_guard "PLUGIN_DATA=$work/x" 'grep -rn -- --no-verify .' | field x)" "(empty)"
big=$(python3 -c 'print("echo " + "x" * 400000 + " && git push")')
started=$(date +%s)
check "a 400 KB command is still checked" "$(kind "$big")" "push"
check "and within the timeout" "$(( $(date +%s) - started < 8 ))" "1"

# Session start.
start() {
  printf '{"session_id":"s1","source":"%s","cwd":"%s"}' "$1" "$2" |
    env -u PLUGIN_DATA -u CLAUDE_CONFIG_DIR CLAUDE_PLUGIN_DATA="$work/start-data" CLAUDE_PLUGIN_ROOT="$root" HOME="$work/home" $3 sh "$root/hooks/session-start.sh"
}
mkdir -p "$work/plain" "$work/home" "$work/cfg/plugins/cache/ponytail/ponytail"
out=$(start startup "$work/plain")
check "startup points to the rules" "$(printf '%s' "$out" | grep -c "$root/rules")" "2"
check "startup gives the start instructions" "$(printf '%s' "$out" | grep -c 'Now, at session start')" "1"
check "startup explains the marker" "$(printf '%s' "$out" | grep -c 'SLIPWAY_OK=1')" "1"
check "startup lists missing resources" "$(printf '%s' "$out" | grep -c 'look missing')" "1"
check "startup finds plugins under CLAUDE_CONFIG_DIR" "$(start startup "$work/plain" "CLAUDE_CONFIG_DIR=$work/cfg" | grep -c 'missing: ponytail')" "0"
out=$(start compact "$work/plain")
check "compact skips the start instructions" "$(printf '%s' "$out" | grep -c 'Now, at session start')" "0"
check "compact still explains the marker" "$(printf '%s' "$out" | grep -c 'SLIPWAY_OK=1')" "1"

# Stop: asks once per new state, only for changes made during the session, in any worktree.
repo="$work/repo with space"
mkdir -p "$repo" && (cd "$repo" && git init -q && git commit -q --allow-empty -m init && echo old >owner.txt)
begin() {
  printf '{"session_id":"%s","source":"startup","cwd":"%s"}' "$2" "$repo" |
    env -u PLUGIN_DATA -u CLAUDE_PLUGIN_DATA $1 CLAUDE_PLUGIN_ROOT="$root" HOME="$work/home" sh "$root/hooks/session-start.sh" >/dev/null
  # The baseline is written in the background; wait for it.
  data=${1#*=}
  tries=0
  until ls "$data"/start-"$2"-* >/dev/null 2>&1 || [ "$tries" -ge 50 ]; do
    tries=$((tries + 1))
    python3 -c 'import time; time.sleep(0.1)'
  done
}
stop() {
  printf '{"session_id":"%s","stop_hook_active":%s,"cwd":"%s"}' "${4:-s1}" "$1" "${3:-$repo}" |
    (cd / && env -u PLUGIN_DATA -u CLAUDE_PLUGIN_DATA $2 sh "$root/hooks/stop.sh")
}
cdata="CLAUDE_PLUGIN_DATA=$work/stop-claude"
xdata="PLUGIN_DATA=$work/stop-codex"
begin "$cdata" s1
check "stop: owner's earlier edits don't count" "$(stop false "$cdata" | field x)" "(empty)"
(cd "$repo" && echo change >file.txt)
check "stop: claude gets feedback, not a block" "$(stop false "$cdata" | field hookSpecificOutput.hookEventName)" "Stop"
(cd "$repo" && echo more >>file.txt)
check "stop: our own continuation finishes" "$(stop true "$cdata" | field x)" "(empty)"
check "stop: what the continuation fixed counts as checked" "$(stop false "$cdata" | field x)" "(empty)"
check "stop: same state finishes" "$(stop false "$cdata" | field x)" "(empty)"
(cd "$repo" && echo again >>file.txt)
check "stop: new edits to an untracked file ask again" "$(stop false "$cdata" | field hookSpecificOutput.hookEventName)" "Stop"
(cd "$repo" && git add -A && git commit -q -m work)
check "stop: a new commit asks again" "$(stop false "$cdata" | field hookSpecificOutput.hookEventName)" "Stop"
begin "$cdata" s2
(cd "$repo" && git worktree add -q "$work/wt" && echo wt >"$work/wt/new.txt")
check "stop: work in a new worktree asks, from the worktree" "$(stop false "$cdata" "$work/wt" s2 | field hookSpecificOutput.hookEventName)" "Stop"
begin "$xdata" s3
(cd "$work/wt" && echo more >>new.txt)
check "stop: another session's worktree doesn't count" "$(stop false "$xdata" "$repo" s3 | field x)" "(empty)"
(cd "$repo" && git worktree add -q "$work/wt3" && echo three >"$work/wt3/three.txt")
check "stop: codex sees work in a worktree it made, from the main checkout" "$(stop false "$xdata" "$repo" s3 | field decision)" "block"
stop false "$cdata" "$repo" s2 >/dev/null
stop true "$cdata" "$repo" s2 >/dev/null
(cd "$repo" && echo goal >>file.txt)
check "stop: another hook's continuation still gets checked" "$(stop true "$cdata" "$repo" s2 | field hookSpecificOutput.hookEventName)" "Stop"
clean="$work/clean"
mkdir -p "$clean" && (cd "$clean" && git init -q && echo ".cache/" >.gitignore && git add .gitignore && git commit -q -m init)
printf '{"session_id":"s9","source":"startup","cwd":"%s"}' "$clean" | env -u PLUGIN_DATA $cdata CLAUDE_PLUGIN_ROOT="$root" HOME="$work/home" sh "$root/hooks/session-start.sh" >/dev/null
tries=0; until ls "$work/stop-claude"/start-s9-* >/dev/null 2>&1 || [ "$tries" -ge 50 ]; do tries=$((tries + 1)); python3 -c 'import time; time.sleep(0.1)'; done
(cd "$clean" && mkdir .cache && touch .cache/x)
check "stop: an ignored folder in a clean checkout doesn't count" "$(stop false "$cdata" "$clean" s9 | field x)" "(empty)"
check "stop: no plugin data folder, no output" "$(stop false "PLUGIN_DATA=" | field x)" "(empty)"
check "stop: outside a repo, no output" "$(stop false "$cdata" "$work/plain" | field x)" "(empty)"

echo
[ "$fails" -eq 0 ] && echo "all hook checks passed" || echo "$fails hook check(s) failed"
[ "$fails" -eq 0 ]
