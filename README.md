# nix-config

A declarative multi-system Nix Flake managing macOS (via `nix-darwin`) and
Linux (via `NixOS`) hosts alongside user environments configured with
`home-manager`.

## Structure

```
flake.nix              Flake inputs and configuration entry points
flake/                 Flake helpers and system configuration builders
machines/<hostname>/   Host-specific system and home-manager configurations
modules/               Custom and reusable modules for Darwin, NixOS, and Home Manager
home/                  Modular home-manager profiles and application configurations
packages/              In-tree package definitions and custom tool wrappers
overlays/              Nixpkgs overlays
secrets/               Encrypted secrets managed with sops-nix
```
