#!/bin/bash
# Pre-merge hook: runs /review before allowing gh pr merge
# Blocks merge if review fails. Max 3 attempts per branch, then requires manual review.
# Exit code 2 = block the tool call (Claude Code convention)

# Only trigger on gh pr merge commands
if ! echo "$TOOL_INPUT" | grep -q "gh pr merge"; then
    exit 0
fi

REVIEW_DIR="$(pwd)/.reviews"
MAX_ATTEMPTS=3
TIMEOUT_SECONDS=300

# Extract PR number or branch from the merge command
PR_REF=$(echo "$TOOL_INPUT" | grep -oP 'gh pr merge\s+\K\S+')

if [ -n "$PR_REF" ]; then
    BRANCH=$(gh pr view "$PR_REF" --json headRefName --jq '.headRefName' 2>/dev/null)
else
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

if [ -z "$BRANCH" ]; then
    echo "ERROR: Could not determine branch for PR."
    exit 2
fi

# Sanitize branch name for filename
PR_ID=$(echo "$BRANCH" | tr '/' '_')
COUNTER_FILE="$REVIEW_DIR/${PR_ID}.review-attempts"

mkdir -p "$REVIEW_DIR"

# Initialize counter if not exists
if [ ! -f "$COUNTER_FILE" ]; then
    echo "0" > "$COUNTER_FILE"
fi

ATTEMPTS=$(cat "$COUNTER_FILE")

# Check if max attempts exceeded
if [ "$ATTEMPTS" -ge "$MAX_ATTEMPTS" ]; then
    echo "BLOCKED: Review failed $MAX_ATTEMPTS times for branch '$BRANCH'. Manual review required."
    echo "Reset: rm $COUNTER_FILE"
    exit 2
fi

# Skip if manual /review already approved this branch
APPROVED_FILE="$REVIEW_DIR/${PR_ID}.approved"
if [ -f "$APPROVED_FILE" ]; then
    FLAG=$(cat "$APPROVED_FILE" 2>/dev/null | tr -d '[:space:]')
    if [ "$FLAG" = "true" ]; then
        echo "Review already PASSED for '$BRANCH' (manual /review). Proceeding with merge."
        exit 0
    fi
fi

# Run review with timeout
echo "Running pre-merge review for '$BRANCH' (attempt $((ATTEMPTS + 1))/$MAX_ATTEMPTS)..."
REVIEW_OUTPUT=$(timeout "$TIMEOUT_SECONDS" claude --dangerously-skip-permissions -p "Read /opt/claude/skills/review.md and execute it on the current branch. Do NOT run gh pr merge. Output the review report." --max-turns 30 2>&1)
REVIEW_EXIT=$?

# Timeout check
if [ "$REVIEW_EXIT" -eq 124 ]; then
    echo "Review timed out after ${TIMEOUT_SECONDS}s. Counting as failed attempt."
    echo $((ATTEMPTS + 1)) > "$COUNTER_FILE"
    REMAINING=$((MAX_ATTEMPTS - ATTEMPTS - 1))
    echo "$REMAINING attempts remaining."
    exit 2
fi

echo "$REVIEW_OUTPUT"

# Check result
if echo "$REVIEW_OUTPUT" | grep -q "REVIEW RESULT: APPROVED"; then
    echo ""
    echo "Review PASSED. Proceeding with merge."
    rm -f "$COUNTER_FILE"
    exit 0
else
    # Increment counter only on actual rejection (not on success or crash)
    echo $((ATTEMPTS + 1)) > "$COUNTER_FILE"
    REMAINING=$((MAX_ATTEMPTS - ATTEMPTS - 1))
    echo ""
    echo "Review REJECTED. $REMAINING attempts remaining."
    echo "Fix the issues and try merge again."
    exit 2
fi
