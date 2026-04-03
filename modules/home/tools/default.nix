{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.tools;

  packageType = types.submodule {
    options = {
      binary = mkOption {
        type = types.str;
        description = "Binary name produced by the package";
      };
      version = mkOption {
        type = types.str;
        default = "latest";
        description = "Package version to install (e.g. '1.2.3' or 'latest')";
      };
      postInstall = mkOption {
        type = types.str;
        default = "";
        description = "Shell command to run inside the package directory after install";
        example = "node scripts/postinstall-bundled-plugins.mjs";
      };
      subpackages = mkOption {
        type = types.attrsOf (
          types.submodule {
            options.version = mkOption {
              type = types.str;
              default = "latest";
              description = "Version to install";
            };
          }
        );
        default = { };
        description = "Additional npm packages to install inside this package's node_modules (for missing runtime deps)";
        example = {
          "@buape/carbon" = {
            version = "0.0.0-beta-20260327000044";
          };
          "grammy" = { };
        };
      };
    };
  };

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
        type = types.nullOr types.str;
        default = null;
        description = "URL for the MCP server (required for http/sse transport)";
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
      args = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Arguments for stdio transport (e.g. [\"npx\" \"@playwright/mcp@latest\"])";
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
      inherit (cfg) gitRepos;
      inherit (cfg) stateFile;
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
        tar = "${pkgs.gnutar}/bin";
        gzip = "${pkgs.gzip}/bin";
        curl = "${pkgs.curl}/bin";
        bash = "${pkgs.bash}/bin";
        perl = "${pkgs.perl}/bin";
        coreutils = "${pkgs.coreutils}/bin";
        git = "${pkgs.git}/bin";
      };
    }
  );
in
{
  options.local.tools = {
    enable = mkEnableOption "declarative tools management (npm, uv, mcp)";

    toolsPrefix = mkOption {
      type = types.str;
      default = config.home.homeDirectory;
      description = "Base directory for tool installations (npm, bun, uv). Defaults to home directory.";
    };

    stateFile = mkOption {
      type = types.path;
      default = "${config.home.homeDirectory}/.config/home-manager/tools/state.json";
      description = "Path to state file tracking installed components";
    };

    bun.packages = mkOption {
      type = types.attrsOf packageType;
      default = { };
      description = "Packages to install globally via bun";
      example = {
        "npm-groovy-lint" = {
          binary = "npm-groovy-lint";
        };
        "@openai/codex" = {
          binary = "codex";
          version = "0.1.0";
        };
      };
    };

    bun.configFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Content for .bunfig.toml file (only created if set and file doesn't exist)";
    };

    npm.packages = mkOption {
      type = types.attrsOf packageType;
      default = { };
      description = "Packages to install globally via npm";
      example = {
        "@google/gemini-cli" = {
          binary = "gemini";
        };
      };
    };

    npm.configFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Content for .npmrc file (only created if set and file doesn't exist)";
    };

    uv.packages = mkOption {
      type = types.attrsOf packageType;
      default = { };
      description = "Python packages to install via uv";
      example = {
        "osxphotos" = {
          binary = "osxphotos";
        };
        "ruff" = {
          binary = "ruff";
          version = "0.4.0";
        };
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

    gitRepos = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Git repositories to clone (destination path -> repo URL)";
      example = {
        "~/.claude/skills/terraform-skill" = "https://github.com/antonbabenko/terraform-skill";
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
