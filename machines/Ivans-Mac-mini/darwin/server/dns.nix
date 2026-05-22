{ ... }:
{
  networking.knownNetworkServices = [
    "AX88179A"
    "Ethernet"
    "Thunderbolt Ethernet Slot 0"
    "Thunderbolt Ethernet Slot 3"
    "Thunderbolt Bridge"
    "Wi-Fi"
  ];

  local.nextdns = {
    enable = true;
    machine = "Mini";
  };
}
