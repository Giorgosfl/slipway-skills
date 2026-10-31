---
name: slipway-issues
description: Report the state of the project's GitHub issues, or say plainly that the project doesn't track its work there. Use when the owner asks for the status of the issues, the open bugs, or what to work on next.
---

# slipway-issues

Reads the repo's GitHub issues and gives the owner one short overview: what an agent can start now, what waits on the owner, and what closed recently. It only reads: it never files, labels, comments on or closes an issue. The report follows the format below, even where it runs longer than a usual status reply.

## Steps

1. **Check that the repo tracks its work in GitHub issues.** Stop at the first check that fails, and report it as in "Not tracked" below.
   - The folder is a git repo.
   - The repo's issue-tracker doc, when it has one, names GitHub. This comes before the GitHub checks, so a project that tracks its work elsewhere isn't told to set up GitHub.
     - Today Matt Pocock's skills point to that doc from an `### Issue tracker` block in `AGENTS.md` or `CLAUDE.md`, usually `docs/agents/issue-tracker.md`, with the triage-label map `triage-labels.md` beside it.
   - The repo has a GitHub remote: `git remote -v`. This skill reads only github.com; a remote on another GitHub host, such as GitHub Enterprise, counts as "can't read".
   - `gh` is installed and signed in: `gh auth status --active --hostname github.com`.
   - With more than one github.com repo among the remotes, as in a fork, use the one `gh repo set-default --view` names; when none is set, ask the owner which one.
   - The repo can be read and has Issues turned on: `gh repo view <owner>/<name> --json hasIssuesEnabled,defaultBranchRef`.
2. **Read the issues** in one query. Write the owner, the name and the date 7 days ago into it literally, on one line, with no `$` variables or shell expansions, so the slipway guard sees a read and lets it through:

   ```bash
   gh api graphql -f query='query { viewer { login } repository(owner: "OWNER", name: "NAME") { open: issues(states: OPEN, first: 100) { totalCount pageInfo { hasNextPage endCursor } nodes { number title author { login } labels(first: 20) { nodes { name } } assignees(first: 1) { totalCount } blockedBy(first: 10) { nodes { number state } } parent { number title } subIssuesSummary { total completed } } } closed: issues(states: CLOSED) { totalCount } recent: issues(states: CLOSED, first: 100, orderBy: {field: UPDATED_AT, direction: DESC}, filterBy: {since: "2026-01-01T00:00:00Z"}) { pageInfo { hasNextPage endCursor } nodes { number title closedAt stateReason parent { number } } } } }'
   ```

   - While `open` or `recent` has `hasNextPage`, run again with `after: "<endCursor>"` written into that list, keeping only that list in the query.
   - No issues at all, open or closed: stop, and report "No issues yet".
   - Read the repo's triage-label map too, when it has one, so a renamed label still counts for its role.
3. **Read what's in flight.** Fetch the default branch first, `git fetch <remote> <default>`, with the github.com remote's name from step 1. Then read the commits on the current branch that aren't on it, subjects and bodies: `git log --format='%h %s%n%b' <remote>/<default>..HEAD`. Note each open issue a commit says it fixes or works on, such as "Fixes #N", "Part of #N" or a subject about it; a passing mention, such as "still tracked in #N", doesn't count.
   - If the fetch fails, as offline or in a sandbox that can't write in `.git`, use the local `<remote>/<default>` as it is, and say in the last line that it may be out of date. If that ref doesn't exist either, skip this step and say so in the last line.
4. **Sort each open issue into one group,** the first that fits:
   1. **Bugs an agent can fix now:** labelled bug and ready-for-agent.
   2. **A map:** sub-issues of the same open parent, or titles in one numbered series such as "Search 2/4". One group per map, named after it. The parent itself is the group's title, not an item.
      - Steps done: the parent's `subIssuesSummary`; for a numbered series, the total from the titles minus the steps still open in any group.
      - An item gets a step number only from a numbered title; sub-issues of a parent are listed in number order.
      - A bug that belongs to a map stays in the bugs group, marked with its map, and its step when it has one. When all of a map's open steps are such bugs, keep the map's title line anyway, with one line pointing to them: "its open steps, #52 and #53, are under bugs".
      - An open parent whose steps are all closed goes under "Waiting on you": "<map>: all N steps done, ready to close".
   3. **Ready for an agent:** other ready-for-agent issues.
   4. **Waiting on you:** ready-for-human and needs-triage, plus needs-info that the owner filed (its author is the viewer).
   5. **Other labels:** any other label, and needs-info someone else filed, noted as "waiting on the reporter".
   6. **No label.**
   - An issue stays in its group but is marked when it's blocked (a blocker in `blockedBy` is still open: "blocked by #N"), taken (it has an assignee) or in flight (step 3 noted it).
   - "Can be started now" counts only ready-for-agent issues that are none of these.
