# slipway-skills

Reusable rules and skills for the whole life of an app, product or server: starting it, developing and refactoring it, testing, reviewing, shipping and maintaining it. One plugin for Claude Code and Codex.

A slipway is the ramp where a ship is built and launched.

## What you get

- **Rules:** curated engineering rules, one file per stage, in [`rules/`](rules/).
- **Hooks** that apply them:
  - at session start, they point the agent to the rules and flag missing resources;
  - before a shell command, they pause outward git and GitHub actions: pushes, force pushes, merges, branch deletes, issues, comments, pull requests, releases, settings, `gh api` writes and skipped git hooks. Claude Code asks you; Codex, which can't ask, refuses the command. When the rules allow the action (the owner asked for it; or, for a push, merge or branch clean-up, reviews are clean and every case passes; or, for a skipped git hook, a deliberate reason is stated in the commit message), the agent runs it again with `SLIPWAY_OK=1` in front. In Claude Code, an allow rule you already have, such as `Bash(git push *)`, doesn't match that form; add `Bash(SLIPWAY_OK=1 git push *)` too if you want those to run without a prompt. The guard is a guard rail for agents that follow the rules, not a security boundary;
  - before the agent finishes, they ask for one verification pass when the repo changed during the session.
- **Skills:**
  - `slipway-rules` picks the rule file for the task at hand.
  - `slipway-setup` checks the [resources](RESOURCES.md) the rules build on and installs the missing ones, after asking.
  - `slipway-update` checks slipway and those resources for updates, and applies the ones you pick.
  - `slipway-uninstall` undoes exactly what setup installed. Only you can start it.

## Install

**Claude Code:**

```bash
claude plugin marketplace add Giorgosfl/slipway-skills
```

```bash
claude plugin install slipway@slipway-skills
```

Or, inside Claude Code 2.1.275 or later, in one step: `/plugin install slipway --marketplace Giorgosfl/slipway-skills`. Then start a session in your project and run `/slipway:slipway-setup`. Run `/slipway:slipway-update` now and then to pick up new versions.

**Codex:**

```bash
codex plugin marketplace add Giorgosfl/slipway-skills
```

```bash
codex plugin add slipway@slipway-skills
```

Then open `/hooks` in Codex and trust slipway's hooks; Codex runs no plugin hook until you do. Then ask Codex to run the slipway-setup skill in your project.

The hooks are POSIX shell scripts. They run on macOS and Linux in both apps. On Windows they need Git for Windows (Git Bash) in Claude Code: without it, every hook fails with an error notice, and the guard watches only the Bash tool, not PowerShell. Codex on Windows runs hooks in the session's shell, PowerShell by default, which can't run them, so don't trust slipway's hooks there; the rules and skills still work.

## Uninstall

1. In a session, start the slipway-uninstall skill to undo what setup installed: `/slipway:slipway-uninstall` in Claude Code; in Codex, type `$` and pick slipway-uninstall from the list, since Codex keeps it out of the model's reach.
2. Remove the plugin: `claude plugin uninstall slipway@slipway-skills`, or `codex plugin remove slipway@slipway-skills`.

## Rules

| File | What it holds |
|---|---|
| `rules/start.md` | Setting up a project or a session |
| `rules/develop.md` | Writing and refactoring code |
| `rules/develop.react.md` | React code only |
| `rules/develop.ui.md` | Apps with a user interface only |
| `rules/test.md` | Tests and test cases |
| `rules/review.md` | Reviews before a merge |
| `rules/ship.md` | Merging, versioning and releasing |
| `rules/ship.store.md` | Apps sold through an app store only |
| `rules/ship.website.md` | Products with a website only |
| `rules/maintain.md` | Bugs, issues and keeping things clean |
| `rules/working-style.md` | How agents work with the owner |

## Resources

The rules build on seven skills and tools: DOX, ponytail, Matt Pocock's skills, impeccable, Context7, security-audit-skill and i-have-adhd. [`RESOURCES.md`](RESOURCES.md) lists what each one gives a project; `slipway-setup` installs them.

## Contributing

Rules are added, edited and removed one at a time. [`AGENTS.md`](AGENTS.md) holds the checks every rule goes through, and how the plugin and its hooks are built. Run `sh tests/hooks.test.sh` (it needs `python3`) after changing a hook.

## Licence

MIT. See [`LICENSE`](LICENSE).
