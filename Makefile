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
