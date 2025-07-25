{ config, pkgs, ... }:

let
  jsonFormat = pkgs.formats.json { };
  
  # Common extensions list for all editors
  commonExtensions = [
    "vscodevim.vim"
    "jnoortheen.nix-ide"
    "hashicorp.terraform"
    "eamodio.gitlens"
    "ms-vscode.makefile-tools"
    "ms-python.python"
    "hashicorp.hcl"
    "golang.go"
    "ms-azuretools.vscode-docker"
    # Nushell
    "thenuprojectcontributors.vscode-nushell-lang"
    # "saoudrizwan.claude-dev"
  ];
  
  # VSCode specific extensions
  vscodeExtensions = commonExtensions ++ [
    "GitHub.copilot"
    "atlassian.atlascode"
  ];
  
  # Generate extension management script for the given app and extensions
  makeExtensionScript = app: appPath: action: extensions: ''
    #!/usr/bin/env bash
    
    # Use direct binary path approach which is more reliable
    BINARY="${appPath}"
    if [ ! -f "$BINARY" ]; then
      echo "Error: Could not find ${app} at $BINARY"
      echo "Please make sure ${app} is installed and update the path if necessary."
      exit 1
    fi
    
    ${builtins.concatStringsSep "\n" (map (ext: "\"$BINARY\" --${action}-extension ${ext}") extensions)}
  '';

  editorSettings = {
    "[nix]" = {
      "editor.tabSize" = 2;
    };
    "diffEditor.ignoreTrimWhitespace" = false;
    "diffEditor.renderSideBySide" = false;
    "editor.lineNumbers" = "relative";
    "editor.minimap.enabled" = false;
    "editor.renderFinalNewline" = "off";
    "editor.renderLineHighlight" = "all";
    "extensions.autoCheckUpdates" = false;
    "extensions.autoUpdate" = false;
    "extensions.ignoreRecommendations" = true;
    "files.autoSave" = "off";
    "files.enableTrash" = false;
    "files.insertFinalNewline" = true;
    "files.trimFinalNewlines" = true;
    "git.autofetch" = "all";
    "git.openRepositoryInParentFolders" = "always";
    "scm.diffDecorations" = "all";
    "security.workspace.trust.enabled" = false;
    "terminal.integrated.fontFamily" = "Hack Nerd Font";
    "update.mode" = "manual";
    "vim.relativeLineNumbers" = true;
    "window.autoDetectColorScheme" = true;
    "window.commandCenter" = 1;
    "windsurf.autoExecutionPolicy" = "off";
    "windsurf.autocompleteSpeed" = "default";
    "windsurf.chatFontSize" = "default";
    "windsurf.explainAndFixInCurrentConversation" = true;
    "windsurf.openRecentConversation" = true;
    "windsurf.rememberLastModelSelection" = true;
    "workbench.colorTheme" = "Auto";
    "workbench.preferredDarkColorTheme" = "Default Dark+";
    "workbench.preferredLightColorTheme" = "Default Light+";
    "cursor.composer.shouldAutoSaveNonAgent" = false;
    "telemetry.enableTelemetry" = false;
  };
in
{
  # VSCode configuration - installed via Homebrew
  # Reference: https://github.com/nix-community/home-manager/blob/master/modules/programs/vscode.nix
  home.file."Library/Application Support/Code/User/settings.json".source =
    jsonFormat.generate "vscode-user-settings" editorSettings;
  
  # VSCode extensions installation script
  home.file."Library/Application Support/Code/User/install-extensions.sh" = {
    executable = true;
    text = makeExtensionScript "Visual Studio Code" "/opt/homebrew/bin/code" "install" vscodeExtensions;
  };
  
  # VSCode extensions uninstallation script
  home.file."Library/Application Support/Code/User/uninstall-extensions.sh" = {
    executable = true;
    text = makeExtensionScript "Visual Studio Code" "/opt/homebrew/bin/code" "uninstall" vscodeExtensions;
  };
  
  # VSCode extensions list for reference
  home.file."Library/Application Support/Code/User/extensions-list.txt".text = 
    builtins.concatStringsSep "\n" (builtins.filter (ext: builtins.substring 0 1 ext != "#") vscodeExtensions);

  # Add Cursor settings with proper formatting
  home.file."Library/Application Support/Cursor/User/settings.json".source =
    jsonFormat.generate "cursor-user-settings" editorSettings;
    
  # Cursor extensions installation script
  home.file."Library/Application Support/Cursor/User/install-extensions.sh" = {
    executable = true;
    text = makeExtensionScript "Cursor" "/Applications/Cursor.app/Contents/Resources/app/bin/cursor" "install" commonExtensions;
  };
  
  # Cursor extensions uninstallation script
  home.file."Library/Application Support/Cursor/User/uninstall-extensions.sh" = {
    executable = true;
    text = makeExtensionScript "Cursor" "/Applications/Cursor.app/Contents/Resources/app/bin/cursor" "uninstall" commonExtensions;
  };
  
  # Cursor extensions list for reference
  home.file."Library/Application Support/Cursor/User/extensions-list.txt".text = 
    builtins.concatStringsSep "\n" (builtins.filter (ext: builtins.substring 0 1 ext != "#") commonExtensions);

  # Windsurf
  home.file."Library/Application Support/Windsurf/User/settings.json".source =
    jsonFormat.generate "windsurf-user-settings" editorSettings;
    
  # Windsurf extensions installation script
  home.file."Library/Application Support/Windsurf/User/install-extensions.sh" = {
    executable = true;
    text = makeExtensionScript "Windsurf" "/Applications/Windsurf.app/Contents/Resources/app/bin/windsurf" "install" commonExtensions;
  };
  
  # Windsurf extensions uninstallation script
  home.file."Library/Application Support/Windsurf/User/uninstall-extensions.sh" = {
    executable = true;
    text = makeExtensionScript "Windsurf" "/Applications/Windsurf.app/Contents/Resources/app/bin/windsurf" "uninstall" commonExtensions;
  };
  
  # Windsurf extensions list for reference
  home.file."Library/Application Support/Windsurf/User/extensions-list.txt".text = 
    builtins.concatStringsSep "\n" (builtins.filter (ext: builtins.substring 0 1 ext != "#") commonExtensions);
}
