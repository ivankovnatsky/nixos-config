PLATFORM := $(shell uname)

default:
ifeq (${PLATFORM}, Darwin)
	darwin-rebuild switch --verbose -L --flake .
else
	nixos-rebuild switch --use-remote-sudo --verbose -L --flake .
endif

rebuild-impure/nixos:
	nixos-rebuild switch --use-remote-sudo --impure --verbose -L --flake .
