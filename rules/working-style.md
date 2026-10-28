# Working style

- **Hand-off brief.**
  - Every hand-off to another session or agent carries a brief.
  - The brief gives the task as the symptom, not the fix.
  - It says when the work is done.
  - It names the base commit to start from.
  - It gives the agent its own worktree and test device.
  - It lists what to read first.
  - It sets the scope and how to finish.
  - The agent reports only when done, blocked or failing.
- **No untested claims.**
  - Call a feature working only after it passed a test on the real platform.
  - Say plainly what was not tested, and why.
  - "It builds" and "the code looks right" don't mean it works.
  - Example: "Import works on iPhone; iPad not tested, no iPad simulator was running."
  - Check it: every "works" in a report points to its test or evidence.
