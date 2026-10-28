# slipway-skills

This repo holds reusable rules for the whole life of an app, product or server. The rules are for the projects that consume them, never for this repo itself: how this repo works is no reason to change, bend or exempt a rule.

## Layout

- `rules/<category>.md`: one file per stage — `start`, `develop`, `test`, `review`, `ship`, `maintain`, `working-style`.
- `rules/<category>.<scope>.md`: a sub file for rules that apply only to one kind of project, such as `develop.react.md`, `develop.ui.md`, `ship.store.md`, `ship.website.md`. It opens with one line: "Rules from <category>.md that apply only to <scope>."
- Make a new sub file only when a rule truly can't be made agnostic.

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
8. **Borrowed:** from DOX, Matt Pocock's skills or impeccable? Those aren't carried here.
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
- Before renaming or removing a rule, find the rules that name it: `Runner agents` points to `Verdicts`; `Session end` points to `Session status`; `Agent does what it can`, `Session end` and `Autopilot` point to `Outward actions`.

## Working with the owner

- Do exactly the action the owner names: "stage" means `git add`, not commit; "root files" means the root, not `rules/`; "create a repo" means an empty repo.
- When something isn't named, leave it undone and mention it in one line.
- Ask questions through interactive prompts with short options, not long text.
- A "No" or a correction applies from then on, not only to the rule at hand.
