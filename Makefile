# https://stackoverflow.com/a/30176470
.DEFAULT_GOAL := default

PLATFORM := $(shell uname)
# TODO: This is temporary until we figure out how to properly configure nix.conf
# Currently determinate.nix doesn't support nix.enable in darwin configuration
# Remove these flags once we have proper nix configuration
NIX_EXTRA_FLAGS := --extra-experimental-features flakes --extra-experimental-features nix-command

# Common flags for rebuild commands
COMMON_REBUILD_FLAGS := --verbose -L --flake .
NIXOS_EXTRA_FLAGS := --use-remote-sudo

# Mark targets that don't create files as .PHONY so Make will always run them
.PHONY: default darwin nixos rebuild/nixos rebuild-impure/nixos trigger-rebuild flake-update-main flake-update-nixvim flake-update-homebrew rebuild-watchman rebuild-watchman-nixos

# Default target will run rebuild and start watchman based on platform
ifeq (${PLATFORM}, Darwin)
default: darwin rebuild-watchman
else
default: nixos rebuild-watchman-nixos
endif

# Darwin-specific rebuild target
darwin:
	# NIXPKGS_ALLOW_UNFREE=1 is needed for unfree packages like codeium when using --impure
	NIXPKGS_ALLOW_UNFREE=1 darwin-rebuild switch --impure $(COMMON_REBUILD_FLAGS) && \
		osascript -e 'display notification "🟢 Darwin rebuild successful!" with title "Nix configuration"' || \
		osascript -e 'display notification "🔴 Darwin rebuild failed!" with title "Nix configuration"'

# FIXME:
# ```console
# filesystem error: in create_hard_link: File exists
# ["/nix/store/.links/04sbnlzwypkihxv6ah7yzb5673c7zdwrj93rxiz2f3xn5wkq56vl"]
# ["/nix/store/.tmp-link-6248-1531891506"] error: some substitutes for the
# 	outputs of derivation
# 	'/nix/store/dckqp5p9gxswfh3k9hpywhw1n311nw20-vscode-extension-ms-vscode-makefile-tools-0.6.0.drv'
# 	failed (usually happens due to networking issues); try '--fallback' to build
# 	derivation from source copying path
# 	'/nix/store/p3l68bkq6181njhrkspk3gpkkipxdy4i-python3.12-mypy-extensions-1.0.0'
# 	from 'https://cache.nixos.org'...
# ```
trigger-rebuild:
	while true; do touch .trigger-rebuild && sleep 1; done

flake-update-main:
	inputs="nixpkgs darwin home-manager"; \
	for input in $$inputs; do \
		nix flake update ${NIX_EXTRA_FLAGS} --commit-lock-file $$input; \
	done

flake-update-nixvim:
	nix flake update ${NIX_EXTRA_FLAGS} --commit-lock-file nixvim

flake-update-homebrew:
	inputs="nix-homebrew homebrew-core homebrew-cask homebrew-bundle"; \
	for input in $$inputs; do \
		nix flake update ${NIX_EXTRA_FLAGS} --commit-lock-file $$input; \
	done

rebuild-watchman:
	while true; do \
		watchman-make \
			--pattern \
				'**/*' \
			--target darwin; \
		echo "watchman-make exited, restarting..."; \
		sleep 1; \
	done

# NixOS rebuild targets
rebuild/nixos:
	nixos-rebuild switch $(NIXOS_EXTRA_FLAGS) $(COMMON_REBUILD_FLAGS)

# Alias for consistency with darwin target
nixos: rebuild/nixos

rebuild-impure/nixos:
	nixos-rebuild switch --impure $(NIXOS_EXTRA_FLAGS) $(COMMON_REBUILD_FLAGS)

# NixOS-specific watchman rebuild target
rebuild-watchman-nixos:
	while true; do \
		watchman-make \
			--pattern \
				'**/*' \
			--target rebuild/nixos; \
		echo "watchman-make exited, restarting..."; \
		sleep 1; \
	done
