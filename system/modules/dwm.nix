{ pkgs, ... }:

{
  programs = {
    slock.enable = true;
  };

  environment.systemPackages = with pkgs; [
    dmenu
    pamixer

    (slstatus.override {
      conf = builtins.readFile ../files/suckless/slstatus/config.h;
    })

    (dwm.override {
      conf = builtins.readFile ../files/suckless/dwm/config.h;
      patches = builtins.map pkgs.fetchurl [
        {
          url = "https://dwm.suckless.org/patches/notitle/dwm-notitle-6.2.diff";
          sha256 = "0lr7l98jc88lwik3hw22jq7pninmdla360c3c7zsr3s2hiy39q9f";
        }
        {
          url = "https://dwm.suckless.org/patches/pwkl/dwm-pwkl-6.2.diff";
          sha256 = "0qq3mlcp55p5dx9jmd75rkxlsdihzh4a2z1qzpljqash14kqsqzm";
        }
      ];
    })

    (st.override { conf = builtins.readFile ../files/suckless/st/config.h; })
  ];

  services = {
    xserver = {
      displayManager = {
        lightdm.enable = true;
        defaultSession = "xsession";

        autoLogin = {
          enable = true;
          user = "ivan";
        };

        sessionCommands = ''
          while true; do slstatus 2> /tmp/slstatus-log; done &
        '';

        session = [{
          manage = "desktop";
          name = "xsession";
          start = "while true; do dwm 2> /tmp/dwm-log; done";
        }];
      };
    };
  };
}
