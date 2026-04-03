#!/bin/bash
# Post-merge hook: cleans up review counter after successful merge
# Reads branch name saved by pre-merge hook (HEAD may have changed after merge)

# Only trigger on gh pr merge commands
if ! echo "$TOOL_INPUT" | grep -q "gh pr merge"; then
    exit 0
fi

REVIEW_DIR="/workspace/.reviews"
BRANCH_FILE="$REVIEW_DIR/.last-merge-branch"

if [ ! -f "$BRANCH_FILE" ]; then
    exit 0
fi

BRANCH=$(cat "$BRANCH_FILE")
PR_ID=$(echo "$BRANCH" | tr '/' '_')
COUNTER_FILE="$REVIEW_DIR/${PR_ID}.review-attempts"

# Verify merge actually happened
PR_STATE=$(gh pr view "$BRANCH" --json state --jq '.state' 2>/dev/null)
if [ "$PR_STATE" = "MERGED" ]; then
    rm -f "$COUNTER_FILE" "$BRANCH_FILE" "$REVIEW_DIR/${PR_ID}.approved" 2>/dev/null
fi
