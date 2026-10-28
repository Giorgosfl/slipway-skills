# slipway-skills

Reusable rules and skills for the whole life of an app, product or server: starting it, developing and refactoring it, testing, reviewing, shipping and maintaining it.

A slipway is the ramp where a ship is built and launched.

## Rules

The rules live in [`rules/`](rules/), one file per stage. A sub file holds rules that apply only to one kind of project.

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

The rules build on seven skills and tools: DOX, ponytail, Matt Pocock's skills, impeccable, Context7, security-audit-skill and i-have-adhd. [`RESOURCES.md`](RESOURCES.md) lists what each one gives a consumer project.

## Changing the rules

Rules are added, edited and removed one at a time. [`AGENTS.md`](AGENTS.md) holds the checks every rule goes through and how each change is made.

Skill names will start with `slipway-` so they never clash with other installed skills.
