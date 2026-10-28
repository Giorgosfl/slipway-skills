---
name: slipway-uninstall
description: Undo what slipway-setup installed, using its record, and nothing else.
disable-model-invocation: true
---

# slipway-uninstall

Removes what `slipway-setup` added, for Claude Code and Codex. It works only from setup's record, so anything the owner had before setup stays untouched.

## Steps

1. **Read the record:** `~/.slipway/installed.json` and the project's `.slipway/installed.json`. With neither file, or no changes in them, say there is nothing to undo and stop.
2. **List the changes,** grouped by resource: what each one is and what removing it takes away.
3. **Ask once.** One interactive prompt, multi-select, listing every change. Recommend removing all of them. Stop if the owner picks none.
4. **Undo each chosen change,** newest first, the way its `kind` says:
   - `plugin`: `claude plugin uninstall <id>`, or `codex plugin remove <id>` in Codex. Then remove the marketplace too, but only when `marketplaceAdded` is true and no installed plugin still comes from it.
   - `mcp`: `claude mcp remove <name>`, or `codex mcp remove <name>`.
   - `files`: run `undo` when the change has one. Then delete each recorded path that still exists and still matches its `checksum`; for one that changed, show the owner what changed and ask first.
   - `block`: delete the text from its start marker to its end marker, both markers included. Delete the file only when `fileCreated` is true and nothing else is left in it.
   - `edited`: run `undo` when the change has one. Otherwise, when the file's checksum still matches the recorded one, copy the `backup` back over it; when it doesn't, or the backup is gone (another machine, a cleaned home folder), show the owner the recorded change and ask first.
5. **Update the record.** Take each undone change out of it. Delete a record file once its list is empty, and its `.slipway` folder once that is empty, along with any backups no change still points to.
6. **Verify.** Check each undone change is gone: the plugin and MCP server no longer listed, the paths gone, the block gone. Report each one as removed, failed or kept, and say when the app needs a restart.

- Undo only what the record lists.
- When a block's text no longer matches the recorded `text`, it was edited since setup: show the owner the difference and ask before deleting it.
- Report a failed removal with its error, and keep its change in the record so a later run can try again.
