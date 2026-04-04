#!/bin/bash
# Post-merge hook: cleans up review counter after successful merge
# Reads branch name saved by pre-merge hook (HEAD may have changed after merge)

# Only trigger on gh pr merge commands
if ! echo "$TOOL_INPUT" | grep -q "gh pr merge"; then
    exit 0
fi

REVIEW_DIR="/workspace/.reviews"

# Extract PR number or branch from the merge command
PR_REF=$(echo "$TOOL_INPUT" | grep -oP 'gh pr merge\s+\K\S+')

if [ -n "$PR_REF" ]; then
    # Got PR number or branch from command - resolve to branch name
    BRANCH=$(gh pr view "$PR_REF" --json headRefName --jq '.headRefName' 2>/dev/null)
else
    # No argument - gh pr merge uses current branch
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

if [ -z "$BRANCH" ]; then
    exit 0
fi

PR_ID=$(echo "$BRANCH" | tr '/' '_')

# Clean up review files for this branch only
rm -f "$REVIEW_DIR/${PR_ID}.review-attempts" \
      "$REVIEW_DIR/${PR_ID}.approved" 2>/dev/null
