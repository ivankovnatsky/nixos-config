#!/usr/bin/env bash

# Restart launchd services (agents or daemons) that have non-zero exit codes
# Usage: launchd-restart [--agents|--daemons|--all]

set -euo pipefail

FILTER="ivankovnats"

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

usage() {
    echo "Usage: launchd-restart [OPTION]"
    echo ""
    echo "Options:"
    echo "  --agents   Restart unhealthy user agents"
    echo "  --daemons  Restart unhealthy system daemons (requires sudo)"
    echo "  --all      Restart both agents and daemons"
    echo "  --status   Show unhealthy services without restarting"
    echo "  -h, --help Show this help"
}

case "${1:-}" in
    --agents)
        restart_agents
        ;;
    --daemons)
        restart_daemons
        ;;
    --all)
        restart_agents
        echo ""
        restart_daemons
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
