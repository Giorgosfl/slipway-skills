# Develop

- **Gotchas file.**
  - Keep a gotchas file in the repo, grouped by area.
  - Add a line when a trap costs real time.
  - Each line names the trap and its issue number.
  - Longer detail goes in a separate file for that area.
  - Remove a line once it is no longer true.
  - Read an area's section before working in that area.
- **Atomic.**
  - Every function, type, module and file has one responsibility.
  - Each has one reason to change.
  - A file that mixes concerns, such as routing, data and rendering, gets split.
  - A unit past about 150 lines is a signal to extract.
