#!/usr/bin/env bash
set -e

echo "Killing SentinelOne services..."

# Kill system daemons (requires sudo)
sudo launchctl kill SIGKILL system/com.sentinelone.sentineld 2>/dev/null || true
sudo launchctl kill SIGKILL system/com.sentinelone.sentineld-helper 2>/dev/null || true
sudo launchctl kill SIGKILL system/com.sentinelone.sentineld-guard 2>/dev/null || true
sudo launchctl kill SIGKILL system/com.sentinelone.sentineld-updater 2>/dev/null || true

# Kill user agent
launchctl kill SIGKILL "gui/$(id -u)/com.sentinelone.agent" 2>/dev/null || true

echo "Done killing SentinelOne services."
