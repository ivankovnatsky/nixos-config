{
  config,
  lib,
  ...
}:

let
  homePath = config.home.homeDirectory;
  isWork = config.flags.purpose == "work";
in
{
  sops.secrets.portkey-api-key = lib.mkIf isWork {
    key = "work/portkey/apiKey";
  };

  sops.templates."portkey.sh" = lib.mkIf isWork {
    content = builtins.concatStringsSep "\n" [
      "#!/bin/bash"
      "export ANTHROPIC_BASE_URL='https://api.portkey.ai'"
      "export ANTHROPIC_API_KEY=\"$(~/.claude/anthropic_key.sh)\""
      "export ANTHROPIC_CUSTOM_HEADERS=$'x-portkey-api-key: ${config.sops.placeholder.portkey-api-key}\\nx-portkey-provider: @anthropic'"
      "exec claude \"$@\""
      ""
    ];
    mode = "0500";
  };

  sops.templates."anthropic_key.sh" = lib.mkIf isWork {
    content = builtins.concatStringsSep "\n" [
      "#!/bin/bash"
      "echo \"${config.sops.placeholder.anthropic-api-key}\""
      ""
    ];
    mode = "0500";
  };

  home.activation.linkClaudeSettings = lib.mkIf isWork (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "${homePath}/.claude"
      $DRY_RUN_CMD ln -sf ${
        config.sops.templates."anthropic_key.sh".path
      } "${homePath}/.claude/anthropic_key.sh"
      $DRY_RUN_CMD ln -sf ${config.sops.templates."portkey.sh".path} "${homePath}/.claude/portkey.sh"
    ''
  );
}
