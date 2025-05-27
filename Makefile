# https://stackoverflow.com/a/30176470
.DEFAULT_GOAL := default

# Mark targets that don't create files as .PHONY so Make will always run them
.PHONY: \
	default \
	\
	trigger-rebuild \
	\
	flake-update-main \
	flake-update-nixvim \
	flake-update-homebrew \
	\
	rebuild-nixos/generic \
	rebuild-nixos/impure \
	\
	rebuild-darwin \
	rebuild-darwin-sudo \
	\
	rebuild-watchman-nixos \
	\
	rebuild-watchman-darwin \
	rebuild-watchman-darwin-sudo

PLATFORM := $(shell uname)
# TODO: This is temporary until we figure out how to properly configure nix.conf
# Currently determinate.nix doesn't support nix.enable in darwin configuration
# Remove these flags once we have proper nix configuration
NIX_EXTRA_FLAGS := --extra-experimental-features flakes --extra-experimental-features nix-command

# Common flags for rebuild commands
COMMON_REBUILD_FLAGS := --verbose -L --flake .
NIXOS_EXTRA_FLAGS := --use-remote-sudo

# Default target will run rebuild and start watchman based on platform
ifeq (${PLATFORM}, Darwin)
default: rebuild-darwin rebuild-watchman-darwin
else
default: rebuild-nixos/generic rebuild-watchman-nixos
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

# NixOS rebuild targets
rebuild-nixos/generic:
	nixos-rebuild switch $(NIXOS_EXTRA_FLAGS) $(COMMON_REBUILD_FLAGS)

rebuild-nixos/impure:
	nixos-rebuild switch --impure $(NIXOS_EXTRA_FLAGS) $(COMMON_REBUILD_FLAGS)

# Darwin-specific rebuild target
rebuild-darwin:
	# NIXPKGS_ALLOW_UNFREE=1 is needed for unfree packages like codeium when using --impure
	NIXPKGS_ALLOW_UNFREE=1 darwin-rebuild switch --impure $(COMMON_REBUILD_FLAGS) && \
		osascript -e 'display notification "🟢 Darwin rebuild successful!" with title "Nix configuration"' || \
		osascript -e 'display notification "🔴 Darwin rebuild failed!" with title "Nix configuration"'

# Darwin-specific rebuild target with sudo
rebuild-darwin-sudo:
	# NIXPKGS_ALLOW_UNFREE=1 is needed for unfree packages like codeium when using --impure
	NIXPKGS_ALLOW_UNFREE=1 sudo -E darwin-rebuild switch --impure $(COMMON_REBUILD_FLAGS) && \
		osascript -e 'display notification "🟢 Darwin rebuild successful!" with title "Nix configuration"' || \
		osascript -e 'display notification "🔴 Darwin rebuild failed!" with title "Nix configuration"'

# NixOS-specific watchman rebuild target
rebuild-watchman-nixos:
	while true; do \
		watchman-make \
			--pattern \
				'**/*' \
			--target rebuild-nixos/generic; \
		echo "watchman-make exited, restarting..."; \
		sleep 1; \
	done

# Darwin-specific watchman rebuild target
rebuild-watchman-darwin:
	while true; do \
		watchman-make \
			--pattern \
				'**/*' \
			--target rebuild-darwin; \
		echo "watchman-make exited, restarting..."; \
		sleep 1; \
	done

# Darwin-specific watchman rebuild target with sudo
rebuild-watchman-darwin-sudo:
	while true; do \
		watchman-make \
			--pattern \
				'**/*' \
			--target rebuild-darwin-sudo; \
		echo "watchman-make exited, restarting..."; \
		sleep 1; \
	done
