{ config, pkgs, ... }:

let
  basedir = "${config.flags.homeWorkPath}/Worktrees";
in
{
  home.packages = [ pkgs.gwq ];

  xdg.configFile."gwq/config.toml".text = ''
    [worktree]
    basedir = "${basedir}"
    auto_mkdir = true

    [finder]
    preview = true

    [naming]
    template = "{{.Host}}/{{.Owner}}/{{.Repository}}/{{.Branch}}"

    [naming.sanitize_chars]
    "/" = "-"
    ":" = "-"

    [cd]
    launch_shell = true

    [ui]
    icons = true
    tilde_home = true

    [[repository_settings]]
    repository = "${config.flags.homeWorkPath}/Sources/github.com/ivankovnatsky/nix-config"
    copy_files = []
    setup_commands = []
  '';
}
