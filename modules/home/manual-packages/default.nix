{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.manualPackages;

  mcpServerType = types.submodule {
    options = {
      scope = mkOption {
        type = types.enum [
          "user"
          "project"
        ];
        default = "user";
        description = "MCP server scope";
      };
      transport = mkOption {
        type = types.enum [
          "sse"
          "http"
          "stdio"
        ];
        description = "Transport protocol for MCP server";
      };
      url = mkOption {
        type = types.str;
        description = "URL for the MCP server";
      };
      headers = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          HTTP headers for the MCP server.
          Supports @VARIABLE@ placeholders for secrets (use with secretPaths).
        '';
      };
      secretPaths = mkOption {
        type = types.attrsOf types.path;
        default = { };
        description = ''
          Map of variable names to secret file paths for header substitution.
          Example: { TOKEN = config.sops.secrets.token.path; }
          Used to replace @TOKEN@ in headers at runtime.
        '';
      };
      command = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Custom command override for complex installs";
      };
    };
  };

  configJson = pkgs.writeText "activation-config.json" (
    builtins.toJSON {
      npm = {
        inherit (cfg.npm) packages configFile;
      };
      mcp = {
        inherit (cfg.mcp) servers;
      };
      inherit (cfg) stateFile;
      paths = {
        npmBin = "${config.home.homeDirectory}/.npm/bin";
        claudeCli = "${config.home.homeDirectory}/.npm/bin/claude";
        bun = "${pkgs.bun}/bin";
        nodejs = "${pkgs.nodejs}/bin";
        python = "${pkgs.python313}/bin";
        tar = "${pkgs.gnutar}/bin";
        gzip = "${pkgs.gzip}/bin";
        curl = "${pkgs.curl}/bin";
      };
    }
  );
in
{
  options.local.manualPackages = {
    enable = mkEnableOption "declarative manual package management";

    stateFile = mkOption {
      type = types.path;
      default = "${config.home.homeDirectory}/.config/home-manager/manual-packages/state.json";
      description = "Path to state file tracking installed components";
    };

    npm.packages = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "NPM packages to install globally (package name -> binary name)";
      example = {
        "@anthropic-ai/claude-code" = "claude";
        "npm-groovy-lint" = "npm-groovy-lint";
      };
    };

    npm.configFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Content for .npmrc file (only created if doesn't exist)";
    };

    mcp.servers = mkOption {
      type = types.attrsOf mcpServerType;
      default = { };
      description = "MCP servers to configure";
    };
  };

  config = mkIf cfg.enable {
    home.activation.manageManualPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.python3}/bin/python3 ${./manage-activation.py} \
        --config ${configJson}
    '';
  };
}
