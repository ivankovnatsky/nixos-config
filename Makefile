# https://stackoverflow.com/a/30176470
.DEFAULT_GOAL := default

PLATFORM := $(shell uname)

all: default rebuild-watchman rebuild-impure/nixos

default:
ifeq (${PLATFORM}, Darwin)
	darwin-rebuild switch --impure --verbose -L --flake . && \
		osascript -e 'display notification "🟢 Darwin rebuild successful!" with title "Nix configuration"' || \
		osascript -e 'display notification "🔴 Darwin rebuild failed!" with title "Nix configuration"'
else
	nixos-rebuild switch --use-remote-sudo --impure --verbose -L --flake .
endif

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

flake-update:
	nix flake update --commit-lock-file nixpkgs
	nix flake update --commit-lock-file darwin
	nix flake update --commit-lock-file home-manager

	nix flake update --commit-lock-file nix-homebrew
	nix flake update --commit-lock-file homebrew-core
	nix flake update --commit-lock-file homebrew-cask
	nix flake update --commit-lock-file homebrew-bundle

	nix flake update --commit-lock-file nixvim

rebuild-watchman:
	while true; do \
		watchman-make \
			--pattern \
				'**/*' \
			--target default; \
		echo "watchman-make exited, restarting..."; \
		sleep 1; \
	done

rebuild-impure/nixos:
	nixos-rebuild switch --use-remote-sudo --impure --verbose -L --flake .
