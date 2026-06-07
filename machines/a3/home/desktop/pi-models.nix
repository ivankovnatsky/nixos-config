{
  config,
  pkgs,
  ...
}:

let
  homePath = config.home.homeDirectory;

  # pi-coding-agent custom providers / models.
  # Docs: https://github.com/earendil-works/pi-coding-agent/blob/main/docs/models.md
  # File is reloaded each time `/model` is opened in pi — no restart needed.
  piModels = {
    providers = {
    };
  };

  # `pkgs.formats.json` pretty-prints (2-space indent) so the deployed
  # file stays human-readable, unlike `builtins.toJSON` which collapses
  # everything onto one line.
  piModelsJson = (pkgs.formats.json { }).generate "pi-models.json" piModels;
in
{
  local.tools.settings.files = [
    {
      source = "${piModelsJson}";
      target = "${homePath}/.pi/agent/models.json";
      mode = "0644";
    }
  ];
}
