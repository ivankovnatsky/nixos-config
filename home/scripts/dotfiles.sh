#!/usr/bin/env bash

# dotfiles config macos status.showUntrackedFiles no
# dotfiles config linux status.showUntrackedFiles no

# Default locations
MACOS_REPO="$HOME/Sources/github.com/ivankovnatsky/macos-dotfiles"
LINUX_REPO="$HOME/Sources/github.com/ivankovnatsky/linux-dotfiles"
# Add more platforms as needed

usage() {
    echo "Usage: $(basename "$0") <platform> <command>"
    echo "Manages dotfiles for different platforms"
    echo ""
    echo "Platforms:"
    echo "  macos    - MacOS dotfiles"
    echo "  linux    - Linux dotfiles"
    echo ""
    echo "Commands:"
    echo "  status   - Show status of tracked files"
    echo "  add      - Add a file to track (requires path argument)"
    echo "  commit   - Commit changes"
    echo "  push     - Push changes to remote"
    echo "  pull     - Pull changes from remote"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") macos status"
    echo "  $(basename "$0") macos add ~/.zshrc"
    echo "  $(basename "$0") macos commit \"Add zshrc\""
}

get_repo_path() {
    local platform=$1
    case "$platform" in
        macos)
            echo "$MACOS_REPO"
            ;;
        linux)
            echo "$LINUX_REPO"
            ;;
        *)
            echo "Unknown platform: $platform" >&2
            exit 1
            ;;
    esac
}

run_git() {
    local platform=$1
    shift
    local repo_path=$(get_repo_path "$platform")
    git --git-dir="$repo_path/.git" --work-tree="$HOME" "$@"
}

# Check if we have enough arguments
if [ $# -lt 2 ]; then
    usage
    exit 1
fi

platform=$1
command=$2
shift 2

case "$command" in
    status)
        run_git "$platform" status
        ;;
    add)
        if [ $# -eq 0 ]; then
            echo "Error: add command requires a file path"
            exit 1
        fi
        run_git "$platform" add "$@"
        ;;
    commit)
        if [ $# -eq 0 ]; then
            echo "Error: commit requires a message"
            exit 1
        fi
        run_git "$platform" commit -m "$*"
        ;;
    push)
        run_git "$platform" push
        ;;
    pull)
        run_git "$platform" pull
        ;;
    *)
        echo "Unknown command: $command"
        usage
        exit 1
        ;;
esac
