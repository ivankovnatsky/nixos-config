{
  boot = {
    initrd = {
      luks.devices."crypted".crypttabExtraOpts = [ "tpm2-device=auto" ];

      systemd = {
        enable = true;
        emergencyAccess = true;
      };
    };
  };
}
