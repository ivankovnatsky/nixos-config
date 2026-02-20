{
  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
      openFirewall = true;
    };
  };

  networking.firewall = {
    allowedUDPPorts = [
      5353
    ];
  };
}
