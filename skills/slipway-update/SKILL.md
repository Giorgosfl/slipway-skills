---
name: slipway-update
description: Check whether slipway itself or the resources its rules build on have updates, and apply the ones the owner picks. Use when the owner asks to update slipway or its skills, or asks whether anything is out of date.
---

# slipway-update

Checks slipway and every installed resource in [`../slipway-setup/RESOURCES.md`](../slipway-setup/RESOURCES.md) for updates, for Claude Code and Codex. Checking changes nothing; updating happens only for what the owner picks, and keeps setup's record current so `slipway-uninstall` still undoes exactly what was installed.

## Steps

1. **Find the app,** as in slipway-setup: Claude Code or Codex, and only that app's commands.
2. **Find what's installed:** slipway itself, plus each resource that slipway-setup's "Found when" checks find. Read setup's record (`~/.slipway/installed.json` and the project's `.slipway/installed.json`) to know how each one was installed.
3. **Check each one for an update,** without installing anything:
   - **A plugin:** read the installed version from `claude plugin list --json`, or `codex plugin list --json` in Codex. Read the latest from the marketplace it was installed from, the part of its id after `@`, without running any update or upgrade command: find the marketplace's source repo (`claude plugin marketplace list` shows it; in Codex it's the `source` under `[marketplaces.<name>]` in `${CODEX_HOME:-~/.codex}/config.toml`), read its `marketplace.json` on its default branch, or the ref it's pinned to, and follow the plugin's entry to its `plugin.json` (at the entry's pinned `sha` or `ref`, when it has one) for `version`. In Codex, `codex plugin marketplace upgrade` reinstalls every installed plugin from that marketplace, so it belongs in step 8, never here.
   - **Skill folders** (`files` in the record): compare each installed `SKILL.md` with the same file on the resource's default branch.
   - **The DOX block:** compare a checksum of the current DOX template with the `template` checksum setup recorded. Never compare it with the block itself: building the index and recording owner preferences change the block on purpose.
   - **An MCP server that runs remotely,** like Context7's: it's always current; check only a local CLI it installed, such as `ctx7`, against its latest published version.
   - **slipway itself:** compare its installed version with `version` in `.claude-plugin/plugin.json` on the default branch of https://github.com/Giorgosfl/slipway-skills.
4. **Report** one line per item: installed version, latest version, and "update available" or "up to date". When a resource's changelog or release notes are easy to find, add one line on what changed. Stop here when everything is up to date.
5. **Ask once.** One interactive prompt, multi-select, listing only what has an update. Recommend updating all of it. Stop if the owner picks none.
6. **Confirm the command.** Before updating a resource, read its own install doc for its update command, and use that when it differs from the ones below.
7. **Snapshot,** as in setup step 5, including backups of the project files the update may change.
8. **Update** each picked item:
   - **A Claude Code plugin:** `claude plugin marketplace update <marketplace>`, then `claude plugin update <id>`.
   - **A Codex plugin:** `codex plugin marketplace upgrade <marketplace>`, which reinstalls every installed plugin from that marketplace at its new version; then `codex plugin list --json` to confirm. Tell the owner first when the marketplace holds more than the picked plugin.
   - **Skill folders:** the resource's own update command, or its install command again.
   - **The DOX block:** first show the owner how the block's template sections differ from the new template. Then update only the template's own sections, and keep the project's `## User Preferences` and `## Child DOX Index` sections as they are. Record the new `template` checksum.
9. **Update the record.** For each updated change, write its new `version`, `text` or `checksum`, and add any path the snapshot shows the update created, so uninstall still matches what's installed.
10. **Verify.** Run the checks from step 3 again and report each item as updated, failed or skipped.
11. **Restart and trust.** Tell the owner when the app needs a restart. In Codex, ask them to open `/hooks` and trust again any updated plugin whose hooks changed, slipway's included.

- Update an item only after the owner's yes for it.
- Report a failed update with its error, and leave its record entry as it was.
