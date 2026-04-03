# Container rules

Isolated dev container with --dangerously-skip-permissions. All tools pre-approved.

## Branch workflow

- NEVER commit directly to main. Always create a feature branch first.
- Work on feature branches: `git checkout -b feature/description`
- Commit, push, create PR with `gh pr create`
- Run `/review` before attempting merge - fix issues early to save merge attempts.
- Merge with `gh pr merge` (triggers automatic review gate, max 3 attempts).
- If review rejects: fix findings, push, try merge again.

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
