#!/bin/bash
# Entrypoint for Claude Code dev container

# Initialize home volume on first run (volume starts empty, image files are shadowed)
if [ ! -f /home/node/.initialized ]; then
    mkdir -p /home/node/.claude/commands /home/node/.m2 /home/node/.npm
    touch /home/node/.initialized
fi

# Install/update skills, hooks, settings from image (/opt/claude/)
cp /opt/claude/skills/review.md /home/node/.claude/commands/review.md 2>/dev/null
cp /opt/claude/settings.json /home/node/.claude/settings.json 2>/dev/null

# Git identity
if [ -n "$GIT_USER_NAME" ]; then
    git config --global user.name "$GIT_USER_NAME"
fi
if [ -n "$GIT_USER_EMAIL" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
fi

# Environment summary
echo "============================================"
echo " Claude Code Dev Container"
echo "============================================"
echo " Java:      $(java -version 2>&1 | head -1)"
echo " Maven:     $(mvn -version 2>&1 | head -1)"
echo " Node:      $(node -v)"
echo " npm:       $(npm -v)"
echo " TypeScript:$(tsc -v)"
echo " Git:       $(git --version)"
echo " Claude:    $(claude --version 2>/dev/null || echo 'installed')"
echo "============================================"
echo ""
echo " First run? Log in first:"
echo "   claude login"
echo ""
echo " Claude Code starts with --dangerously-skip-permissions."
echo " For plain bash: docker exec -it <container> bash"
echo "============================================"

# Check if logged in; if not, prompt login
if ! claude auth status &>/dev/null 2>&1; then
    echo ""
    echo " Not logged in yet. Starting login..."
    echo ""
    claude login
fi

# Execute CMD
exec "$@"
