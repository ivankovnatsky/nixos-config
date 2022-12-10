rebuild/darwin:
	darwin-rebuild switch --verbose -L --flake .

rebuild/nixos:
	nixos-rebuild switch --use-remote-sudo --verbose -L --flake .

rebuild-impure/nixos:
	nixos-rebuild switch --use-remote-sudo --impure --verbose -L --flake .
