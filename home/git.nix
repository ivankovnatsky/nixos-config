{ pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin isLinux;

  homeCredentialHelper = if isDarwin then "osxkeychain" else "${pkgs.rbw}/bin/git-credential-rbw";
in
{
  home.packages = with pkgs; [
    gitAndTools.pre-commit
    git-crypt
    pinentry
    (rbw.override { withFzf = true; })
    tig
  ];

  programs.gh = {
    enable = true;

    settings = { };

    enableGitCredentialHelper = false;
  };

  programs.git = {
    enable = true;

    userEmail = "75213+ivankovnatsky@users.noreply.github.com";
    userName = "Ivan Kovnatsky";
    signing = {
      signByDefault = true;
      key = "75213+ivankovnatsky@users.noreply.github.com";
    };

    extraConfig = {
      init.defaultBranch = "main";
      merge.tool = "nvim";
      mergetool."nvim".cmd = ''nvim -f -c "Gdiffsplit!" "$MERGED"'';
      pull.rebase = false;
      push.default = "current";

      credential = {
        helper = "${homeCredentialHelper}";
      };

      core = {
        editor = "nvim";
        filemode = true;
      };

      mergetool = {
        keepBackup = false;
        prompt = true;
      };
    };
  };
}
