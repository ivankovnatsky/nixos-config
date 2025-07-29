{ pkgs, ... }:
{
  security = {
    pam = {
      services = {
        # Enable for SDDM - Plasma 6 already handles login and kde services
        sddm = {
          kwallet = {
            enable = true;
            package = pkgs.kdePackages.kwallet-pam;
          };
        };
        # Enable for user login session to auto-unlock KWallet
        login = {
          kwallet = {
            enable = true;
          };
        };
        # https://www.reddit.com/r/NixOS/comments/1cuzql7/os_keyring/
        kwallet = {
          name = "kwallet";
          enableKwallet = true;
        };
      };
    };
  };
}
