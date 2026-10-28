# Review

- **Parallel reviewers.**
  - When a task is finished, review the whole change before committing or merging it.
  - Run the reviewers in parallel, each as its own agent.
  - Simplicity: the smallest change that fully solves the task.
  - Design: stress-test the decisions behind the change.
  - Stack: one reviewer per technology, checked against its current docs.
  - Security: a focused review of the change.
  - Tests: every behavior change has a test that fails when it breaks, and the full suite passes.
  - UI: a design critique and audit, skipped only when no UI changed.
  - Today these run as: `ponytail`, `grilling`, `ctx7` docs, `security-audit`, `impeccable`.
  - Check it: every reviewer has reported before the merge.
