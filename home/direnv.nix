{ pkgs, ... }:
{
  # direnv binary is installed via Homebrew (see darwin/homebrew.nix);
  # nix-direnv is not a Homebrew formula, so its direnvrc comes from
  # nixpkgs. This file declares the user-level config that
  # `programs.direnv` used to manage.
  home.file = {
    ".config/direnv/direnv.toml".text = ''
      [global]
      warn_timeout = "5m"
    '';

    ".config/direnv/direnvrc".text = ''
      source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc
    '';
  };
}
