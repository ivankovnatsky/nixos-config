{ config, pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;
  fontSizeT = if config.device.graphicsEnv == "xorg" then 8.5 else 10.5;
  fontSize = if isDarwin then 13 else fontSizeT;
  shellIntegration = if config.flags.enableFishShell then "fish" else "zsh";

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
    theme = dark:Builtin Dark,light:Builtin Light
    auto-update = off
    # window-decoration = false
    # macos-titlebar-style = hidden
    copy-on-select = true
    split-divider-color = #555555
    window-padding-x = 8
    macos-option-as-alt = true
    keybind = cmd+down=jump_to_prompt:1
    keybind = cmd+up=jump_to_prompt:-1

    shell-integration = ${shellIntegration}
    window-inherit-working-directory = true

    # Quake-style quick terminal (F12 to toggle from anywhere)
    # On KDE Plasma, approve the "Global Shortcuts Requested" dialog on first launch
    keybind = ctrl+one=goto_tab:1
    keybind = ctrl+two=goto_tab:2
    keybind = ctrl+three=goto_tab:3
    keybind = ctrl+four=goto_tab:4
    keybind = ctrl+five=goto_tab:5
    keybind = ctrl+six=goto_tab:6
    keybind = ctrl+seven=goto_tab:7
    keybind = ctrl+eight=goto_tab:8
    keybind = ctrl+nine=goto_tab:9

    keybind = global:f12=toggle_quick_terminal
    quick-terminal-position = top
    quick-terminal-size = 75%
    quick-terminal-animation-duration = 0.15
  '';
}
