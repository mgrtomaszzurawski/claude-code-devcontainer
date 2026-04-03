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
    if [ -d "connection/$AGENT" ]; then
      echo "Agent '$AGENT' already exists."
      exit 1
    fi

    # Create folder structure
    mkdir -p "workspace/$AGENT" "agents/$AGENT/claude" "connection/$AGENT"

    # Generate wrapper scripts
    for cmd in start stop attach bash destroy logs; do
      cat > "connection/$AGENT/$cmd.sh" <<EOF
#!/bin/bash
cd "\$(dirname "\$0")/../.."
./agent.sh $cmd $AGENT
EOF
      chmod +x "connection/$AGENT/$cmd.sh"
    done

    echo "Agent '$AGENT' created."
    echo "  Folder:    connection/$AGENT/"
    echo "  Workspace: workspace/$AGENT/"
    echo ""
    echo "  Start:     connection/$AGENT/start.sh"
    ;;

  start)
    if [ -z "$AGENT" ]; then
      echo "Usage: ./agent.sh start <agent-name>"
      exit 1
    fi
    mkdir -p "workspace/$AGENT" "agents/$AGENT/claude"

    # Check if container exists but is stopped
    if docker ps -a --filter "name=^claude-${AGENT}$" --format "{{.Status}}" | grep -q "Exited"; then
      AGENT="$AGENT" docker compose -p "claude-$AGENT" start
    else
      AGENT="$AGENT" docker compose -p "claude-$AGENT" up -d
    fi

    echo ""
    echo "Agent '$AGENT' is running."
    echo "  Attach: connection/$AGENT/attach.sh"
    echo "  Bash:   connection/$AGENT/bash.sh"
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
    rm -rf "connection/$AGENT" "agents/$AGENT" "workspace/$AGENT"
    echo "Agent '$AGENT' destroyed."
    ;;

  list)
    echo "Claude agents:"
    echo ""
    # Show all connection folders with status
    if [ -d "connection" ] && [ "$(ls -A connection 2>/dev/null)" ]; then
      for dir in connection/*/; do
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
    echo "  destroy <name>  Remove agent, config, and workspace"
    echo "  list            Show all agents and their status"
    ;;
esac
