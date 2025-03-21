{
  security = {
    pam = {
      services.sudo_local = {
        enable = true;
        touchIdAuth = true;
        reattach = true; # for tmux/screen support
      };
    };
  };
}
