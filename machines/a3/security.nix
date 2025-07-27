{ pkgs, ... }:
{
  security = {
    pam = {
      services = {
        # Enable KWallet unlock for login (works with SDDM)
        login = {
          kwallet = {
            enable = true;
            package = pkgs.kdePackages.kwallet-pam;
          };
        };
        
        # Enable KWallet unlock for KDE sessions
        kde = {
          allowNullPassword = true;
          kwallet = {
            enable = true;
            package = pkgs.kdePackages.kwallet-pam;
          };
        };
        
        # Enable for SDDM as well
        sddm = {
          kwallet = {
            enable = true;
            package = pkgs.kdePackages.kwallet-pam;
          };
        };
      };
    };
  };
}