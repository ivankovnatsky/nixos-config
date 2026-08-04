{ pkgs, ... }:

{
  # Share the USB-attached Brother HL-1110E over the LAN via CUPS.
  # brlaser is the open driver that covers the HL-1110 family.
  services.printing = {
    enable = true;
    drivers = [ pkgs.brlaser ];
    # Advertise queues and accept jobs from other hosts on the LAN.
    browsing = true;
    defaultShared = true;
    listenAddresses = [ "*:631" ];
    allowFrom = [ "192.168.50.0/24" ];
    openFirewall = true;
  };

  # Publish the CUPS queue over mDNS so iOS/macOS see it as AirPrint.
  # avahi itself is already enabled in networking.nix.
  services.avahi.publish.userServices = true;
}
