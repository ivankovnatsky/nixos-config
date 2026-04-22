{ ... }:
{
  networking.knownNetworkServices = [
    "AX88179A"
    "iPhone USB"
    "Thunderbolt Bridge"
    "Thunderbolt Ethernet Slot 0"
    "Wi-Fi"
  ];

  local.nextdns-dns = {
    enable = true;
    machine = "Pro";
  };
}
