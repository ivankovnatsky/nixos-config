{ pkgs, ... }:

{
  imports = [
    ../../home/transmission.nix
    ../../home/workstation.nix
    ../../home/firefox-config.nix
    ../../home/amethyst.nix
    ../../home/vim
    ../../home/lsd.nix
  ];

  variables = {
    purpose = "work";
    editor = "nvim";
    darkMode = false;
  };

  # https://home-manager-options.extranix.com/?query=programs.direnv.&release=release-23.11
  programs = {
    direnv = {
      enable = true;
      enableZshIntegration = true; # see note on other shells below
      nix-direnv.enable = true;
    };
  };

  home = {
    packages =
      with pkgs; [
        aria
        defaultbrowser
        typst
        typstfmt
        killport
        kor
        docker-client
      ];

    # c) For `nix-env`, `nix-build`, `nix-shell` or any other Nix command you can add
    # { allowUnfree = true; }
    # to ~/.config/nixpkgs/config.nix.
    file.".config/nixpkgs/config.nix".text = ''
      { allowUnfree = true; }
    '';
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };
}
