---
name: slipway-rules
description: Pick and apply the slipway rule file for the stage of work at hand. Use when starting a session, writing or refactoring code, writing or running tests, reviewing a change, merging or releasing, fixing bugs, or deciding how to work with the owner.
---

# slipway-rules

The rules live in `rules/` at the plugin root: `../../rules/` from this file, or `${CLAUDE_PLUGIN_ROOT}/rules/` in Claude Code. Read the file for the stage you're in, follow every rule in it, and re-read it when the stage changes.

| Stage | Read |
|---|---|
| Starting a session or a project | `start.md` |
| Writing or refactoring code | `develop.md`, plus a sub file below when it fits |
| Writing or running tests and test cases | `test.md` |
| Reviewing a change before a merge | `review.md` |
| Merging, versioning, releasing | `ship.md`, plus a sub file below when it fits |
| Fixing bugs, filing issues, cleaning up | `maintain.md` |
| Reporting to the owner, asking, handing off work | `working-style.md` |

Sub files apply only to one kind of project:

| Sub file | Applies when |
|---|---|
| `develop.react.md` | The code is React or React Native |
| `develop.ui.md` | The app has a user interface |
| `ship.store.md` | The app ships through an app store |
| `ship.website.md` | The product has a website |

- `working-style.md` applies in every stage.
- A rule that names another rule, such as "the Outward actions rule", means that rule in its own file; read it there.
- Rules that build on another skill name it on a "Today…" line; `slipway-setup` installs those skills.
- A slipway hook pauses outward git and GitHub commands. Put `SLIPWAY_OK=1` in front of one only when the rules allow it: the owner asked for it; or, for a push, merge or branch clean-up, reviews are clean and every case passes; or, for a skipped git hook, a deliberate reason is stated in the commit message.
- Check it: before calling a stage done, every rule in its file was followed, or the owner was told which one wasn't and why.
