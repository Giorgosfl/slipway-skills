#!/bin/sh
# PreToolUse on Bash: applies the Outward actions, Review report and Check before done rules.
# Claude Code asks the owner. Codex rejects "ask" and runs the tool anyway, so there the guard denies.
# Either way, a command the rules allow runs when it starts with SLIPWAY_OK=1; a push or merge also
# needs a clean review report saved for each commit it publishes, and passes only as one plain command.
# With SLIPWAY_NO_REVIEW=1, Claude Code confirms with the owner and Codex refuses.

. "$(dirname "$0")/lib.sh"

input=$(cat)
case $input in *git* | *gh*) ;; *) exit 0 ;; esac
slipway_cd "$input"

out=$(printf '%s' "$input" | awk '
# Decode the "command" string from the hook JSON.
function command_of(json,    pos, rest, out, c) {
  if (!match(json, /"command"[ \t\r\n]*:[ \t\r\n]*"/)) return ""
  pos = RSTART + RLENGTH; out = ""
  while (1) {
    rest = substr(json, pos)
    if (!match(rest, /["\\]/)) return out rest
    out = out substr(rest, 1, RSTART - 1); pos += RSTART
    if (substr(rest, RSTART, 1) == "\"") return out
    c = substr(json, pos, 1); pos++
    if (c == "n") c = "\n"; else if (c == "t") c = "\t"; else if (c == "r") c = "\r"
    else if (c == "u") { c = " "; pos += 4 }
    out = out c
  }
}

# Split a command line into simple commands, word by word, the way a shell would,
# skipping comments and heredoc bodies, and looking inside $(...) and `...`.
function scan(line, depth,    i, c, n, q, qpos, word, inword, k, end, rest, sub_, sv, svn, delim, dash, line_, here, hereshell) {
  n = length(line); q = ""; word = ""; inword = 0; nw = 0; here = ""
  for (i = 1; i <= n; i++) {
    if (found == "force") return
    c = substr(line, i, 1)
    if (q == "'\''") {
      k = index(substr(line, i), "'\''")
      if (k == 0) { word = word substr(line, i); i = n; break }
      word = word substr(line, i, k - 1); i += k - 1; q = ""; continue
    }
    if (q == "\"") {
      rest = substr(line, i)
      if (!match(rest, /["\\$`]/)) { word = word rest; i = n; break }
      word = word substr(rest, 1, RSTART - 1); i += RSTART - 1; c = substr(line, i, 1)
      if (c == "\"") { q = ""; continue }
      if (c == "\\") { if (substr(line, i + 1, 1) != "\n") word = word substr(line, i + 1, 1); i++; continue }
      if (c == "`" || substr(line, i, 2) == "$(") {
        end = closing(line, i)
        sub_ = c == "`" ? substr(line, i + 1, end - i - 1) : substr(line, i + 2, end - i - 2)
        for (k = 1; k <= nw; k++) sv[k] = words[k]; svn = nw
        if (depth < 4) scan(sub_, depth + 1)
        for (k = 1; k <= svn; k++) words[k] = sv[k]; nw = svn
        i = end; continue
      }
      word = word c; continue
    }
    if (c !~ /[ \t\\"#<;&|()`{}\n\r'\'']/) {
      rest = substr(line, i)
      k = match(rest, /[ \t\\"<;&|()`\n\r'\'']/) ? RSTART - 1 : length(rest)
      word = word substr(rest, 1, k); inword = 1; i += k - 1; continue
    }
    if (c == "\\") { if (substr(line, i + 1, 1) != "\n") { word = word substr(line, i + 1, 1); inword = 1 } i++; continue }
    if (c == "'\''" || c == "\"") { q = c; qpos = i; inword = 1; continue }
    if (c == "#" && !inword) { k = index(substr(line, i), "\n"); if (k == 0) break; i += k - 2; continue }
    if (c == "<" && substr(line, i, 3) == "<<<") { i += 2; continue }
    if (c == "<" && substr(line, i + 1, 1) == "<") {
      if (inword) { words[++nw] = word; word = ""; inword = 0 }
      i += 2; dash = 0
      if (substr(line, i, 1) == "-") { dash = 1; i++ }
      while (substr(line, i, 1) == " " || substr(line, i, 1) == "\t") i++
      delim = ""
      while (i <= n && substr(line, i, 1) !~ /[ \t\n;&|<>()]/) { delim = delim substr(line, i, 1); i++ }
      gsub(/["\\'\'']/, "", delim)
      here = delim; hereshell = (nw > 0 && words[1] ~ /(^|\/)(sh|bash|zsh|dash)$/)
      i--; continue
    }
    if (c == " " || c == "\t") { if (inword) { words[++nw] = word; word = ""; inword = 0 } continue }
    if ((c == "{" || c == "}") && (inword || (substr(line, i + 1, 1) != "" && substr(line, i + 1, 1) !~ /[ \t\n;]/))) { word = word c; inword = 1; continue }
    if (c == "`" || (c == "(" && inword && substr(word, length(word)) == "$" && substr(line, i + 1, 1) != "(")) {
      end = closing(line, c == "`" ? i : i - 1)
      sub_ = c == "`" ? substr(line, i + 1, end - i - 1) : substr(line, i + 1, end - i - 1)
      for (k = 1; k <= nw; k++) sv[k] = words[k]; svn = nw
      if (depth < 4) scan(sub_, depth + 1)
      for (k = 1; k <= svn; k++) words[k] = sv[k]; nw = svn
      word = word "x"; inword = 1; i = end; continue
    }
    if (c ~ /[;&|()`{}\n\r]/) {
      if (inword) { words[++nw] = word; word = ""; inword = 0 }
      check(depth); nw = 0
      if (c == "\n" && here != "") {
        if (!hereshell) {
          while (i < n) {
            k = index(substr(line, i + 1), "\n")
            line_ = k ? substr(line, i + 1, k - 1) : substr(line, i + 1)
            if (dash) sub(/^\t+/, "", line_)
            i = k ? i + k : n
            if (line_ == here) break
          }
        }
        here = ""
      }
      continue
    }
    word = word c; inword = 1
  }
  if (inword) words[++nw] = word
  check(depth); nw = 0
  if (q != "" && depth < 4) scan(substr(line, qpos + 1), depth + 1)
}

# The position of the ")" or "`" that closes the substitution starting at i,
# stepping over quoted strings and heredoc bodies inside it.
function closing(line, i,    d, j, c, n, k, m, delim, ln) {
  n = length(line)
  if (substr(line, i, 1) == "`") { j = index(substr(line, i + 1), "`"); return j ? i + j : n }
  d = 0
  for (j = i + 1; j <= n; j++) {
    c = substr(line, j, 1)
    if (c == "\\") { j++; continue }
    if (c == "'\''") { k = index(substr(line, j + 1), "'\''"); if (!k) return n; j += k; continue }
    if (c == "\"") {
      for (j++; j <= n; j++) { c = substr(line, j, 1); if (c == "\\") { j++; continue } if (c == "\"") break }
      continue
    }
    if (c == "<" && substr(line, j + 1, 1) == "<" && substr(line, j + 2, 1) != "<") {
      k = j + 2
      if (substr(line, k, 1) == "-") k++
      while (substr(line, k, 1) == " " || substr(line, k, 1) == "\t") k++
      delim = ""
      while (k <= n && substr(line, k, 1) !~ /[ \t\n;&|<>()]/) { delim = delim substr(line, k, 1); k++ }
      gsub(/["\\'\'']/, "", delim)
      m = index(substr(line, k), "\n"); if (!m) return n
      j = k + m - 1
      while (j < n) {
        m = index(substr(line, j + 1), "\n")
        ln = m ? substr(line, j + 1, m - 1) : substr(line, j + 1)
        sub(/^\t+/, "", ln)
        j = m ? j + m : n
        if (ln == delim) break
      }
      continue
    }
    if (c == "(") d++
    else if (c == ")") { d--; if (d == 0) return j }
  }
  return n
}

function rank(k) { return k == "force" ? 7 : k == "owner" ? 6 : k == "pushnoverify" ? 5 : k == "noverify" ? 4 : k == "push" ? 3 : k == "waived" ? 2 : k == "review" ? 1 : 0 }
# A command marked SLIPWAY_OK=1 passes, except one that publishes commits (a push or merge that is not only
# a branch delete): that becomes "review", or "waived" with SLIPWAY_NO_REVIEW=1, and the shell below decides.
function flag(k) {
  if (cur_ok) {
    if (!cur_push || cur_delete) return
    k = cur_waive ? "waived" : "review"
  }
  if (rank(k) > rank(found)) { found = k; target = cur_target; plain = cur_plain }
}
function short_has(w, letters) { return w ~ /^-[A-Za-z]+$/ && w ~ letters }

# Whether a gh api graphql field could carry a mutation: one the guard cannot read
# (empty, a $variable, a file) counts as one; only a literal read query passes.
function writes(field,    v) {
  if (field ~ /mutation|=@/) return 1
  if (field !~ /^query=/) return 0
  v = substr(field, 7); sub(/^[ \t\r\n]+/, "", v)
  return v == "" || v ~ /\$/ || v !~ /^(query|\{|fragment)/
}

# Look at one simple command held in words[1..nw].
function check(depth,    envskip, i, ok, waive, w, cmd, pos, save_ok, save_waive, j, s, a, group, act, method, fields, graphql, mutation, hooksoff, k, dry) {
  if (nw == 0) return
  i = 1; ok = inh_ok; waive = inh_waive; envskip = 0
  while (i <= nw) {
    w = words[i]
    if (w ~ /^[A-Za-z_][A-Za-z0-9_]*=/) {
      if (w == "SLIPWAY_OK=1") ok = 1
      if (w == "SLIPWAY_NO_REVIEW=1") waive = 1
      if (w ~ /^(HUSKY=0|LEFTHOOK=0|SKIP=.+)$/) envskip = 1
      i++; continue
    }
    if (w ~ /^(if|then|do|else|elif|while|until|!|time|nohup|builtin|command|exec|noglob|nocorrect)$/) { i++; continue }
    if (w == "sudo") { i++; while (i <= nw && words[i] ~ /^-/) i += words[i] ~ /^-[ugChpUrtD]$/ ? 2 : 1; continue }
    if (w == "env") {
      i++
      while (i <= nw && (words[i] ~ /^-/ || words[i] ~ /^[A-Za-z_][A-Za-z0-9_]*=/)) {
        if (words[i] == "SLIPWAY_OK=1") ok = 1
        if (words[i] == "SLIPWAY_NO_REVIEW=1") waive = 1
        i += words[i] ~ /^-[uCS]$/ ? 2 : 1
      }
      continue
    }
    if (w == "nice") { i++; while (i <= nw && words[i] ~ /^-/) i += words[i] == "-n" ? 2 : 1; continue }
    if (w == "timeout") { i++; while (i <= nw && words[i] ~ /^-/) i += words[i] ~ /^-[sk]$/ ? 2 : 1; i++; continue }
    if (w == "stdbuf") { i++; while (i <= nw && words[i] ~ /^-/) i += words[i] ~ /^-[ioe]$/ ? 2 : 1; continue }
    if (w == "xargs") { i++; while (i <= nw && words[i] ~ /^-/) i += words[i] ~ /^-[EIiLlnPsd]$/ ? 2 : 1; continue }
    if (w == "watch") { i++; while (i <= nw && words[i] ~ /^-/) i += words[i] ~ /^-[nd]$/ ? 2 : 1; continue }
    break
  }
  if (i > nw) return
  ncmd++
  cmd = words[i]; sub(/.*\//, "", cmd)
  cur_ok = ok; cur_waive = waive; cur_push = 0; cur_delete = 0; cur_target = ""; cur_plain = 1

  if (cmd ~ /^(sh|bash|zsh|dash)$/) {
    for (k = i + 1; k < nw; k++) if (words[k] ~ /^-[A-Za-z]*c[A-Za-z]*$/) {
      if (depth < 4) {
        s = words[k + 1]; nw = 0; save_ok = inh_ok; save_waive = inh_waive; inh_ok = ok; inh_waive = waive
        scan(s, depth + 1); inh_ok = save_ok; inh_waive = save_waive
      }
      return
    }
    return
  }

  if (cmd == "git") {
    j = i + 1; hooksoff = envskip
    while (j <= nw && words[j] ~ /^-/) {
      cur_plain = 0
      if (words[j] ~ /^(-C|-c|--git-dir|--work-tree|--namespace|--super-prefix|--config-env)$/) {
        if (words[j] == "-c" && words[j + 1] ~ /^core\.hooks[Pp]ath=/) hooksoff = 1
        j += 2
      } else j++
    }
    s = words[j]
    if (s == "subtree" && words[j + 1] == "push") { cur_push = 1; cur_plain = 0; flag("push"); return }
    if (s == "push") {
      k = "push"; dry = 0; cur_push = 1; pos = 0
      for (a = j + 1; a <= nw; a++) {
        w = words[a]
        if (w == "--dry-run" || short_has(w, "n")) dry = 1
        if (w ~ /^--force/ || w == "--mirror" || w ~ /^\+./ || short_has(w, "f")) k = "force"
        if (w == "--delete" || short_has(w, "d")) cur_delete = 1
        if (w == "--no-verify") hooksoff = 1
        # An option that adds refs or takes a value (--all, --tags, -o, --repo) makes the commits unclear.
        if (w ~ /^-/ && w !~ /^-[ufqvnd]+$/ && w !~ /^--(set-upstream|quiet|verbose|progress|no-progress|force|force-with-lease(=.*)?|force-if-includes|no-verify|verify|atomic|dry-run|delete)$/) cur_plain = 0
        # After the remote, each refspec that is not a delete names a commit to review; a bare ":" names none.
        if (w !~ /^-/ && ++pos >= 2) {
          if (w == ":" || w == "+:") cur_plain = 0
          else if (w !~ /^:/) { w = substr(w, w ~ /^\+/ ? 2 : 1); sub(/:.*/, "", w); cur_target = cur_target (cur_target == "" ? "" : "\n") w }
        }
      }
      if (pos >= 2 && cur_target == "" && cur_plain) cur_delete = 1
      if (hooksoff && k == "push") k = "pushnoverify"
      if (!dry) flag(k)
    } else if (s ~ /^(commit|merge|am|rebase|cherry-pick|revert)$/) {
      for (a = j + 1; a <= nw; a++) {
        w = words[a]; sub(/[mFCcuSt].*$/, "", w)
        if (words[a] == "--no-verify" || (s == "commit" && short_has(w, "n"))) hooksoff = 1
        if (words[a] ~ /^-[mFC]$/) a++
      }
      if (hooksoff) flag("noverify")
    }
    return
  }

  if (cmd == "gh") {
    j = i + 1; repo = "-"
    while (j <= nw && words[j] ~ /^-/) {
      if (words[j] ~ /^(-R|--repo)$/) { repo = words[j + 1]; j += 2 }
      else { cur_plain = 0; j += words[j] == "--hostname" ? 2 : 1 }
    }
    group = words[j]; act = words[j + 1]
    if ((group == "pr" && act ~ /^(merge|update-branch)$/)) {
      # The pull request: the first word after the action that is neither an option nor the value of one.
      pr = "-"
      for (a = j + 2; a <= nw; a++) {
        w = words[a]
        if (w ~ /^(-R|--repo)$/) { repo = words[++a]; continue }
        if (w ~ /^(-t|--subject|-b|--body|-F|--body-file|-A|--author-email|--match-head-commit)$/) { a++; continue }
        if (w ~ /^-/) continue
        if (pr == "-") pr = w; else cur_plain = 0
      }
      cur_push = 1; cur_target = "pr " repo " " pr
      flag("push")
    }
    else if ((group == "repo" && act ~ /^(delete|archive|rename)$/) ||
        (group == "release" && act == "delete") ||
        (group == "issue" && act ~ /^(delete|transfer)$/)) flag("force")
    else if (group == "repo" && act == "edit") {
      for (a = j + 2; a <= nw; a++) if (words[a] ~ /^--visibility/) { flag("force"); return }
      flag("owner")
    }
    else if ((group == "pr" && act ~ /^(create|new|comment|close|reopen|edit|review|ready|lock|unlock|revert)$/) ||
        (group == "issue" && act ~ /^(create|new|comment|close|reopen|edit|lock|unlock|pin|unpin|develop)$/) ||
        (group == "release" && act ~ /^(create|new|edit|upload|delete-asset)$/) ||
        (group == "repo" && act ~ /^(create|new|unarchive|fork|sync)$/) ||
        (group == "repo" && act ~ /^(deploy-key|autolink)$/ && words[j + 2] ~ /^(add|create|delete)$/) ||
        (group == "gist" && act ~ /^(create|new|edit|delete)$/) ||
        (group == "label" && act ~ /^(create|edit|delete|clone)$/) ||
        (group == "workflow" && act ~ /^(run|enable|disable)$/) ||
        (group == "run" && act ~ /^(rerun|cancel|delete)$/) ||
        (group ~ /^(secret|variable)$/ && act ~ /^(set|delete|remove)$/) ||
        (group == "cache" && act == "delete") ||
        (group == "project" && act ~ /^(create|edit|delete|close|copy|link|unlink|mark-template|item-|field-)/)) flag("owner")
    else if (group == "api") {
      method = ""; fields = 0; graphql = 0; mutation = 0
      for (a = j + 1; a <= nw; a++) {
        w = words[a]
        if (w == "graphql") graphql = 1
        if (w == "-X" || w == "--method") { method = toupper(words[a + 1]); a++ }
        else if (w ~ /^-X./) method = toupper(substr(w, 3))
        else if (w ~ /^--method=/) method = toupper(substr(w, 10))
        else if (w ~ /^(-f|-F|--field|--raw-field)$/) { fields = 1; a++; if (writes(words[a])) mutation = 1 }
        else if (w ~ /^(-f|-F|--field|--raw-field)./) { fields = 1; if (writes(substr(w, 3))) mutation = 1 }
        else if (w ~ /^--input/) { fields = 1; mutation = 1 }
      }
      if (graphql) { if (mutation) flag("owner") }
      else if ((method != "" && method != "GET") || (method == "" && fields)) flag("owner")
    }
  }
}

{ json = json $0 "\n" }
# A marked push or merge passes only as the one command in the line: an earlier cd, commit or checkout
# would change what it publishes after the guard has looked.
END {
  found = ""; target = ""; plain = 0; ncmd = 0
  scan(command_of(json), 0)
  if (ncmd > 1) plain = 0
  print found; print plain; print target
}
')

{
  read -r kind
  read -r plain
  targets=$(cat)
} <<EOF
$out
EOF

# A clean report: a table whose Result column has at least one ✅ and no ❌ (a ❌ in a Note doesn't count).
clean_report() {
  [ -s "$1" ] && awk -F'|' '
    NF >= 4 { if ($3 ~ /❌/) bad = 1; if ($3 ~ /✅/) good = 1 }
    END { exit !(good && !bad) }' "$1"
}

# Each commit a marked push or merge publishes: each pushed ref, the pull request's head, or HEAD.
# It passes only when every one has a clean report; a commit the guard can't tell makes it ask.
if [ "$kind" = review ] || [ "$kind" = waived ]; then
  unknown=0
  [ "$plain" = 1 ] || unknown=1
  reports=$(slipway_repo)/slipway/reviews
  report="" short="" dirty=0
  while [ "$unknown" = 0 ] && IFS= read -r t; do
    case $t in
      "pr "*)
        set -- $t
        pr=$3 repo=$2
        set -- pr view
        [ "$pr" = - ] || set -- "$@" "$pr"
        [ "$repo" = - ] || set -- "$@" -R "$repo"
        commit=$(gh "$@" --json headRefOid -q .headRefOid 2>/dev/null) ;;
      "") commit=$(git rev-parse --verify -q HEAD 2>/dev/null) ;;
      *) commit=$(git rev-parse --verify -q "$t^{commit}" 2>/dev/null) ;;
    esac
    [ -n "$commit" ] || { unknown=1; break; }
    clean_report "$reports/$commit.md" && continue
    dirty=1
    [ -n "$report" ] && continue
    report=$reports/$commit.md
    short=$(printf '%s' "$commit" | cut -c1-7)
  done <<EOF
$targets
EOF
  [ "$kind" = review ] && [ "$unknown" = 0 ] && [ "$dirty" = 0 ] && exit 0
fi

case $kind in
  review)
    owner="slipway: no clean review report is saved for ${short:-the commit this publishes}, so the reviews may not have run. Allow it only if you said to skip the reviews."
    if [ "$unknown" = 0 ]; then
      agent="slipway, Review report: no clean review report is saved for $short, a commit this pushes or merges. Run the reviewers in review.md, show the owner the report table, save it as $report with at least one ✅ and no ❌; then run the command again."
    else
      agent="slipway, Review report: the guard couldn't tell which commits this pushes or merges. Run the push or merge on its own, as one plain command from inside the repo: git push [remote] [branch...] or gh pr merge <number>; then save the review report for each commit."
    fi
    agent="$agent Only if the owner said to skip the reviews, put SLIPWAY_NO_REVIEW=1 in front as well; the owner is then asked to confirm." ;;
  waived)
    owner="slipway: this pushes or merges ${short:-a commit} with the reviews skipped. Allow it only if you said to skip the reviews."
    agent="slipway, Review report: the reviews were skipped for this push or merge, so the owner is asked to confirm."
    [ "$(slipway_host)" = codex ] && agent="slipway, Review report: the reviews were skipped for this push or merge, and Codex can't ask the owner to confirm, so it is refused. The owner can run it themself." ;;
  push)
    owner="slipway: this pushes, merges or deletes a branch on the remote. Allow it if you asked for it, or if reviews are clean and every required case passes."
    agent="slipway, Outward actions: this pushes, merges or deletes a branch on the remote. Run it only when the owner asked for it, or when reviews are clean and every required case passes; then put SLIPWAY_OK=1 in front of the command." ;;
  owner)
    owner="slipway: this acts on GitHub (an issue, comment, pull request, release or setting). Allow it only if you asked for it."
    agent="slipway, Outward actions: this acts on GitHub (an issue, comment, pull request, release or setting). Run it only when the owner asked for this action; then put SLIPWAY_OK=1 in front of the command." ;;
  force)
    owner="slipway: this rewrites history, or deletes or exposes something on GitHub. Allow it only if you asked for exactly this."
    agent="slipway, Outward actions: this rewrites history, or deletes or exposes something on GitHub. Run it only when the owner asked for exactly this; then put SLIPWAY_OK=1 in front of the command." ;;
  pushnoverify)
    owner="slipway: this pushes to the remote and skips git hooks. Allow it only if you asked for it, or reviews are clean and every required case passes, and you know why the hook is skipped."
    agent="slipway, Outward actions and Check before done: this pushes to the remote and skips git hooks. Run it only when the owner asked for it, or when reviews are clean and every required case passes, and only for a deliberate reason you tell the owner; then put SLIPWAY_OK=1 in front of the command." ;;
  noverify)
    owner="slipway: this skips git hooks. Allow it only for a deliberate, stated reason."
    agent="slipway, Check before done: keep git hooks on. Skip one only for a deliberate reason, stated in the commit message (for a push, tell the owner); then put SLIPWAY_OK=1 in front of the command." ;;
  *) exit 0 ;;
esac

if [ "$(slipway_host)" = codex ]; then
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$agent"
else
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s","additionalContext":"%s"}}\n' "$owner" "$agent"
fi
