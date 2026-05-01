{
  # direnv binary and nix-direnv are installed via Homebrew (see
  # darwin/homebrew.nix). This file declares the user-level config that
  # `programs.direnv` used to manage.
  home.file = {
    ".config/direnv/direnv.toml".text = ''
      [global]
      warn_timeout = "5m"

      [whitelist]
      prefix = ["/Users/Ivan.Kovnatskyi"]
    '';

    ".config/direnv/direnvrc".text = ''
      source /opt/homebrew/share/nix-direnv/direnvrc
    '';
  };
}
