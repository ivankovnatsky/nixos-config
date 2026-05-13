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
      inherit (cfg) goPath;
      goBin = "${cfg.goPath}/bin";
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
    "go"
    "mcp"
    "curlShell"
    "gitRepos"
    "files"
    "brew"
  ];
  enabledSections = filter (
    section:
    builtins.hasAttr section cfg.settings
    && cfg.settings.${section} != [ ]
    && cfg.settings.${section} != { }
  ) toolsSections;
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

    goPath = mkOption {
      type = types.str;
      readOnly = true;
      default =
        if cfg.toolsPrefix == config.home.homeDirectory then
          "${cfg.toolsPrefix}/go"
        else
          "${cfg.toolsPrefix}/.go";
      defaultText = literalExpression ''
        if toolsPrefix == $HOME then "$HOME/go" else "$\{toolsPrefix}/.go"
      '';
      description = ''
        GOPATH for this user, derived from `toolsPrefix`. Dotted `.go`
        when the workspace lives outside `$HOME` (external storage),
        plain `go` otherwise. Consumed by both this module (for
        `go install` binaries) and `home/go.nix` (for `GOPATH`).
      '';
    };

    settings = mkOption {
      type = types.submodule {
        freeformType = types.attrsOf types.anything;
        options.files = mkOption {
          type = types.listOf (types.attrsOf types.anything);
          default = [ ];
          description = "Files to deploy via the tools binary. Concatenated across modules.";
        };
      };
      default = { };
      description = "Native tools CLI configuration, serialized as JSON for activation.";
    };
  };

  config = mkIf (cfg.enable && enabledSections != [ ]) {
    # Home-manager activation runs with a sanitized PATH and no shell
    # rc files, so `go install` cannot find `go` or the `git` it
    # invokes to fetch modules. We disable cgo because the only C
    # toolchain we could put on PATH here is Nix's clang-wrapper,
    # which has no macOS SDK library search paths configured — cgo
    # links then fail with `library not found for -lresolv` and
    # similar. Pure-Go binaries are sufficient for the packages we
    # actually install (rclone, etc.).
    home.activation.manageTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${lib.optionalString (lib.elem "go" enabledSections) ''
        export PATH="${pkgs.go}/bin:${pkgs.git}/bin:$PATH"
        export CGO_ENABLED=0
      ''}
      ${inputs.tools.packages.${pkgs.system}.default}/bin/tools \
        deploy \
        --approve \
        ${scopeFlags} \
        --config ${configJson}
    '';
  };
}
