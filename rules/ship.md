# Ship

- **Feature branches.**
  - Commit on a feature branch, not straight on main.
- **Outward actions.**
  - Ask before any outward action the owner didn't name: push, merge, open issues, post comments.
  - One exception: when reviews are clean and every case passes, merge, push and clean up without asking.
  - Ask only when something is left to decide or fix.
- **Merge on green.**
  - Merge a feature branch into main only after the full test suite passes on its latest commit.
  - If main has moved, bring it into the branch first and run the suite again.
  - Then fast-forward main and push.
