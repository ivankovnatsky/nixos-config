{ ... }:

{
  services.prowlarr = {
    enable = true;
    openFirewall = true;
    settings = {
      server.bindaddress = "*";
    };
  };
}
