# Container rules

Isolated dev container with --dangerously-skip-permissions. All tools pre-approved.

## Commit rules

- NEVER add Co-Authored-By, Generated-by, or any AI/Claude/Anthropic attribution to commits, PRs, code comments, or anywhere else. This is a tool, not an author.

## Branch workflow

- NEVER commit directly to main or develop. Always create a feature branch first.
- Work on feature branches: `git checkout -b feature/description`
- Commit often at points of interest - after completing a logical step, fixing a bug, adding a feature. Do NOT save all commits for the end before PR creation.
- Push your changes regularly.
- Create PR targeting **develop** branch: `gh pr create --base develop`
- AFTER the PR is created, run `/review` to check for issues. Fix any findings before merging.
- Squash merge to develop, keep the branch: `gh pr merge --squash --delete-branch=false`
- If review rejects at merge: fix findings, push, try merge again.
- NEVER create PRs to main. Only the project owner merges develop to main.

## Review gate

A pre-merge hook runs `/review` automatically before `gh pr merge`.
If rejected: read findings, fix issues, push, retry merge.
After 3 failed attempts manual review is required.

## Available skills

- `/review` - code review orchestrator (spawns specialized reviewer subagents)

Reviewer prompts are at `/opt/claude/skills/review-*.md` - used by orchestrator internally.

## Housekeeping

- Ensure `.reviews/` is in the project's `.gitignore`. Never commit review counter files.
- Secret violation reports are stored in `~/.claude/violations/` (persisted in agent volume).

## Code standards enforced by review

- All code, comments, and names in English
- No 1-3 character variable names (except i/j in loops, e in catch)
- No magic numbers or strings - use named constants
- Java: string literals must be private static final constants at class top
