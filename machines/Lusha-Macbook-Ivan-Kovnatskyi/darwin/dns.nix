{ ... }:
{
  networking.knownNetworkServices = [
    "Wi-Fi"
    "Thunderbolt Ethernet Slot 1"
  ];

  networking.dns = [
    "1.1.1.1"
    "1.0.0.1"
  ];
}
