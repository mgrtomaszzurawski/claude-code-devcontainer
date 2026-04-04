#!/bin/bash
# Central agent manager for Claude Code dev containers
# Usage: ./agent.sh <command> <agent-name>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

CMD="${1:-help}"
AGENT="${2:-}"

case "$CMD" in
  create)
    if [ -z "$AGENT" ]; then
      read -p "Agent name: " AGENT
    fi
    if [ -z "$AGENT" ]; then
      echo "Name cannot be empty."
      exit 1
    fi
    # Docker compose project names: lowercase alphanumeric, hyphens, underscores
    AGENT=$(echo "$AGENT" | tr '[:upper:]' '[:lower:]')
    if ! echo "$AGENT" | grep -qE '^[a-z0-9][a-z0-9_-]*$'; then
      echo "Invalid name. Use only lowercase letters, numbers, hyphens and underscores. Must start with letter or number."
      exit 1
    fi
    if [ -d "agent-shells/$AGENT" ]; then
      echo "Agent '$AGENT' already exists."
      exit 1
    fi

    # Create folder structure
    mkdir -p "agent-data/$AGENT" "agent-shells/$AGENT"

    # Generate wrapper scripts
    # .bat: numbered 1-7 for Windows Explorer ordering
    # .sh: lettered a-g for terminal tab-completion ordering
    BAT_NUM=0
    SH_LETTER=96  # ASCII 'a' - 1
    for cmd in start attach bash logs stop destroy reset list; do
      BAT_NUM=$((BAT_NUM + 1))
      SH_LETTER=$((SH_LETTER + 1))
      SH_PREFIX=$(printf "\\$(printf '%03o' $SH_LETTER)")

      # .sh wrapper
      if [ "$cmd" = "list" ]; then
        cat > "agent-shells/$AGENT/${SH_PREFIX}-${cmd}.sh" <<EOF
#!/bin/bash
cd "\$(dirname "\$0")/../.."
./agent.sh list
EOF
      else
        cat > "agent-shells/$AGENT/${SH_PREFIX}-${cmd}.sh" <<EOF
#!/bin/bash
cd "\$(dirname "\$0")/../.."
./agent.sh $cmd $AGENT
EOF
      fi
      chmod +x "agent-shells/$AGENT/${SH_PREFIX}-${cmd}.sh"

      # .bat wrapper
      if [ "$cmd" = "attach" ] || [ "$cmd" = "bash" ]; then
        cat > "agent-shells/$AGENT/${BAT_NUM}-${cmd}.bat" <<EOF
@echo off
cd /d "%~dp0\\..\\.."
"%ProgramFiles%\Git\bin\bash.exe" --login -c "./agent.sh $cmd $AGENT; exec bash"
EOF
      elif [ "$cmd" = "list" ]; then
        cat > "agent-shells/$AGENT/${BAT_NUM}-${cmd}.bat" <<EOF
@echo off
cd /d "%~dp0\\..\\.."
"%ProgramFiles%\Git\bin\bash.exe" --login -c "./agent.sh list"
pause
EOF
      else
        cat > "agent-shells/$AGENT/${BAT_NUM}-${cmd}.bat" <<EOF
