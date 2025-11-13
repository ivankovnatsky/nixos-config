{ config, pkgs, ... }:

# Creating home file links in /Users/ivan
# Activating onFilesChange
# Activating regenDotTaskRc
# Activating report-changes
# /nix/store/lddi4qxinncymkws68dmsbsnnb7c4i5p-home-manager-generation/activate: line 348: oldGenPath: unbound variable
# # waiting for changes
# # Execute: `env NIXPKGS_ALLOW_UNFREE=1 darwin-rebuild switch --impure -L --flake .`
# building the system configuration...
# warning: Git tree '/Users/ivan/Sources/github.com/ivankovnatsky/nixos-config' is dirty    waiting for changes

# Now handles the first-time run case by checking if oldGenPath exists
{
  home.activation.report-changes = config.lib.dag.entryAnywhere ''
    if [[ -n "''${oldGenPath:-}" && -e "''${oldGenPath:-}" ]]; then
      ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff $oldGenPath $newGenPath
    else
      echo "No previous generation found. Skipping diff."
    fi
  '';
}
