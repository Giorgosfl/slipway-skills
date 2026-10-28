# Maintain

- **Ideas vs shipped.**
  - Ideas and design notes that haven't shipped go in a docs folder.
  - The agent instruction files (`AGENTS.md`, `CLAUDE.md`) describe only what shipped.
- **Fix the cause everywhere.**
  - When fixing a bug, find its root cause, not only the spot where it showed up.
  - Before changing code, list every place that cause can reach.
  - In an app: every screen, orientation, screen size, theme and state.
  - In code: every caller of the broken piece.
  - Fix all of them in one change.
  - Check each place on the list before calling the bug fixed.
  - File a follow-up issue only for a place you checked and could not fix in this change.
  - Example: a list cut off at the bottom gets fixed on every list, in portrait and landscape, with and without the tab bar.
