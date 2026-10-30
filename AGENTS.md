# slipway-skills

This repo holds reusable rules for the whole life of an app, product or server. The rules are for the projects that consume them, never for this repo itself: how this repo works is no reason to change, bend or exempt a rule.

The rules build on the skills and tools listed in `RESOURCES.md`. Point to a resource instead of copying what it provides.

## Layout

- `rules/<category>.md`: one file per stage — `start`, `develop`, `test`, `review`, `ship`, `maintain`, `working-style`.
- `rules/<category>.<scope>.md`: a sub file for rules that apply only to one kind of project, such as `develop.react.md`, `develop.ui.md`, `ship.store.md`, `ship.website.md`. It opens with one line: "Rules from <category>.md that apply only to <scope>."
- Make a new sub file only when a rule truly can't be made agnostic.
- `skills/<name>/SKILL.md`: the plugin's skills, `slipway-rules`, `slipway-setup`, `slipway-update` and `slipway-uninstall`. Every skill name starts with `slipway-`. `slipway-update` reads slipway's version from `.claude-plugin/plugin.json` on GitHub, so a release isn't visible to it until both manifests carry the new `version`.
- `hooks/hooks.json` and `hooks/*.sh`: the hooks that apply the rules, shared by Claude Code and Codex. `hooks/lib.sh` holds their shared helpers.
- `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`: the plugin and its marketplace; Codex reads the same marketplace file.
- `.codex-plugin/plugin.json`: Codex's manifest, which adds its `interface` fields.
- `tests/hooks.test.sh`: runs every hook the way each app calls it.

## Plugin and hooks

One `hooks/hooks.json` serves both apps, so it uses only what both accept:

- Top-level keys: only `description` and `hooks`. Handler fields: only `type`, `command` and `timeout`; Codex ignores `if`, `args` and `onFailure`, and Claude's marketplace validation has rejected Codex's `commandWindows`.
- Neither manifest gets a `hooks` or `skills` field: both apps load `hooks/hooks.json` and `skills/` on their own, and a `hooks` field makes Claude Code report a duplicate.
- Commands read the plugin root from the environment, `sh "$CLAUDE_PLUGIN_ROOT/hooks/x.sh"`, so a path with odd characters can't break the command.
- SessionStart prints plain text; both apps add it to the model's context.
- The hooks tell the apps apart by `PLUGIN_DATA`, which only Codex sets; Claude Code sets `CLAUDE_PLUGIN_DATA`.
- PreToolUse: Claude Code gets `permissionDecision: "ask"`, with a `permissionDecisionReason` written for the owner and an `additionalContext` written for the agent. Claude Code shows the reason in the permission prompt; in a `-p` run with no one to answer, it denies the call and the agent reads the reason in the tool result, so the owner text must read sensibly to the agent too. Codex rejects "ask" and would run the tool anyway, and its `additionalContext` arrives only after the tool ran, so Codex gets "deny", with a reason written for the agent. Never mark the guard `async`.
- The guard parses the command itself, in `awk`, in a way that works with BSD awk, mawk, gawk and busybox: it reads only `tool_input.command`; splits it into simple commands at `;`, `&`, `|`, newlines and subshells; skips comments and heredoc bodies; looks inside `$(…)`, backticks and `sh -c`; skips wrappers such as `sudo`, `env`, `timeout` and `xargs`; and looks at the real git or gh subcommand, `git subtree push` included. Hook-skipping variables (`HUSKY=0`, `LEFTHOOK=0`, `SKIP=`) count as a skipped hook. It's a guard rail for agents that follow the rules, not a security boundary: a long tail of shell forms will always get past it.
- It sorts what it finds into six kinds, each with its own reason: `push` (push, merge, branch delete: the clean-reviews exception applies), `owner` (other GitHub writes: only when the owner asked), `force` (history rewrites, deletes, visibility changes: only when the owner asked for exactly this), `noverify` (skipped git hooks), `pushnoverify` (a push that skips hooks: both conditions) and `review` (below). A simple command that starts with `SLIPWAY_OK=1` passes, except one that publishes commits: a push that isn't only branch deletes, `git subtree push`, `gh pr merge` (with or without `-d`) and `gh pr update-branch`. That becomes `review`: it passes only when, for each commit it publishes, `<git common dir>/slipway/reviews/<commit>.md` has at least one ✅ and no ❌ in its Result column. The commits are each pushed refspec that isn't a delete (HEAD when none is named), or the pull request's head (`gh pr view`, with its number and `-R`), read in the session's `cwd`. It fails closed: the guard asks unless the push or merge is the only command in the line (no `cd`, `commit` or `checkout` before it, no `sh -c`), has no git or gh global option such as `-C`, and has no push option that adds refs or takes a value (`--all`, `--tags`, `--mirror`, `-o`, `--repo`, a bare `:`). `git subtree push` always asks, since the commit it pushes isn't named. Other commands marked `SLIPWAY_OK=1` pass inside `sh -c` too. With `SLIPWAY_NO_REVIEW=1` as well it becomes `waived`, which outranks `review` in a chain: Claude Code asks the owner, Codex refuses it, since Codex can't ask and its sandbox can't write the report in `.git`.
- Stop: Claude Code gets `hookSpecificOutput.additionalContext`, which it shows as feedback, not as an error. Codex accepts only `{"decision":"block","reason":"…"}` or nothing.
- SessionStart records the repo's state, keyed by session and by the repo's shared git folder, and the list of worktrees that already exist. Stop sums the session's own checkout plus every worktree made since, and asks only when that sum differs from the session's start and from its last ask: work in a worktree the session made counts, other sessions' worktrees don't. Both read `cwd` from stdin and keep their state in the plugin's data folder; without one, SessionStart records nothing and Stop stays silent. SessionStart prints first and records the state in the background. git runs with `GIT_OPTIONAL_LOCKS=0`, so the hooks never take another session's index lock, and `git diff` runs with `--no-ext-diff --no-textconv`, so no user diff program runs or changes the sum. Stop marks its own ask with a `.asked` file, so only the continuation it caused counts as checked; one that `/goal` or another plugin started gets the normal check.
- Matchers use only letters, digits, `_` and `|`, which both apps read the same way: `startup|resume|clear|compact|fork` and `Bash`. PowerShell is left out: `SLIPWAY_OK=1` isn't valid PowerShell.
- On Windows, Claude Code runs the hooks in Git Bash, and without it they fail with an error notice; Codex runs them in the session's shell, PowerShell by default (`cmd.exe` only as a fallback), which can't run them.
- Codex runs a plugin hook only after the owner trusts it in `/hooks`, and again after `hooks.json` changes. Changing a script needs no new trust.
- Bump `version` in both manifests, in the same commit, for every release.
- Check a change with `sh tests/hooks.test.sh` and `claude plugin validate . --strict`. Add a test case for every command shape the guard should catch or let through.

