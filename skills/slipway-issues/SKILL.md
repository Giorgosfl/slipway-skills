---
name: slipway-issues
description: Report the state of the project's GitHub issues, or say plainly that the project doesn't track its work there. Use when the owner asks for the status of the issues, the open bugs, or what to work on next, and for the open bugs in the session-start status.
---

# slipway-issues

Reads the repo's GitHub issues and gives the owner one short overview: what an agent can start now, what waits on the owner, and what closed recently. It only reads: it never files, labels, comments on or closes an issue.

## Steps

1. **Check that the repo tracks its work in GitHub issues.** Stop at the first check that fails, and report it as in "Not tracked" below.
   - The repo has a GitHub remote: `git remote -v`.
   - `gh` is installed and signed in: `gh auth status`.
   - Issues are turned on: `gh repo view --json nameWithOwner,hasIssuesEnabled,defaultBranchRef`.
   - The repo's issue-tracker doc, when it has one, names GitHub. Today the issue-tracker setup in Matt Pocock's skills writes it to `docs/agents/issue-tracker.md`.
   - The repo has at least one issue, open or closed: the counts from step 2.
2. **Read the issues** in one query, with the owner and name from step 1 written into it. Keep it a literal query on one line, with no `$` variables, so the slipway guard sees a read and lets it through:

   ```bash
   gh api graphql -f query='query { repository(owner: "OWNER", name: "NAME") { open: issues(states: OPEN, first: 100) { totalCount nodes { number title labels(first: 20) { nodes { name } } parent { number title } subIssuesSummary { total completed } } } closed: issues(states: CLOSED, first: 50, orderBy: {field: UPDATED_AT, direction: DESC}) { totalCount nodes { number title closedAt stateReason parent { number } } } } }'
   ```

   - With more than 100 open issues, page through the rest before sorting.
   - Read the repo's triage-label map too, when it has one, so a renamed label still counts for its role. Today Matt Pocock's skills write it to `docs/agents/triage-labels.md`.
3. **Read what's in flight:** the commits on the current branch that aren't on the default branch, `git log --oneline origin/<default>..HEAD`. Note each open issue a commit names by number or clearly works on.
4. **Sort each open issue into one group,** the first that fits:
   1. **Bugs an agent can fix now:** labelled bug and ready-for-agent.
   2. **A map:** sub-issues of the same open parent, or titles in one numbered series such as "Search 2/4". One group per map, named after it, with how many of its steps are done. The parent itself is the group's title, not an item.
   3. **Ready for an agent:** other ready-for-agent issues.
   4. **Waiting on you:** ready-for-human, needs-triage and needs-info.
   5. **Other labels:** any other label.
   6. **No label.**
5. **Find what closed recently:** issues closed in the last 7 days, compared in code, not by eye. Leave out those closed as not planned.
6. **Write the report,** in the format below.
7. **Ask** which issue to start on, through an interactive prompt with at most two options. Recommend the first group that has issues an agent can start.

## Report format

```markdown
acme-app has **9 open issues** and **41 closed**. The 4 marked ready-for-agent can be started now.

**Bugs an agent can fix now (ready-for-agent)**
- #52: Search results disappear after you rotate the phone
- #55: Saving a draft with an empty title crashes the editor

**Offline mode (steps 1 and 2 of 4 are done)**
- #48, step 3/4: keep edits made offline and send them when back online. Ready for an agent.
- #49, step 4/4: show which notes haven't synced yet. Needs you (ready-for-human).

**Waiting on you**
- #50: Decisions left from the last test run (needs-triage)

**No label**
- #31: Measure start-up time on older phones

**Done recently:** 6 issues closed since Oct 24, including offline mode steps 1 and 2 (#46, #47).

The current branch `fix-search` has commits about search results and rotation. I haven't checked whether they already fix #52.
```

- **First line:** the repo's name, the open and closed counts in bold, and how many issues can be started now.
- **Groups:** in the order of step 4, each with a bold title. Leave out an empty group.
- **Items:** `#<number>: <title>`, with the title rewritten in plain words. A map's items add their step and who they're ready for.
- **Labels:** say what a label means the first time it appears, such as "Needs you (ready-for-human)".
- **Long groups:** at most 5 issues each, the most important first, then one line: "+3 more: #12, #14, #19".
- **Done recently:** one line, grouped by theme or number range, naming any map steps that finished.
- **Last line:** in-flight commits that may fix an open issue, saying they weren't checked. Leave it out when the branch has none.

## Not tracked

```markdown
acme-app doesn't track its work in GitHub issues: the repo has no GitHub remote.

Next: tell me where this project tracks its work, or create a GitHub repo for it.
```

- **First line:** the repo's name and the check that failed, in plain words.
- **Next:** one action the owner can take now:

| Failed check | Next |
|---|---|
| No GitHub remote | Tell me where this project tracks its work, or create a GitHub repo for it. |
| `gh` missing or signed out | Install `gh`, then run `gh auth login`. |
| Issues turned off | Turn on Issues in the repo's GitHub settings. |
| The tracker doc names another tracker | Read the issues there; this skill reads only GitHub. |
| No issues yet | Set up the issue tracker (slipway-setup installs the skills that do it), then file the first issue. |

- Turning on Issues and filing an issue are outward actions: leave them to the owner, or do them only when the owner asks.
