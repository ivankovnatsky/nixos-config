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
    # @LOCAL = any directly-connected local network. Using the interface
    # list (not a raw subnet) makes CUPS normalize IPv4-mapped IPv6 peers
    # (::ffff:192.168.x.x) that arrive on its dual-stack :631 socket;
    # a hardcoded "192.168.50.0/24" fails to match the mapped form -> 403.
    allowFrom = [ "@LOCAL" ];
    openFirewall = true;
    # Let any LAN device (incl. iOS AirPrint) submit jobs without a CUPS
    # login. Default policy demands auth for Send-Document, which macOS/iOS
    # can't satisfy and holds jobs. Network access stays gated by allowFrom;
    # printer-admin ops still require a system account.
    extraConf = ''
      DefaultPolicy anonymous
      <Policy anonymous>
        <Limit Pause-Printer Resume-Printer Set-Printer-Attributes Enable-Printer Disable-Printer Pause-Printer-After-Current-Job Hold-New-Jobs Release-Held-New-Jobs Deactivate-Printer Activate-Printer Restart-Printer Shutdown-Printer Startup-Printer Promote-Job Schedule-Job-After CUPS-Add-Printer CUPS-Delete-Printer CUPS-Add-Class CUPS-Delete-Class CUPS-Accept-Jobs CUPS-Reject-Jobs CUPS-Set-Default>
          AuthType Basic
          Require user @SYSTEM
          Order deny,allow
        </Limit>
        <Limit All>
          Order deny,allow
        </Limit>
      </Policy>
    '';
  };

  # Publish the CUPS queue over mDNS so iOS/macOS see it as AirPrint.
  # avahi itself is already enabled in networking.nix.
  services.avahi.publish.userServices = true;

  hardware.printers = {
    ensureDefaultPrinter = "HL-1110E";
    ensurePrinters = [
      {
        name = "HL-1110E";
        deviceUri = "usb://Brother/HL-1110%20series?serial=L5L570378";
        model = "drv:///brlaser.drv/br1110.ppd";
      }
    ];
  };
}
