{ config, ... }:
{
  # Show all available options:

  # ```console
  # ghostty +show-config --default --docs
  # ```
  home.file.".config/ghostty/config".text = ''
    adjust-cell-height = 8%
    adjust-cell-width =
    font-family = ${config.flags.fontGeneral}
    font-size = 13
    font-thicken = true
    # `ghostty +list-themes`
    theme = dark:3024 Night,light:3024 Day
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
