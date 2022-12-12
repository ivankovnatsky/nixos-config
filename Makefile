PLATFORM=$(shell uname)

default:
	@if [ ${PLATFORM} == "Darwin" ]; then \
		darwin-rebuild switch --verbose -L --flake . ; \
	else \
		nixos-rebuild switch --use-remote-sudo --verbose -L --flake . ; \
	fi

rebuild-impure/nixos:
	nixos-rebuild switch --use-remote-sudo --impure --verbose -L --flake .
