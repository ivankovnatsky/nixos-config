{ config, pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;
  fontSizeT = if config.device.graphicsEnv == "xorg" then 7.5 else 9.5;
  fontSize = if isDarwin then 13 else fontSizeT;

in
{
  # Show all available options:

  # ```console
  # ghostty +show-config --default --docs
  # ```
  home.file.".config/ghostty/config".text = ''
    adjust-cell-height = 8%
    adjust-cell-width =
    font-family = ${config.flags.fontGeneral}
    font-size = ${builtins.toString fontSize}
    font-thicken = true
    # `ghostty +list-themes`
    theme = dark:Apple System Colors,light:Apple System Colors Light
    auto-update = off
    # window-decoration = false
    # macos-titlebar-style = hidden
    copy-on-select = true
    macos-option-as-alt = true
    # keybind = global:cmd+escape=toggle_quick_terminal
    keybind = cmd+down=jump_to_prompt:1
    keybind = cmd+up=jump_to_prompt:-1
  '';
}