5. **Find what closed recently:** issues closed in the last 7 days, comparing `closedAt` in code, not by eye. Leave out those closed as not planned or as duplicates.
6. **Write the report,** in the format below.
7. **Ask** what to work on, through an interactive prompt with at most two options. When the branch has work in flight, recommend finishing or checking it first, naming its issues. When step 3 was skipped, don't treat the branch as clear: say its work wasn't checked. Otherwise recommend the first issue that can be started now; when there is none, ask which waiting issue the owner wants to take up.

## Report format

```markdown
acme-app has **7 open issues** and **41 closed**. 2 can be started now.

**Bugs an agent can fix now (ready-for-agent)**
- #52: Search results disappear after you rotate the phone. In flight on this branch.
- #55: Saving a draft with an empty title crashes the editor

**Offline mode (2 of 4 steps done)**
- #48: keep edits made offline and send them when back online. Ready for an agent.
- #49: show which notes haven't synced yet. Needs you (ready-for-human), blocked by #48.

**Waiting on you**
- #50: Decisions left from the last test run (needs-triage)

**No label**
- #31: Measure start-up time on older phones

**Done recently:** 6 issues closed since Oct 24, including two offline mode steps (#46, #47).

The current branch `fix-search` has commits about search results and rotation. I haven't checked whether they already fix #52.
```

Here "Offline mode" is the map's open parent issue: it counts among the 7 open issues but shows only as the group's title. Its sub-issues have plain titles, so the items carry no step numbers.

- **First line:** the GitHub repo's name, the open and closed counts in bold, and how many issues can be started now.
- **Groups:** in the order of step 4, each with a bold title. Leave out an empty group.
- **Items:** `#<number>: <title>`, with the title rewritten in plain words, then any mark from step 4. A map's items add their step, when they have one, and who they're ready for.
- **Labels:** say what a label means the first time it appears, such as "Needs you (ready-for-human)".
- **Long groups:** at most 5 issues each, the most important first, then one line: "+3 more: #12, #14, #19".
- **Done recently:** one line, grouped by theme or number range, naming any map steps that finished. Leave it out when nothing closed.
- **Last line:** in-flight commits that may fix an open issue, saying they weren't checked, plus any note from step 3 that the comparison may be out of date or was skipped. Leave it out only when the branch has none and step 3 ran on a fresh fetch.

## Not tracked

Two kinds of failed check read differently. Never call a repo "not tracked" only because its issues couldn't be read.

```markdown
acme-app doesn't track its work in GitHub issues: the repo has no GitHub remote.

Next: tell me where this project tracks its work, or create a GitHub repo for it.
```

```markdown
I can't read acme-app's GitHub issues: gh is signed out.

Next: run `gh auth login`, then ask again.
```

- **First line:** the repo's name and the check that failed, in plain words.
- **Next:** one action the owner can take now:

| Failed check | First line | Next |
|---|---|---|
| Not a git repo | doesn't track | Open the project's folder, or tell me where it tracks its work. |
| The tracker doc names another tracker | doesn't track | Read the issues there; this skill reads only GitHub. |
| No GitHub remote | doesn't track | Tell me where this project tracks its work, or create a GitHub repo for it. |
| Issues turned off | doesn't track | Turn on Issues in the repo's GitHub settings. |
| No issues yet | doesn't track, or "tracks its work in GitHub issues, but none are filed yet" when the tracker doc names GitHub | File the first one; with no tracker doc, set it up first (slipway-setup installs the skills that do it). |
| The GitHub remote isn't on github.com | can't read | Read the issues on that host directly; this skill reads only github.com. |
| `gh` missing or signed out | can't read | Install `gh`, or run `gh auth login`, then ask again. |
| The repo can't be reached: no access, no network, or a sandbox blocking it | can't read | Give the error in one line, then: check access to the repo, then ask again. |
