{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.local.tools;

  generatedConfig = {
    paths = {
      bunBin = "${cfg.toolsPrefix}/.bun/bin";
      npmBin = "${cfg.toolsPrefix}/.npm/bin";
      uvBin = "${cfg.toolsPrefix}/.local/bin";
      uvToolDir = "${cfg.toolsPrefix}/.local/share/uv/tools";
      # Claude CLI always installs to ~/.local/bin (hardcoded in binary, not configurable)
      claudeCli = "${config.home.homeDirectory}/.local/bin/claude";
      bun = "${pkgs.bun}/bin";
      uv = "${pkgs.uv}/bin";
      nodejs = "${pkgs.nodejs}/bin";
      python = "${pkgs.python313}/bin";
    };
  };

  configJson = pkgs.writeText "tools-config.json" (
    builtins.toJSON (lib.recursiveUpdate generatedConfig cfg.settings)
  );

  toolsSections = [
    "bun"
    "npm"
    "uv"
    "mcp"
    "curlShell"
    "gitRepos"
    "files"
    "brew"
  ];
  enabledSections = filter (section: builtins.hasAttr section cfg.settings) toolsSections;
  scopeFlags = concatMapStringsSep " " (section: "--scope ${escapeShellArg section}") enabledSections;
in
{
  options.local.tools = {
    enable = mkEnableOption "native config-based tools management";

    toolsPrefix = mkOption {
      type = types.str;
      default = config.home.homeDirectory;
      description = "Base directory for tool installations (npm, bun, uv). Defaults to home directory.";
    };

    settings = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Native tools CLI configuration, serialized as JSON for activation.";
    };
  };

  config = mkIf (cfg.enable && enabledSections != [ ]) {
    home.activation.manageTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${inputs.tools.packages.${pkgs.system}.default}/bin/tools \
        deploy \
        --approve \
        ${scopeFlags} \
        --config ${configJson}
    '';
  };
}
