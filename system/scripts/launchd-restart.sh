#!/usr/bin/env bash

# Restart launchd services (agents or daemons) that have non-zero exit codes
# Usage: launchd-restart [--filter <pattern>] <command>

set -euo pipefail

FILTER="${LAUNCHD_FILTER:-ivankovnats}"

# Parse --filter option
while [[ $# -gt 0 ]]; do
    case "$1" in
        --filter)
            FILTER="$2"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

restart_agent() {
    launchctl kickstart -k "gui/$(id -u)/$1"
}

restart_agents() {
    local uid
    uid=$(id -u)

    echo "Checking user agents..."
    local services
    services=$(launchctl list | grep "$FILTER" | awk '$2 != 0 {print $3}')

    if [ -z "$services" ]; then
        echo "All agents are healthy (exit code 0)"
        return 0
    fi

    echo "Restarting unhealthy agents:"
    echo "$services" | while read -r svc; do
        echo "  → $svc"
        launchctl kickstart -k "gui/${uid}/${svc}"
    done
}

restart_daemon() {
    sudo launchctl kickstart -k "system/$1"
}

restart_daemons() {
    echo "Checking system daemons (requires sudo)..."
    local services
    services=$(sudo launchctl list | grep "$FILTER" | awk '$2 != 0 {print $3}')

    if [ -z "$services" ]; then
        echo "All daemons are healthy (exit code 0)"
        return 0
    fi

    echo "Restarting unhealthy daemons:"
    echo "$services" | while read -r svc; do
        echo "  → $svc"
        sudo launchctl kickstart -k "system/${svc}"
    done
}

show_status() {
    echo "=== User Agents ==="
    launchctl list | grep "$FILTER" | awk '$2 != 0' || echo "All healthy"
    echo ""
    echo "=== System Daemons ==="
    sudo launchctl list | grep "$FILTER" | awk '$2 != 0' || echo "All healthy"
}

list_agents() {
    launchctl list | grep "$FILTER" | awk '{print $3}' || echo "None found"
}

list_daemons() {
    sudo launchctl list | grep "$FILTER" | awk '{print $3}' || echo "None found"
}

list_services() {
    echo "=== User Agents ==="
    list_agents
    echo ""
    echo "=== System Daemons ==="
    list_daemons
}

usage() {
    echo "Usage: launchd-restart [--filter <pattern>] [OPTION] [SERVICE_NAME]"
    echo ""
    echo "Options:"
    echo "  --filter <pattern>  Filter services by pattern (default: ivankovnats)"
    echo "  --agents            Restart all unhealthy user agents"
    echo "  --agent <name>      Restart a specific user agent"
    echo "  --daemons           Restart all unhealthy system daemons (requires sudo)"
    echo "  --daemon <name>     Restart a specific system daemon (requires sudo)"
    echo "  --all               Restart both unhealthy agents and daemons"
    echo "  --list              List all services matching filter"
    echo "  --list-agents       List only user agents matching filter"
    echo "  --list-daemons      List only system daemons matching filter"
    echo "  --status            Show unhealthy services without restarting"
    echo "  -h, --help          Show this help"
    echo ""
    echo "Environment:"
    echo "  LAUNCHD_FILTER      Default filter pattern (overridden by --filter)"
}

case "${1:-}" in
    --agents)
        restart_agents
        ;;
    --agent)
        if [ -z "${2:-}" ]; then
            echo "Error: --agent requires a service name"
            exit 1
        fi
        restart_agent "$2"
        ;;
    --daemons)
        restart_daemons
        ;;
    --daemon)
        if [ -z "${2:-}" ]; then
            echo "Error: --daemon requires a service name"
            exit 1
        fi
        restart_daemon "$2"
        ;;
    --all)
        restart_agents
        echo ""
        restart_daemons
        ;;
    --list)
        list_services
        ;;
    --list-agents)
        list_agents
        ;;
    --list-daemons)
        list_daemons
        ;;
    --status)
        show_status
        ;;
    -h|--help)
        usage
        ;;
    "")
        usage
        exit 1
        ;;
    *)
        echo "Unknown option: $1"
        usage
        exit 1
        ;;
esac
