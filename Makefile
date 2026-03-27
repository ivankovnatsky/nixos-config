# https://stackoverflow.com/a/30176470
.DEFAULT_GOAL := default

# Mark targets that don't create files as .PHONY so Make will always run them
.PHONY: \
	default \
	addall \
	rebuild-once \
	\
	trigger-rebuild \
	\
	flake-update-darwin-unstable \
	flake-update-darwin-release \
	flake-update-nixos-unstable \
	flake-update-nixos-release \
	flake-update-nixvim \
	flake-update-homebrew \
	\
	rebuild-nixos/generic \
	rebuild-nixos/impure \
	rebuild-nixos/a3 \
	rebuild-nixos/a3-user \
	\
	rebuild-darwin \
	verbose \
	debug \
	rebuild-loop \
	rebuild-watch-loop \
	\
	test-build \
	rebuild-watchman \
	rebuild-watchman-nixos \
	rebuild-watchman-darwin \
	\
	devcontainer \
	devcontainer-rebuild

PLATFORM := $(shell uname)
# TODO: This is temporary until we figure out how to properly configure nix.conf
# Currently determinate.nix doesn't support nix.enable in darwin configuration
# Remove these flags once we have proper nix configuration
NIX_EXTRA_FLAGS := --extra-experimental-features flakes --extra-experimental-features nix-command

