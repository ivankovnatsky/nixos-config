{ pkgs, ... }:

let editor = "vim";

in
{
  home.packages = with pkgs; [
    syncthing
    yt-dlp
    mpv
  ];

  home.sessionVariables = {
    EDITOR = editor;
    VISUAL = editor;
  };

  home.file = {
    ".manual/config".text = ''
      # Do not enter user password too often
      bash -c 'cat << EOF > /private/etc/sudoers.d/ivan
      Defaults:ivan timestamp_timeout=240
      EOF'
    '';
  };

  programs = {
    zsh.enable = true;
    starship = {
      enable = true;
      enableZshIntegration = true;
    };
    git = {
      enable = true;
      userEmail = "75213+ivankovnatsky@users.noreply.github.com";
      userName = "Ivan Kovnatsky";
      signing = {
        signByDefault = true;
        key = "75213+ivankovnatsky@users.noreply.github.com";
      };
      ignores = [
        ".stignore"
      ];
      extraConfig = {
        core = {
          editor = editor;
        };
        pull.rebase = false;
        push.default = "current";
      };
      aliases = {
        co = "checkout";
        ca = "commit -av";
      };
    };
  };
}
