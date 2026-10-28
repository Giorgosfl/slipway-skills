# Resources

The skills and tools every slipway rule and skill builds on. A consumer project installs them, and the rules point to them instead of copying what they already provide.

| Resource | What it gives the consumer | Used by |
|---|---|---|
| [DOX](https://github.com/agent0ai/dox) | A hierarchy of `AGENTS.md` files: read every one from the root down before editing, update the closest one after | start, maintain |
| [ponytail](https://github.com/dietrichgebert/ponytail) | The simplicity review: the smallest change that fully solves the task | develop, review |
| [Matt Pocock's skills](https://github.com/mattpocock/skills) | `grilling` to stress-test decisions, `code-review`, issue tracker and triage-label setup, a glossary and ADRs for domain docs | review, maintain, working-style |
| [impeccable](https://github.com/pbakaus/impeccable) | The UI critique and audit, and the `DESIGN.md` design doc | develop.ui, review |
| [Context7](https://github.com/upstash/context7) | Current docs for any library, so stack reviews check today's best practice | review |
| [security-audit-skill](https://github.com/cloudflare/security-audit-skill) | The security review: a focused review of a change, or a full audit when asked | review |
| [i-have-adhd](https://github.com/ayghri/i-have-adhd) | Replies that lead with the next action: numbered steps, short status, one next step | working-style |

## Licences

Checked against each repo's `LICENSE` file on 2026-10-28: impeccable is Apache 2.0, and DOX, ponytail, Matt Pocock's skills, Context7, security-audit-skill and i-have-adhd are MIT. Both allow linking, installing and copying, as long as the licence and copyright notice travel with any copied content (`rules/develop.md` → Licence provenance).
