# Requires: System Settings > Privacy & Security > Accessibility > allow bash
{
  local.launchd.services.close-zscaler = {
    enable = true;
    type = "user-agent";
    command = builtins.concatStringsSep " " [
      "/usr/bin/osascript -e"
      "'tell app \"Terminal\" to do script"
      "\"sleep 60;"
      "osascript -e"
      "'\"'\"'tell application \\\"System Events\\\""
      "to tell process \\\"Zscaler\\\""
      "to if exists (window 1)"
      "then click button 1 of window 1'\"'\"';"
      "exit\"'"
    ];
    runAtLoad = true;
    keepAlive = false;
  };
}
