{ ... }:

{
  programs.home-manager.enable = true;

  home.username = "sevenfourk";
  home.homeDirectory = "/home/sevenfourk";

  programs = {
    git = {
      enable = true;

      extraConfig = {
        commit = { gpgSign = true; };
        push = { default = "current"; };
        pull = { rebase = false; };
        core = {
          filemode = true;
          editor = "nvim";
        };
        merge = { tool = "vimdiff"; };
        mergetool = {
          prompt = true;
          keepBackup = false;
        };
        mergetool."vimdiff".cmd =
          "nvim -d $BASE $LOCAL $REMOTE $MERGED -c '$wincmd w' -c 'wincmd J'";
        include.path = "~/.config/git/config-home";
        includeIf."gitdir:~/Sources/Work/".path = "~/.config/git/config-work";
      };
    };
  };

  home.file = {
    ".config/git/config-type.template" = {
      text = ''
        [user]
        	email = 
        	name = 
        	signingKey = 
      '';
    };
  };

  home.stateVersion = "21.03";
}
