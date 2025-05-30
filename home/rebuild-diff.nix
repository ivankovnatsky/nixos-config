{ config, pkgs, ... }:

# Creating home file links in /Users/ivan
# Activating onFilesChange
# Activating regenDotTaskRc
# Activating report-changes
# /nix/store/lddi4qxinncymkws68dmsbsnnb7c4i5p-home-manager-generation/activate: line 348: oldGenPath: unbound variable
# # waiting for changes
# # Execute: `env NIXPKGS_ALLOW_UNFREE=1 darwin-rebuild switch --impure --verbose -L --flake .`
# building the system configuration...
# warning: Git tree '/Users/ivan/Sources/github.com/ivankovnatsky/nixos-config' is dirty    waiting for changes

# It does not work for the first time, so you shoud comment out import of this file
{
  # FIXME: For the first time this fails, we need to make sure this does not fail the rebuild.
  home.activation.report-changes = config.lib.dag.entryAnywhere ''
    ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff $oldGenPath $newGenPath
  '';
}
