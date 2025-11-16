{ pkgs, ... }:
{
  security = {
    pam = {
      services = {
        sddm = {
          kwallet = {
            enable = true;
            package = pkgs.kdePackages.kwallet-pam;
          };
        };
        login = {
          kwallet = {
            enable = true;
            package = pkgs.kdePackages.kwallet-pam;
          };
        };
        # Enable for systemd-user to handle jovian autoStart autologin scenarios
        systemd-user = {
          kwallet = {
            enable = true;
            package = pkgs.kdePackages.kwallet-pam;
          };
        };
        kwallet = {
          name = "kwallet";
          enableKwallet = true;
        };
      };
    };
  };
}
