{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.local.manualPackages;

  mcpServerType = types.submodule {
    options = {
      scope = mkOption {
        type = types.enum [ "user" "project" ];
        default = "user";
        description = "MCP server scope";
      };
      transport = mkOption {
        type = types.enum [ "sse" "http" "stdio" ];
        description = "Transport protocol for MCP server";
      };
      url = mkOption {
        type = types.str;
        description = "URL for the MCP server";
      };
      headers = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "HTTP headers for the MCP server";
      };
      command = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Custom command override for complex installs";
      };
    };
  };

  configJson = pkgs.writeText "activation-config.json" (builtins.toJSON {
    npm = {
      packages = cfg.npm.packages;
      configFile = cfg.npm.configFile;
    };
    mcp = {
      servers = cfg.mcp.servers;
    };
    stateFile = cfg.stateFile;
    paths = {
      npmBin = "${config.home.homeDirectory}/.npm/bin";
      claudeCli = "${config.home.homeDirectory}/.npm/bin/claude";
      nodejs = "${pkgs.nodejs}/bin";
      python = "${pkgs.python313}/bin";
      tar = "${pkgs.gnutar}/bin";
      gzip = "${pkgs.gzip}/bin";
      curl = "${pkgs.curl}/bin";
    };
  });
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
      type = types.listOf types.str;
      default = [];
      description = "NPM packages to install globally";
    };

    npm.configFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Content for .npmrc file (only created if doesn't exist)";
    };

    mcp.servers = mkOption {
      type = types.attrsOf mcpServerType;
      default = {};
      description = "MCP servers to configure";
    };
  };

  config = mkIf cfg.enable {
    home.activation.manageManualPackages = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${pkgs.python3}/bin/python3 ${./manage-activation.py} \
        --config ${configJson}
    '';
  };
}
