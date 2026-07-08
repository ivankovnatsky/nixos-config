{ pkgs, ... }:

let
  configJson = (pkgs.formats.json { }).generate "summarize-config.json" {
    cache.enabled = false;
    cli.enabled = [ "codex" ];
    model = "cli/codex";
    output.length = "12k";
  };
in
{
  home.file.".summarize/config.json".source = configJson;
}
