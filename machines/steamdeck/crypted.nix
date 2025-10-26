{
  boot = {
    initrd = {
      luks.devices.crypted = {
        device = "/dev/disk/by-uuid/2b9052dc-f819-4ff3-98e6-661a45a2cc3e";
        preLVM = true;
      };
    };
  };
}