# Use full nix path so targets work even when nix is not in PATH (e.g. after reboot/migration)
NIX_BIN := /nix/var/nix/profiles/default/bin/nix
NIX := $(shell command -v nix 2>/dev/null || echo $(NIX_BIN))
DARWIN_REBUILD := $(shell command -v darwin-rebuild 2>/dev/null || echo $(NIX_BIN) run $(NIX_EXTRA_FLAGS) nix-darwin --)
NIXOS_REBUILD := $(shell command -v nixos-rebuild 2>/dev/null || echo $(NIX_BIN) run $(NIX_EXTRA_FLAGS) nixpkgs\#nixos-rebuild --)

# Common flags for rebuild commands
# VERBOSE=1: --verbose, DEBUG=1: -vvvvv --print-build-logs
COMMON_REBUILD_FLAGS := -L --flake .
ifdef VERBOSE
COMMON_REBUILD_FLAGS += --verbose
endif
ifdef DEBUG
COMMON_REBUILD_FLAGS += -vvvvv --print-build-logs
endif

# Default target will run rebuild based on platform
ifeq (${PLATFORM}, Darwin)
default: rebuild-darwin
else
default: rebuild-nixos/generic
endif

verbose:
	@$(MAKE) VERBOSE=1

debug:
	@$(MAKE) DEBUG=1

addall:
	git add -A

# One-time rebuild and exit terminal
ifeq (${PLATFORM}, Darwin)
rebuild-once:
	@$(MAKE) rebuild-darwin && exit
else
rebuild-once:
	@$(MAKE) rebuild-nixos/generic && exit
endif

# FIXME:
# ```console
# filesystem error: in create_hard_link: File exists
# ["/nix/store/.links/04sbnlzwypkihxv6ah7yzb5673c7zdwrj93rxiz2f3xn5wkq56vl"]
# ["/nix/store/.tmp-link-6248-1531891506"] error: some substitutes for the
#   outputs of derivation
#   '/nix/store/dckqp5p9gxswfh3k9hpywhw1n311nw20-vscode-extension-ms-vscode-makefile-tools-0.6.0.drv'
#   failed (usually happens due to networking issues); try '--fallback' to build
#   derivation from source copying path
#   '/nix/store/p3l68bkq6181njhrkspk3gpkkipxdy4i-python3.12-mypy-extensions-1.0.0'
#   from 'https://cache.nixos.org'...
# ```
trigger-rebuild:
	while true; do touch .trigger-rebuild && sleep 1; done

flake-update-darwin-unstable:
	inputs="nixpkgs-darwin-unstable nix-darwin-darwin-unstable home-manager-darwin-unstable nixvim-darwin-unstable sops-nix-darwin-unstable"; \
	for input in $$inputs; do \
		$(NIX) flake update ${NIX_EXTRA_FLAGS} --commit-lock-file $$input; \
	done

flake-update-darwin-release:
	inputs="nixpkgs-darwin-release nix-darwin-darwin-release home-manager-darwin-release nixvim-darwin-release sops-nix-darwin-release"; \
	for input in $$inputs; do \
		$(NIX) flake update ${NIX_EXTRA_FLAGS} --commit-lock-file $$input; \
	done

flake-update-nixos-unstable:
	inputs="nixpkgs-nixos-unstable home-manager-nixos-unstable nixvim-nixos-unstable plasma-manager-nixos-unstable sops-nix-nixos-unstable nur-nixos-unstable"; \
	for input in $$inputs; do \
		$(NIX) flake update ${NIX_EXTRA_FLAGS} --commit-lock-file $$input; \
	done

flake-update-nixos-release:
	inputs="nixpkgs-nixos-release home-manager-nixos-release nixvim-nixos-release plasma-manager-nixos-release sops-nix-nixos-release"; \
	for input in $$inputs; do \
		$(NIX) flake update ${NIX_EXTRA_FLAGS} --commit-lock-file $$input; \
	done

flake-update-nixvim:
	inputs="nixvim-darwin-unstable nixvim-darwin-release nixvim-nixos-unstable nixvim-nixos-release"; \
	for input in $$inputs; do \
		$(NIX) flake update ${NIX_EXTRA_FLAGS} --commit-lock-file $$input; \
	done

flake-update-homebrew:
	inputs="nix-homebrew homebrew-core homebrew-cask homebrew-bundle"; \
	for input in $$inputs; do \
		$(NIX) flake update ${NIX_EXTRA_FLAGS} --commit-lock-file $$input; \
	done

# Function to send notifications with fallbacks
define notify_linux
	if [ -n "$$DISPLAY" ] && command -v notify-send >/dev/null 2>&1; then \
		notify-send "$(1)" "Nix configuration" 2>/dev/null || echo "$(1)"; \
	elif [ -n "$$DISPLAY" ] && command -v kdialog >/dev/null 2>&1; then \
		kdialog --passivepopup "$(1)" 5 2>/dev/null || echo "$(1)"; \
	elif [ -n "$$DISPLAY" ] && command -v zenity >/dev/null 2>&1; then \
		zenity --info --text="$(1)" --timeout=5 2>/dev/null || echo "$(1)"; \
	else \
		echo "$(1)"; \
	fi
endef

# Test build for current machine (dry-run, no switch)
HOSTNAME := $(shell hostname)
ifeq (${PLATFORM}, Darwin)
test-build:
	$(NIX) build .#darwinConfigurations.${HOSTNAME}.system --dry-run ${NIX_EXTRA_FLAGS}
else
test-build:
	$(NIX) build .#nixosConfigurations.${HOSTNAME}.config.system.build.toplevel --dry-run
endif

# NixOS rebuild targets
rebuild-nixos/generic: addall
	sudo -H -E $(NIXOS_REBUILD) switch $(COMMON_REBUILD_FLAGS) && \
		$(call notify_linux,🟢 NixOS rebuild successful!) || \
		$(call notify_linux,🔴 NixOS rebuild failed!)

rebuild-nixos/impure: addall
	sudo -H -E $(NIXOS_REBUILD) switch --impure $(COMMON_REBUILD_FLAGS) && \
		$(call notify_linux,🟢 NixOS rebuild successful!) || \
		$(call notify_linux,🔴 NixOS rebuild failed!)

rebuild-nixos/a3:
	sudo $(NIXOS_REBUILD) switch $(COMMON_REBUILD_FLAGS) --build-host a3 && \
		$(call notify_linux,🟢 NixOS rebuild successful (built on a3)!) || \
		$(call notify_linux,🔴 NixOS rebuild failed!)

rebuild-nixos/a3-user:
	$(NIXOS_REBUILD) switch $(COMMON_REBUILD_FLAGS) --build-host a3 --sudo && \
		$(call notify_linux,🟢 NixOS rebuild successful (built on a3)!) || \
		$(call notify_linux,🔴 NixOS rebuild failed!)

# Darwin-specific rebuild target
rebuild-darwin: addall
	# NIXPKGS_ALLOW_UNFREE=1 is needed for unfree packages like codeium when using --impure
	NIXPKGS_ALLOW_UNFREE=1 sudo -H -E $(DARWIN_REBUILD) switch --impure $(COMMON_REBUILD_FLAGS) && \
		osascript -e 'display notification "🟢 Darwin rebuild successful!" with title "Nix configuration"' || \
		osascript -e 'display notification "🔴 Darwin rebuild failed!" with title "Nix configuration"'

# Loop rebuild with sudo refresh (timer only, no file watching)
rebuild-loop:
	@watchman-rebuild --loop --no-watch $(CURDIR)

# Watch for file changes and also rebuild on a timer
rebuild-watch-loop:
	@watchman-rebuild --loop $(CURDIR)

# Watchman rebuild (platform-independent, identical behavior)
rebuild-watchman:
	@watchman-rebuild $(CURDIR)

# Platform-specific aliases (kept for backwards compatibility)
rebuild-watchman-nixos: rebuild-watchman
rebuild-watchman-darwin: rebuild-watchman

# Devcontainer: start and exec into container with Claude Code
devcontainer:
	devcontainer up --workspace-folder .
	devcontainer exec --workspace-folder . npx @anthropic-ai/claude-code --dangerously-skip-permissions

# Devcontainer rebuild: force rebuild container
devcontainer-rebuild:
	devcontainer up --workspace-folder . --remove-existing-container --build-no-cache

