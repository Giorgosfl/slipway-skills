# Test

- **Focused test per behavior change.**
  - Every change to behavior adds or updates an automated test for it.
  - The test checks that one behavior and nothing else.
  - It fails when that behavior breaks.
  - Prove it: break the behavior on purpose, watch the test fail, then restore it.
  - Removing a behavior removes its test.
  - Example: switching the sort to newest-first comes with a test that fails if the order flips back.
  - Check it: every behavior change in the diff has a matching test change.
