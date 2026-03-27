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
    keybind = ctrl+1=goto_tab:1
    keybind = ctrl+digit_1=goto_tab:1
    keybind = ctrl+2=goto_tab:2
    keybind = ctrl+digit_2=goto_tab:2
    keybind = ctrl+3=goto_tab:3
    keybind = ctrl+digit_3=goto_tab:3
    keybind = ctrl+4=goto_tab:4
    keybind = ctrl+digit_4=goto_tab:4
    keybind = ctrl+5=goto_tab:5
    keybind = ctrl+digit_5=goto_tab:5
    keybind = ctrl+6=goto_tab:6
    keybind = ctrl+digit_6=goto_tab:6
    keybind = ctrl+7=goto_tab:7
    keybind = ctrl+digit_7=goto_tab:7
    keybind = ctrl+8=goto_tab:8
    keybind = ctrl+digit_8=goto_tab:8
    keybind = ctrl+9=goto_tab:9
    keybind = ctrl+digit_9=goto_tab:9

    keybind = global:f12=toggle_quick_terminal
    quick-terminal-position = top
    quick-terminal-size = 75%
    quick-terminal-animation-duration = 0.15
  '';
}
