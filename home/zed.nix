{ pkgs, ... }:

{
  home.packages = with pkgs; [ nixd ];
  home.file.".config/zed/settings.json".text = ''
    // Zed settings
    //
    // For information on how to configure Zed, see the Zed
    // documentation: https://zed.dev/docs/configuring-zed
    //
    // To see all of Zed's default settings without changing your
    // custom settings, run the `zed: Open Default Settings` command
    // from the command palette
    {
      "theme": {
        "mode": "system",
        "light": "One Light",
        "dark": "One Dark"
      },
      "vim_mode": true,
      "relative_line_numbers": true,
      "telemetry": {
        "diagnostics": false,
        "metrics": false
      },
      "vim": {
        "use_system_clipboard": "never",
        "use_multiline_find": true,
        "use_smartcase_find": true,
        "toggle_relative_line_numbers": true
      },
      "ui_font_size": 13,
      "buffer_font_size": 13,
      // https://github.com/zed-industries/zed/discussions/7160
      "terminal": {
        "dock": "bottom",
        "font_family": "Hack Nerd Font"
      },
      "autosave": "on_focus_change",
      "tabs": {
        "git_status": true
      },
      // https://github.com/zed-industries/zed/discussions/6663#discussioncomment-10930390
      "experimental.theme_overrides": {
        "syntax": {
          "comment": {
            "font_style": "italic"
          }
        }
      },
      "auto_update": false,
      "buffer": {
        "ensure_final_newline_on_save": true,
        "show_end_of_line": false
      }
    }
  '';
}
