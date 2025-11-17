{ ... }:
{
  # DNS configuration for lusha machine
  # Applies DNS servers to both Ethernet and Wi-Fi interfaces
  networking.knownNetworkServices = [
    "Wi-Fi"
    "Thunderbolt Ethernet Slot 1"
  ];

  # Cloudflare DNS servers
  # Note: For work machines, it's better not to use NextDNS as it can cause issues
  # with DNS rebinding protection blocking legitimate endpoints (e.g., Confluent
  # endpoints pointing to AWS were previously blocked by NextDNS rebinding settings)
  networking.dns = [
    "1.1.1.1"
    "1.0.0.1"
  ];
}
