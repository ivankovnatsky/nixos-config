{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.tools;

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
      bun = {
        inherit (cfg.bun) packages configFile;
      };
      # Backward compatibility
      npm = {
        inherit (cfg.npm) packages configFile;
      };
      uv = {
        inherit (cfg.uv) packages;
      };
      mcp = {
        inherit (cfg.mcp) servers;
      };
      inherit (cfg) curlShell;
      inherit (cfg) stateFile;
      paths = {
        bunBin = "${config.home.homeDirectory}/.bun/bin";
        npmBin = "${config.home.homeDirectory}/.npm/bin";
        uvBin = "${config.home.homeDirectory}/.local/bin";
        claudeCli = "${config.home.homeDirectory}/.local/bin/claude";
        bun = "${pkgs.bun}/bin";
        uv = "${pkgs.uv}/bin";
        nodejs = "${pkgs.nodejs}/bin";
        python = "${pkgs.python313}/bin";
        tar = "${pkgs.gnutar}/bin";
        gzip = "${pkgs.gzip}/bin";
        curl = "${pkgs.curl}/bin";
        bash = "${pkgs.bash}/bin";
        perl = "${pkgs.perl}/bin";
        coreutils = "${pkgs.coreutils}/bin";
      };
    }
  );
in
{
  options.local.tools = {
    enable = mkEnableOption "declarative tools management (npm, uv, mcp)";

    stateFile = mkOption {
      type = types.path;
      default = "${config.home.homeDirectory}/.config/home-manager/tools/state.json";
      description = "Path to state file tracking installed components";
    };

    bun.packages = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Packages to install globally via bun (package name -> binary name)";
      example = {
        "npm-groovy-lint" = "npm-groovy-lint";
        "@google/gemini-cli" = "gemini";
      };
    };

    bun.configFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Content for .bunfig.toml file (only created if set and file doesn't exist)";
    };

    # Backward compatibility - deprecated, use bun.packages instead
    npm.packages = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Deprecated: use bun.packages instead. NPM packages to install globally via bun.";
    };

    npm.configFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Deprecated: use bun.configFile instead.";
    };

    uv.packages = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Python packages to install via uv (package name -> binary name)";
      example = {
        "osxphotos" = "osxphotos";
        "ruff" = "ruff";
      };
    };

    mcp.servers = mkOption {
      type = types.attrsOf mcpServerType;
      default = { };
      description = "MCP servers to configure";
    };

    curlShell = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "URLs to install via curl piped to shell (URL -> shell interpreter)";
      example = {
        "https://claude.ai/install.sh" = "bash";
        "https://example.com/setup.sh" = "sh";
      };
    };
  };

  config = mkIf cfg.enable {
    home.activation.manageTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.python3}/bin/python3 ${./packages.py} \
        --config ${configJson}
    '';
  };
}
