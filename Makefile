PLATFORM := $(shell uname)

default:
ifeq (${PLATFORM}, Darwin)
	darwin-rebuild switch --verbose -L --flake . && \
	osascript -e 'display notification "Darwin rebuild completed!" with title "Nix configuration"'
else
	nixos-rebuild switch --use-remote-sudo --verbose -L --flake .
endif

rebuild-impure/nixos:
	nixos-rebuild switch --use-remote-sudo --impure --verbose -L --flake .