## Rule format

```markdown
- **Title.**
  - One short, simple line per point.
  - Example: one concrete case.
  - Check it: how to tell the rule was followed.
```

- A bold title, then sub-bullets: one point per line, plain words, readable on its own.
- Steps in order when the rule is a process, planning step first.
- No source tags such as `(project-name)`: where a rule came from doesn't matter.

## Checks for every rule

Run all of them on every rule you add or edit, in this order.

1. **Source tag:** remove it.
2. **Agnostic:** would it hold for a Swift iOS app, a React Native app, a Windows desktop app, a Chrome extension and a server? Show a short table per target. Generalize what's too specific, or move the rule to a sub file.
3. **Fixed names:** a path, tool, skill, model ID, library or vendor. Cut it, even as an example, unless it's the point of the rule; then name it once, on a "Today…" line, so only that line changes when it goes stale.
4. **Owner-specific:** personal devices, folders, names, or one project's workflow (issue numbers, a build service, a team habit). Replace with plain words.
5. **Overlap and conflict:** with every rule already in `rules/`, and with the agent tool's own behavior. Join overlapping rules into one. A rule that allows acting "without asking" stays within the Outward actions rule.
6. **No-op:** an agent already does this without being told? Drop it, or keep it only as the anchor line of a larger rule.
7. **Wording:** a positive target, not a bare "never"; a done-state someone can check.
8. **Borrowed:** does one of the resources in `RESOURCES.md` already provide it? Rules a resource already provides aren't copied; consumers get them from the resource.
9. **Short lines:** split any long line into meaningful short ones, dropping nothing.
10. **One home:** exactly one category or sub file, where the rule's work actually happens. Never copy a rule into a second file.
11. **Outcome over mechanism:** say what must be achieved, not which script or tool must do it.
12. **Stands alone:** every line makes sense with no context. Replace jargon ("composition root", "RPC", "ADR") with plain words, and add a few words of why where the what isn't obvious.
13. **Verdict:** do you agree? Is it sound engineering and current best practice? Check the current docs for any library the rule names. Say what's missing or overdone, and propose changes.
14. **Groom:** rewrite around the rule's intent: steps in order, app and code variants where they differ, one example, a "Check it:" line.

## Working on rules

- One rule per change. Run the checks, write the rule in its home, and stage it.
- Show the owner the rule, what it means in plain words with a real example, the check results and your verdict.
- Then ask through an interactive prompt: commit and go to the next rule, or change it. Put the recommended option first.
- Commit only on a yes, one commit per rule: `Add rule: <title>`, `Update rule: <title>`, `Remove rule: <title>`.
- Never push unless the owner says so.
- When the owner says "groom", rewrite the rule around its intent (check 14).
- When the owner says "explain", explain plainly, with a real example from a project.
- Before renaming or removing a rule, find the rules that name it: `Runner agents` points to `Verdicts`; `Session end` points to `Session status`; `Agent does what it can`, `Session end` and `Autopilot` point to `Outward actions`. The hooks and `slipway-rules` quote rule titles too: grep `hooks/` and `skills/` for the title.

## Working with the owner

- Do exactly the action the owner names: "stage" means `git add`, not commit; "root files" means the root, not `rules/`; "create a repo" means an empty repo.
- When something isn't named, leave it undone and mention it in one line.
- Ask questions through interactive prompts with short options, not long text.
- A "No" or a correction applies from then on, not only to the rule at hand.