@echo off
cd /d "%~dp0\\..\\.."
"%ProgramFiles%\Git\bin\bash.exe" --login -c "./agent.sh $cmd $AGENT"
pause
EOF
      fi
    done

    echo "Agent '$AGENT' created."
    echo "  Folder:    agent-shells/$AGENT/"
    echo "  Workspace: agent-data/$AGENT/"
    echo ""
    echo "  Start:  agent-shells/$AGENT/1-start"
    echo "  Attach: agent-shells/$AGENT/2-attach"
    ;;

  start)
    if [ -z "$AGENT" ]; then
      echo "Usage: ./agent.sh start <agent-name>"
      exit 1
    fi
    mkdir -p "agent-data/$AGENT"

    # Always use up -d --build to pick up image updates after upgrade
    # Recreates container if image changed, no-op if already running with current image
    AGENT="$AGENT" docker compose -p "claude-$AGENT" up -d --build

    echo ""
    echo "Agent '$AGENT' is running."
    echo "  Attach: agent-shells/$AGENT/2-attach"
    echo "  Bash:   agent-shells/$AGENT/3-bash"
    ;;

  stop)
    if [ -z "$AGENT" ]; then
      echo "Usage: ./agent.sh stop <agent-name>"
      exit 1
    fi
    AGENT="$AGENT" docker compose -p "claude-$AGENT" stop
    echo "Agent '$AGENT' stopped. Use start to resume."
    ;;

  attach)
    if [ -z "$AGENT" ]; then
      echo "Usage: ./agent.sh attach <agent-name>"
      exit 1
    fi
    # Check if running
    if ! docker ps --filter "name=^claude-${AGENT}$" --format "{{.Names}}" | grep -q .; then
      echo "Agent '$AGENT' is not running. Starting..."
      "$0" start "$AGENT"
    fi
    echo "Attaching to claude-$AGENT (detach: Ctrl+P, Ctrl+Q)"
    docker attach "claude-$AGENT"
    ;;

  bash)
    if [ -z "$AGENT" ]; then
      echo "Usage: ./agent.sh bash <agent-name>"
      exit 1
    fi
    if ! docker ps --filter "name=^claude-${AGENT}$" --format "{{.Names}}" | grep -q .; then
      echo "Agent '$AGENT' is not running."
      exit 1
    fi
    docker exec -it "claude-$AGENT" bash
    ;;

  logs)
    if [ -z "$AGENT" ]; then
      echo "Usage: ./agent.sh logs <agent-name>"
      exit 1
    fi
    docker logs "claude-$AGENT"
    ;;

  reset)
    if [ -z "$AGENT" ]; then
      echo "Usage: ./agent.sh reset <agent-name>"
      exit 1
    fi
    if [ ! -d "agent-shells/$AGENT" ]; then
      echo "Agent '$AGENT' does not exist."
      exit 1
    fi
    echo "Resetting agent '$AGENT' (removes container + scripts, keeps workspace files)."
    read -p "Continue? [y/N] " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
      echo "Cancelled."
      exit 0
    fi

    AGENT="$AGENT" docker compose -p "claude-$AGENT" down 2>/dev/null
    rm -rf "agent-shells/$AGENT"
    echo "Agent '$AGENT' reset. Workspace files in agent-data/$AGENT/ preserved."
    echo ""
    # Recreate immediately
    "$0" create "$AGENT"
    ;;

  destroy)
    if [ -z "$AGENT" ]; then
      echo "Usage: ./agent.sh destroy <agent-name>"
      exit 1
    fi
    read -p "Destroy agent '$AGENT'? This removes container, config and workspace. [y/N] " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
      echo "Cancelled."
      exit 0
    fi

    AGENT="$AGENT" docker compose -p "claude-$AGENT" down 2>/dev/null
    rm -rf "agent-shells/$AGENT" "agent-data/$AGENT"
    echo "Agent '$AGENT' destroyed."
    ;;

  list)
    echo "Claude agents:"
    echo ""
    # Show all agent folders with status
    if [ -d "agent-shells" ] && [ "$(ls -A agent-shells 2>/dev/null)" ]; then
      for dir in agent-shells/*/; do
        name=$(basename "$dir")
        status=$(docker ps -a --filter "name=^claude-${name}$" --format "{{.Status}}" 2>/dev/null)
        if [ -z "$status" ]; then
          status="not created"
        fi
        echo "  $name - $status"
      done
    else
      echo "  No agents. Create one: ./agent.sh create <name>"
    fi
    ;;

  upgrade)
    echo "Rebuilding image with latest Claude Code..."
    echo "Running pods are NOT affected until restart."
    echo ""
    docker compose build --no-cache
    if [ $? -eq 0 ]; then
      echo ""
      echo "Image rebuilt. To upgrade a pod: stop -> start"
      echo "Auth, chat history, and theme are preserved."
      echo ""
      # Show which pods need restart
      if [ -d "agent-shells" ] && [ "$(ls -A agent-shells 2>/dev/null)" ]; then
        echo "Running pods (need stop/start for new version):"
        for dir in agent-shells/*/; do
          name=$(basename "$dir")
          status=$(docker ps --filter "name=^claude-${name}$" --format "{{.Status}}" 2>/dev/null)
          if [ -n "$status" ]; then
            echo "  $name - $status"
          fi
        done
      fi
    else
      echo ""
      echo "ERROR: Image build failed."
      exit 1
    fi
    ;;

  help|*)
    echo "Claude Code Agent Manager"
    echo ""
    echo "Usage: ./agent.sh <command> [agent-name]"
    echo ""
    echo "Commands:"
    echo "  create [name]   Create new agent (prompts for name if omitted)"
    echo "  start <name>    Start or resume agent"
    echo "  stop <name>     Stop agent (keeps data)"
    echo "  attach <name>   Attach to Claude Code session"
    echo "  bash <name>     Open bash in agent container"
    echo "  logs <name>     Show agent startup logs"
    echo "  reset <name>    Remove container + scripts, keep workspace files"
    echo "  destroy <name>  Remove agent, config, and workspace"
    echo "  upgrade         Rebuild image with latest Claude Code"
    echo "  list            Show all agents and their status"
    ;;
esac
