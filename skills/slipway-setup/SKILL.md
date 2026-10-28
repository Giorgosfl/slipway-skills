---
name: slipway-setup
description: Check that the skills and tools slipway's rules build on are installed for this agent app and project, and install the missing ones with the owner's OK. Use when setting up slipway in a project, or when a rule needs a resource that isn't installed.
---

# slipway-setup

Makes sure the resources in [RESOURCES.md](RESOURCES.md) are installed, for Claude Code and Codex. Installs only what the owner approves, and records every change so `slipway-uninstall` can undo exactly that and nothing else.

## Steps

1. **Find the app.** You are running in Claude Code or in Codex; use only that app's checks and commands. Cover both only when the owner asks.
2. **Check each resource** with its "Found when" lines in [RESOURCES.md](RESOURCES.md). Mark each one installed or missing.
3. **Ask once.** One interactive prompt, multi-select, listing only the missing resources: what each gives and the command that installs it. Recommend installing all of them. Stop if the owner picks none.
4. **Confirm the command.** Before installing a resource, read its own install doc (linked in RESOURCES.md). If its current command differs from the one listed, use the current one.
5. **Snapshot.** Before each install, note the installed plugins, the MCP servers, and the contents of every skill folder the app reads.
6. **Install** the approved resources one at a time.
7. **Record.** Snapshot again, and write what this install added to the record (below). Anything that existed before stays out of the record.
8. **Verify.** Run the "Found when" checks again. Report each resource as installed, failed or skipped, and any step the owner must take, such as trusting hooks in Codex's `/hooks` or restarting the app.

- Install a resource only after the owner's yes for that resource.
- Leave an existing skill folder or plugin as it is; never overwrite it.
- Report a failed install with its error; retry only if the owner asks.

## The record

Two JSON files, one per level, each holding a `changes` list that setup only ever appends to:

- `~/.slipway/installed.json`: plugins, marketplaces, MCP servers and skill folders, which belong to the user.
- `.slipway/installed.json` in the project root: changes to project files. Commit it with those changes, so uninstall works from any checkout.

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
      "installedAt": "2026-10-28T12:00:00Z"
    },
    {
      "resource": "security-audit-skill",
      "app": "codex",
      "kind": "files",
      "paths": ["~/.agents/skills/security-audit"],
      "undo": "npx skills remove security-audit",
      "installedAt": "2026-10-28T12:05:00Z"
    }
  ]
}
```

Each change has one `kind`:

- `plugin`: `id`, `marketplace`, and `marketplaceAdded` (true only when setup added the marketplace).
- `mcp`: the server `name`.
- `files`: every `path` the install created.
- `block`: the `file`, the marker `name`, the exact `text` added, and `fileCreated` (true only when setup created the file).

Add `undo` whenever the resource ships its own removal command.

## Project blocks

Setup marks every text it adds to a project file, so uninstall can take out exactly that:

```markdown
<!-- slipway:dox start -->
…the added text…
<!-- slipway:dox end -->
```

Claude Code reads `CLAUDE.md`, not `AGENTS.md`. When the app is Claude Code and `CLAUDE.md` doesn't already import `AGENTS.md`, add a `slipway:claude-import` block holding `@AGENTS.md` to `CLAUDE.md`, creating the file if needed, and record it as its own `block` change.
