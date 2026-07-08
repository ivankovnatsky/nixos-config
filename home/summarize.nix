{ pkgs, ... }:

let
  configJson = (pkgs.formats.json { }).generate "summarize-config.json" {
    cache.enabled = false;
    output.length = "12k";
  };
in
{
  home.file.".summarize/config.json".source = configJson;
}
