---
name: slipway-setup
description: Check that the skills and tools slipway's rules build on are installed for this agent app and project, and install the missing ones with the owner's OK. Use when setting up slipway in a project, or when a rule needs a resource that isn't installed.
---

# slipway-setup

Makes sure the resources in [RESOURCES.md](RESOURCES.md) are installed, for Claude Code and Codex. The slipway rules build on them, and the slipway-rules skill points to them. Installs only what the owner approves, and records every change so `slipway-uninstall` can undo exactly that and nothing else.

## Steps

1. **Find the app.** You are running in Claude Code or in Codex; use only that app's checks and commands. Cover both only when the owner asks.
2. **Check each resource** with its "Found when" lines in [RESOURCES.md](RESOURCES.md). Mark each one installed or missing.
3. **Ask once.** One interactive prompt, multi-select, listing only the missing resources: what each gives and the command that installs it. Recommend installing all of them. Stop if the owner picks none.
4. **Confirm the command.** Before installing a resource, read its own install doc (linked in RESOURCES.md). If its current command differs from the one listed, use the current one.
5. **Snapshot.** Before each install, note the installed plugins, the MCP servers, the contents of every skill folder the app reads, the user's and the project's agent settings and hook files (`${CLAUDE_CONFIG_DIR:-~/.claude}/settings.json`, `${CODEX_HOME:-~/.codex}/hooks.json` and `config.toml`, the project's `.claude/settings*.json`, `.codex/hooks.json` and `.codex/config.toml`), the user's and the project's Claude `rules/` folders, and any folder the resource's install doc says it writes. For DOX, also list every `AGENTS.md` in the project, since building its index creates new ones. Copy each of those settings and hook files to `~/.slipway/backups/<timestamp>/` first; record a user-level one that changed as an `edited` change in `~/.slipway/installed.json`.
6. **Install** the approved resources one at a time.
7. **Record.** Snapshot again, and write what this install added to the record (below). Anything that existed before stays out of the record.
8. **Verify.** Run the "Found when" checks again. Report each resource as installed, failed or skipped, and any step the owner must take, such as restarting the app.
9. **Hooks.** slipway's own hooks come with the plugin. In Codex, ask the owner to open `/hooks` and trust slipway's hooks and those of every plugin just installed; Codex runs no plugin hook until it's trusted, and again after its hook file changes.

- Install a resource only after the owner's yes for that resource.
- Leave an existing skill folder or plugin as it is; never overwrite it.
- Report a failed install with its error; retry only if the owner asks.

## The record

Two JSON files, one per level, each holding a `changes` list that setup only ever appends to:

- `~/.slipway/installed.json`: plugins, marketplaces, MCP servers, skill folders, and user-level settings or hook files a resource edited, which all belong to the user.
- `.slipway/installed.json` in the project root: changes to project files. Commit it with those changes, so uninstall works from any checkout. Backups of edited files stay in `~/.slipway/backups/` on this machine, since a settings file can hold private values.

```json
{
  "version": 1,
  "changes": [
    {
      "resource": "ponytail",
      "app": "claude-code",
      "kind": "plugin",
      "id": "ponytail@ponytail",
      "marketplace": "ponytail",
      "marketplaceAdded": true,
      "version": "5.3.2",
      "installedAt": "2026-10-28T12:00:00Z"
    },
    {
      "resource": "security-audit-skill",
      "app": "codex",
      "kind": "files",
      "paths": [{ "path": "~/.agents/skills/security-audit", "checksum": "1702934951" }],
      "undo": "npx skills remove security-audit --global --agent codex -y",
      "installedAt": "2026-10-28T12:05:00Z"
    }
  ]
}
```

Each change has one `kind`:

- `plugin`: `id`, `marketplace`, `marketplaceAdded` (true only when setup added the marketplace), and the installed `version`.
- `mcp`: the server `name`.
- `files`: every `path` the install created, each with a `checksum` of what the install left there. For a folder, checksum its sorted file list and contents: `find <path> -type f | LC_ALL=C sort | xargs cat | cksum`.
- `block`: the `file`, the marker `name`, the exact `text` added, and `fileCreated` (true only when setup created the file). For DOX, also the `template` checksum of the DOX template that was installed, which `slipway-update` compares against.
- `edited`: a settings or hook file the install changed but didn't create, such as one a resource merged its hooks into; a user-level one goes in `~/.slipway/installed.json`, a project one in `.slipway/installed.json`. Record the `file`, the `backup` copy from step 5, and a `checksum` of the file after the install.

Add `undo` whenever the resource ships its own removal command.

## Project blocks

Setup marks every text it adds to a project file, so uninstall can take out exactly that:

```markdown
<!-- slipway:dox start -->
…the added text…
<!-- slipway:dox end -->
```

By default, Claude Code reads `AGENTS.md` only when the project has no `CLAUDE.md`, `.claude/CLAUDE.md` or `CLAUDE.local.md`. So when the app is Claude Code and none of those already imports `AGENTS.md`, add a `slipway:claude-import` block holding `@AGENTS.md` to the one that exists (`CLAUDE.md` first), or create `CLAUDE.md` holding only that block. Record it as its own `block` change.
