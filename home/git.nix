{ pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin isLinux;


in
{
  home.packages = with pkgs; [
    gitAndTools.pre-commit
    git-crypt
    pinentry
    tig
  ];

  programs.gh = {
    enable = true;

    settings = { };

    enableGitCredentialHelper = false;
  };

  programs.git = {
    enable = true;

    defaultProfile = "home";

    signing = {
      signByDefault = true;
    };

    profiles = {
      home = {
        name = "Ivan Kovnatsky";
        email = "75213+ivankovnatsky@users.noreply.github.com";
        signingKey = "75213+ivankovnatsky@users.noreply.github.com";
        dirs = [ ];
      };
    };

    extraConfig = {
      init.defaultBranch = "main";
      merge.tool = "nvim";
      mergetool."nvim".cmd = ''nvim -f -c "Gdiffsplit!" "$MERGED"'';
      pull.rebase = false;
      push.default = "current";

      credential = {
        helper = "${pkgs.rbw}/bin/git-credential-rbw";
      };

      ghq = {
        root = "~/Sources";
      };

      tag = {
        gpgSign = "true";
        forceSignAnnotated = "true";
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
