{ pkgs, ... }:

let
  configJson = (pkgs.formats.json { }).generate "summarize-config.json" {
    output.length = "12k";
  };
in
{
  home.file.".summarize/config.json".source = configJson;
}
