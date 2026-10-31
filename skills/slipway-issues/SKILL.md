---
name: slipway-issues
description: Report the state of the project's GitHub issues, or say plainly that the project doesn't track its work there. Use when the owner asks for the status of the issues, the open bugs, or what to work on next.
---

# slipway-issues

Reads the repo's GitHub issues and gives the owner one short overview: what an agent can start now, what waits on the owner, and what closed recently. It only reads: it never files, labels, comments on or closes an issue.

## Steps

1. **Check that the repo tracks its work in GitHub issues.** Stop at the first check that fails, and report it as in "Not tracked" below.
   - The folder is a git repo.
   - The repo's issue-tracker doc, when it has one, names GitHub. Check this first: a project that tracks its work elsewhere shouldn't be told to set up GitHub. Today Matt Pocock's skills point to that doc from an `### Issue tracker` block in `AGENTS.md` or `CLAUDE.md`, usually `docs/agents/issue-tracker.md`.
   - The repo has a GitHub remote: `git remote -v`. With more than one GitHub repo among the remotes, as in a fork, use the one `gh repo set-default --view` names; when none is set, ask the owner which one.
   - `gh` is installed and signed in: `gh auth status`.
   - Issues are turned on: `gh repo view <owner>/<name> --json nameWithOwner,hasIssuesEnabled,defaultBranchRef`.
2. **Read the issues** in one query. Write the owner, the name and the date 7 days ago into it literally, on one line, with no `$` variables or shell expansions, so the slipway guard sees a read and lets it through:

   ```bash
   gh api graphql -f query='query { repository(owner: "OWNER", name: "NAME") { open: issues(states: OPEN, first: 100) { totalCount pageInfo { hasNextPage endCursor } nodes { number title labels(first: 20) { nodes { name } } assignees(first: 1) { totalCount } issueDependenciesSummary { blockedBy } parent { number title } subIssuesSummary { total completed } } } closed: issues(states: CLOSED) { totalCount } recent: issues(states: CLOSED, first: 100, filterBy: {since: "2026-01-01T00:00:00Z"}) { nodes { number title closedAt stateReason parent { number } } } } }'
   ```

   - While `hasNextPage` is true, run it again with `after: "<endCursor>"` written into `open: issues(...)`.
   - No issues at all, open or closed: stop, and report "No issues yet".
   - Read the repo's triage-label map too, when it has one, so a renamed label still counts for its role. Today Matt Pocock's skills write it next to the issue-tracker doc, as `triage-labels.md`.
3. **Read what's in flight:** the commits on the current branch that aren't on the default branch, `git log --oneline <remote>/<default>..HEAD`, with the GitHub remote's name from step 1. Note each open issue a commit names by number or clearly works on.
4. **Sort each open issue into one group,** the first that fits:
   1. **Bugs an agent can fix now:** labelled bug and ready-for-agent.
   2. **A map:** sub-issues of the same open parent, or titles in one numbered series such as "Search 2/4". One group per map, named after it, with how many of its steps are done. The parent itself is the group's title, not an item.
      - Steps done: the parent's `subIssuesSummary`; for a numbered series, the total from the titles minus the steps still open.
   3. **Ready for an agent:** other ready-for-agent issues.
   4. **Waiting on you:** ready-for-human and needs-triage, plus needs-info when the owner is the one asked.
   5. **Other labels:** any other label, and needs-info waiting on someone else, noted as "waiting on the reporter".
   6. **No label.**
   - An issue with an open blocker (`blockedBy` above 0) or an assignee stays in its group, marked "blocked" or "taken".
   - "Can be started now" counts only ready-for-agent issues that are neither.
5. **Find what closed recently:** issues closed in the last 7 days, comparing `closedAt` in code, not by eye. Leave out those closed as not planned or as duplicates.
6. **Write the report,** in the format below.
7. **Ask** which issue to start on, through an interactive prompt with at most two options. Recommend the first issue that can be started now; when there is none, ask which waiting issue the owner wants to take up.

## Report format

```markdown
acme-app has **7 open issues** and **41 closed**. 3 can be started now.

**Bugs an agent can fix now (ready-for-agent)**
- #52: Search results disappear after you rotate the phone
- #55: Saving a draft with an empty title crashes the editor

**Offline mode (steps 1 and 2 of 4 are done)**
- #48, step 3/4: keep edits made offline and send them when back online. Ready for an agent.
- #49, step 4/4: show which notes haven't synced yet. Needs you (ready-for-human), blocked by #48.

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
- **Done recently:** one line, grouped by theme or number range, naming any map steps that finished. Leave it out when nothing closed.
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
| Not a git repo | Open the project's folder, or tell me where it tracks its work. |
| The tracker doc names another tracker | Read the issues there; this skill reads only GitHub. |
| No GitHub remote | Tell me where this project tracks its work, or create a GitHub repo for it. |
| `gh` missing or signed out | Install `gh`, then run `gh auth login`. |
| Issues turned off | Turn on Issues in the repo's GitHub settings. |
| No issues yet, and no tracker doc | Set up the issue tracker (slipway-setup installs the skills that do it), then file the first issue. |

- **No issues yet, and the tracker doc names GitHub:** the repo is set up but has nothing filed. Say "acme-app tracks its work in GitHub issues, but none are filed yet." Next: file the first one.
