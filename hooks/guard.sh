#!/bin/sh
# PreToolUse on Bash: applies the Outward actions and Check before done rules.
# Claude Code asks the owner. Codex rejects "ask" and runs the tool anyway, so there the guard denies.
# Either way, a command the rules allow runs when it starts with SLIPWAY_OK=1.

. "$(dirname "$0")/lib.sh"

input=$(cat)
case $input in *git* | *gh*) ;; *) exit 0 ;; esac

kind=$(printf '%s' "$input" | awk '
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

function rank(k) { return k == "force" ? 5 : k == "owner" ? 4 : k == "pushnoverify" ? 3 : k == "noverify" ? 2 : k == "push" ? 1 : 0 }
function flag(k) { if (rank(k) > rank(found)) found = k }
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
function check(depth,    envskip, i, ok, w, cmd, j, s, a, group, act, method, fields, graphql, mutation, hooksoff, k, dry) {
  if (nw == 0) return
  i = 1; ok = 0; envskip = 0
  while (i <= nw) {
    w = words[i]
    if (w ~ /^[A-Za-z_][A-Za-z0-9_]*=/) {
      if (w == "SLIPWAY_OK=1") ok = 1
      if (w ~ /^(HUSKY=0|LEFTHOOK=0|SKIP=.+)$/) envskip = 1
      i++; continue
    }
    if (w ~ /^(if|then|do|else|elif|while|until|!|time|nohup|builtin|command|exec|noglob|nocorrect)$/) { i++; continue }
    if (w == "sudo") { i++; while (i <= nw && words[i] ~ /^-/) i += words[i] ~ /^-[ugChpUrtD]$/ ? 2 : 1; continue }
    if (w == "env") {
      i++
      while (i <= nw && (words[i] ~ /^-/ || words[i] ~ /^[A-Za-z_][A-Za-z0-9_]*=/)) {
        if (words[i] == "SLIPWAY_OK=1") ok = 1
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
  if (i > nw || ok) return
  cmd = words[i]; sub(/.*\//, "", cmd)

  if (cmd ~ /^(sh|bash|zsh|dash)$/) {
    for (k = i + 1; k < nw; k++) if (words[k] ~ /^-[A-Za-z]*c[A-Za-z]*$/) { if (depth < 4) { s = words[k + 1]; nw = 0; scan(s, depth + 1) } return }
    return
  }

  if (cmd == "git") {
    j = i + 1; hooksoff = envskip
    while (j <= nw && words[j] ~ /^-/) {
      if (words[j] ~ /^(-C|-c|--git-dir|--work-tree|--namespace|--super-prefix|--config-env)$/) {
        if (words[j] == "-c" && words[j + 1] ~ /^core\.hooks[Pp]ath=/) hooksoff = 1
        j += 2
      } else j++
    }
    s = words[j]
    if (s == "subtree" && words[j + 1] == "push") { flag("push"); return }
    if (s == "push") {
      k = "push"; dry = 0
      for (a = j + 1; a <= nw; a++) {
        w = words[a]
        if (w == "--dry-run" || short_has(w, "n")) dry = 1
        if (w ~ /^--force/ || w == "--mirror" || w ~ /^\+./ || short_has(w, "f")) k = "force"
        if (w == "--no-verify") hooksoff = 1
      }
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
    j = i + 1
    while (j <= nw && words[j] ~ /^-/) j += words[j] ~ /^(-R|--repo|--hostname)$/ ? 2 : 1
    group = words[j]; act = words[j + 1]
    if ((group == "pr" && act ~ /^(merge|update-branch)$/)) flag("push")
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
END { found = ""; scan(command_of(json), 0); print found }
')

case $kind in
  push)
    owner="slipway: this pushes, merges or deletes a branch on the remote. Allow it if you asked for it, or if reviews are clean and every case passes."
    agent="slipway, Outward actions: this pushes, merges or deletes a branch on the remote. Run it only when the owner asked for it, or when reviews are clean and every case passes; then put SLIPWAY_OK=1 in front of the command." ;;
  owner)
    owner="slipway: this acts on GitHub (an issue, comment, pull request, release or setting). Allow it only if you asked for it."
    agent="slipway, Outward actions: this acts on GitHub (an issue, comment, pull request, release or setting). Run it only when the owner asked for this action; then put SLIPWAY_OK=1 in front of the command." ;;
  force)
    owner="slipway: this rewrites history, or deletes or exposes something on GitHub. Allow it only if you asked for exactly this."
    agent="slipway, Outward actions: this rewrites history, or deletes or exposes something on GitHub. Run it only when the owner asked for exactly this; then put SLIPWAY_OK=1 in front of the command." ;;
  pushnoverify)
    owner="slipway: this pushes to the remote and skips git hooks. Allow it only if you asked for it, or reviews are clean and every case passes, and you know why the hook is skipped."
    agent="slipway, Outward actions and Check before done: this pushes to the remote and skips git hooks. Run it only when the owner asked for it, or when reviews are clean and every case passes, and only for a deliberate reason you tell the owner; then put SLIPWAY_OK=1 in front of the command." ;;
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
