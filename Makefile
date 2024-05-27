PLATFORM := $(shell uname)

all: default darwin-rebuild-watch rebuild-impure/nixos

default:
ifeq (${PLATFORM}, Darwin)
	darwin-rebuild switch --verbose -L --flake . && \
		osascript -e 'display notification "🟢 Darwin rebuild successful!" with title "Nix configuration"' || \
		osascript -e 'display notification "🔴 Darwin rebuild failed!" with title "Nix configuration"'
else
	nixos-rebuild switch --use-remote-sudo --verbose -L --flake .
endif

darwin-rebuild-watch:
	echo "Watching for changes..."; \
	git ls-files | xargs fswatch -o | while read -r event; do \
		echo "Change detected, running make to rebuild configuration..."; \
		$(MAKE) default; \
	done; \

rebuild-impure/nixos:
	nixos-rebuild switch --use-remote-sudo --impure --verbose -L --flake .
