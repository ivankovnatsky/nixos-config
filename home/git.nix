{ pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin isLinux;

  git-credential-bw = pkgs.writeScriptBin "git-credential-bw" ''
    ${toString(builtins.readFile ../files/git-credential-bw.sh)}
  '';

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

    defaultProfile = "home";
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
        helper = "${homeCredentialHelper}";
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
