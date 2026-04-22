{ ... }:
{
  networking.knownNetworkServices = [
    "AX88179A"
    "USB-C Dock Ethernet"
    "Thunderbolt Ethernet Slot 0"
    "Thunderbolt Bridge"
    "Wi-Fi"
    "iPhone USB"
  ];

  local.nextdns-dns = {
    enable = true;
    machine = "Air";
  };
}
