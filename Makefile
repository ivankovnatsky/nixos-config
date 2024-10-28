# https://stackoverflow.com/a/30176470
.DEFAULT_GOAL := default

PLATFORM := $(shell uname)

all: default rebuild-fswatch rebuild-watchman rebuild-impure/nixos

default:
ifeq (${PLATFORM}, Darwin)
	darwin-rebuild switch --verbose -L --flake . && \
		osascript -e 'display notification "🟢 Darwin rebuild successful!" with title "Nix configuration"' || \
		osascript -e 'display notification "🔴 Darwin rebuild failed!" with title "Nix configuration"'
else
	nixos-rebuild switch --use-remote-sudo --verbose -L --flake .
endif

machine-specific:
	darwin-rebuild switch --verbose -L --flake ".#Ivans-MBP0" && \
		osascript -e 'display notification "🟢 Darwin rebuild successful!" with title "Nix configuration"' || \
		osascript -e 'display notification "🔴 Darwin rebuild failed!" with title "Nix configuration"'

rebuild-fswatch:
	echo "Watching for changes..."; \
	git ls-files | xargs fswatch -o | while read -r event; do \
		echo "Change detected, running make to rebuild configuration..."; \
		$(MAKE) default; \
	done

rebuild-watchman:
	watchman-make \
		--pattern \
			'**/*.nix' \
			'**/*.sh' \
			'**/*.fish' \
			'**/*.lua' \
			'flake.lock' \
		--target default

rebuild-watchman-machine-specific:
	watchman-make \
		--pattern \
			'**/*.nix' \
			'**/*.sh' \
			'**/*.fish' \
			'**/*.lua' \
			'flake.lock' \
		--target machine-specific

rebuild-impure/nixos:
	nixos-rebuild switch --use-remote-sudo --impure --verbose -L --flake .
