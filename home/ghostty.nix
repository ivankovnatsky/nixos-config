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
    theme = 3024 Night
    auto-update = off
    copy-on-select = true
    macos-option-as-alt = true
    ${if config.flags.purpose == "home" then ''
      window-decoration = false
      macos-titlebar-style = hidden
    '' else ""}
  '';
}
