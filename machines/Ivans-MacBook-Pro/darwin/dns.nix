{ ... }:
{
  networking.knownNetworkServices = [
    "AX88179A"
    "Ethernet"
    "Thunderbolt Ethernet Slot 0"
    "Thunderbolt Bridge"
    "Wi-Fi"
  ];

  local.nextdns-dns = {
    enable = true;
    machine = "Pro";
  };
}
