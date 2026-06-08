{ ... }:
{
  networking.knownNetworkServices = [
    "AX88179A"
    "Ethernet"
    "Thunderbolt Ethernet Slot 3"
    "Thunderbolt Bridge"
    "Wi-Fi"
  ];

  # Link IP in https://my.nextdns.io/$profile/setup
  local.nextdns = {
    enable = true;
    machine = "Mini";
  };
}
