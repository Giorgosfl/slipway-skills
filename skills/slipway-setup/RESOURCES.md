# Resources slipway-setup checks

Commands are today's; step 4 of the skill confirms each against the resource's own install doc before running it. Skill folders: Claude Code reads `~/.claude/skills` (or `$CLAUDE_CONFIG_DIR/skills` when that's set) and the project's `.claude/skills`; Codex reads `$CODEX_HOME/skills` (by default `~/.codex/skills`), `~/.agents/skills`, and the project's `.agents/skills` and `.codex/skills`.

## DOX

- Gives: the `AGENTS.md` hierarchy agents read before editing and update after.
- Source: https://github.com/agent0ai/dox (MIT). Install doc: its README.
- Level: project.
- Found when: the project's `AGENTS.md` contains the DOX template (its `# DOX framework` heading).
- Install, both apps: fetch `https://raw.githubusercontent.com/agent0ai/dox/main/AGENTS.md` and add it to the project's `AGENTS.md` inside a `slipway:dox` block, creating the file if needed. Then follow the template's own last step: build the child `AGENTS.md` index.

## ponytail

- Gives: the simplicity review, the smallest change that fully solves the task.
- Source: https://github.com/DietrichGebert/ponytail (MIT). Install doc: its README → Install.
- Found when: `ponytail` is an installed plugin, or a `ponytail` folder is in one of the app's skill folders.
- Install, Claude Code: `claude plugin marketplace add DietrichGebert/ponytail`, then `claude plugin install ponytail@ponytail`.
- Install, Codex: `codex plugin marketplace add DietrichGebert/ponytail`, then `codex plugin add ponytail@ponytail`; the owner then trusts its hooks in `/hooks`.

## Matt Pocock's skills

- Gives: `grilling`, `code-review`, `setup-matt-pocock-skills` (issue tracker, triage labels, domain docs) and more.
- Source: https://github.com/mattpocock/skills (MIT). Install doc: its README → Installation.
- Found when: `mattpocock-skills` is an installed plugin, or `grilling` and `code-review` folders are in one of the app's skill folders.
- Install, Claude Code: `claude plugin install mattpocock-skills@claude-plugins-official`.
- Install, Codex: `codex plugin marketplace add mattpocock/skills`, then `codex plugin add mattpocock-skills@mattpocock`.
- After: offer to run `setup-matt-pocock-skills` in the project.

## impeccable

- Gives: the UI critique and audit, and the `DESIGN.md` design doc.
- Source: https://github.com/pbakaus/impeccable (Apache 2.0). Install doc: its README → Installation.
- Found when: `impeccable` is an installed plugin, or an `impeccable` folder is in one of the app's skill folders.
- Install, both apps: `npx impeccable install --providers=claude --scope=global` (Claude Code) or `--providers=codex` (Codex). It also adds its hooks: with `--scope=global` for Claude Code it merges them into `${CLAUDE_CONFIG_DIR:-~/.claude}/settings.json`; for a project install, into `.claude/settings.local.json` or `.codex/hooks.json`, plus `.impeccable/`. Record a created file as `files` and a changed one as `edited`. In Codex, the owner then approves its hook in `/hooks`.

## Context7

- Gives: current docs for any library, so stack reviews check today's best practice.
- Source: https://github.com/upstash/context7 (MIT). Install doc: its README → Installation.
- Found when: an MCP server named `context7` is listed by `claude mcp list` or `codex mcp list`, or the `ctx7` CLI runs and a docs skill that uses it is installed.
- Install, Claude Code: `npx ctx7 setup --claude --cli`; it signs in, installs a skill and writes a rule file into `${CLAUDE_CONFIG_DIR:-~/.claude}/rules/`. Record `undo: "npx ctx7 remove --claude --cli -y"`.
- Install, Codex: add the MCP server `https://mcp.context7.com/mcp` with `codex mcp add`, as Context7's client docs describe. Record it as an `mcp` change.

## security-audit-skill

- Gives: the security review, a focused review of a change or a full audit when asked.
- Source: https://github.com/cloudflare/security-audit-skill (MIT). Install doc: its README → Installation.
- Found when: a `security-audit` folder is in one of the app's skill folders.
- Install, both apps: `npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit --global --agent claude-code -y`, or `--agent codex` in Codex. Record `undo: "npx skills remove security-audit --global --agent claude-code -y"`, with the same `--agent` as the install.

## i-have-adhd

- Gives: replies that lead with the next action, numbered steps, short status and one next step.
- Source: https://github.com/ayghri/i-have-adhd (MIT). Install doc: its `INSTALL.md`.
- Found when: `i-have-adhd` is an installed plugin, or an `i-have-adhd` folder is in one of the app's skill folders.
- Install, Claude Code: `claude plugin marketplace add ayghri/i-have-adhd`, then `claude plugin install i-have-adhd@i-have-adhd`.
- Install, Codex: `codex plugin marketplace add ayghri/i-have-adhd --ref main`, then `codex plugin add i-have-adhd@i-have-adhd`.
