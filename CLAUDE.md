# NixOS Config Project Instructions

Scripts in `home/scripts/` are automatically processed by `home/scripts.nix` which:
- Automatically makes scripts executable 
- Handles shebangs for different script types (bash, fish, python, go, nu)
- Creates binary packages in the Nix store

**Do not use `chmod +x` on scripts** - the Nix build system handles permissions automatically.