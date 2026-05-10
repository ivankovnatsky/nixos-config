{
  # Pin all NM-managed wifi interfaces to their permanent hardware MAC
  # so router DHCP static reservations stay stable across reconnects.
  # NM defaults are `wifi.macAddress = "preserve"` (freezes whatever MAC
  # is active at association — i.e. a scan-randomized one) and
  # `scanRandMacAddress = true` (fresh random MAC each scan cycle).
  networking.networkmanager.wifi = {
    macAddress = "permanent";
    scanRandMacAddress = false;
  };
}
