{ pkgs, ... }:

let editorName = "nvim";

in
{
  imports = [
    ./bluetooth.nix
    ./boot.nix
    ./chromium.nix
    ./documentation.nix
    ./fonts.nix
    ./networking.nix
    ./nextdns.nix
    ./opengl.nix
    ./packages.nix
    ./pipewire.nix
    ./security.nix
    ./services.nix
    ./users.nix
    ./xdg.nix

    ../modules/default.nix
    ../modules/secrets.nix
  ];

  environment = {
    variables = {
      AWS_VAULT_BACKEND = "pass";
      EDITOR = editorName;
      LPASS_AGENT_TIMEOUT = "0";
      VISUAL = editorName;
    };
  };

  hardware.video.hidpi.enable = true;
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Kiev";
  sound.enable = true;

  programs = {
    seahorse.enable = true;
    dconf.enable = true;
  };

  nix.autoOptimiseStore = true;

  nixpkgs.config.allowUnfree = true;

  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}
