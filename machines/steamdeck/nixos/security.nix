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
