{ ... }:
{
  networking.knownNetworkServices = [
    "AX88179A"
    "iPhone USB"
    "Thunderbolt Bridge"
    "Thunderbolt Ethernet Slot 0"
    "Wi-Fi"
  ];

  local.nextdns = {
    enable = true;
    machine = "Pro";
  };
}
