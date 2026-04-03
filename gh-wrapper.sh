#!/bin/bash
# gh wrapper - blocks destructive GitHub CLI commands
# Real gh binary is at /usr/bin/gh-real

BLOCKED_PATTERNS=(
    "repo delete"
    "repo archive"
    "repo rename"
    "repo edit --visibility"
    "ssh-key delete"
    "gpg-key delete"
    "auth token"
)

ARGS="$*"

for pattern in "${BLOCKED_PATTERNS[@]}"; do
    if echo "$ARGS" | grep -qi "$pattern"; then
        echo "BLOCKED: 'gh $ARGS' is not allowed in this container."
        echo "Blocked pattern: $pattern"
        exit 1
    fi
done

exec /usr/bin/gh-real "$@"
