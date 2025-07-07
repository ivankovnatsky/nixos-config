# References:
# - https://github.com/nix-darwin/nix-darwin/blob/master/modules/services/tailscale.nix

# Manual authentication after applying config:
# ```console
# sudo tailscale up
# sudo tailscale set --advertise-routes=192.168.50.0/24
# ```
#
# Then approve subnet routes in Tailscale admin console:
# 1. Go to https://login.tailscale.com/admin/machines
# 2. Find this machine and click "Edit route settings"
# 3. Under "Subnet routes" toggle ON the 192.168.50.0/24 route
# 4. Click "Save"
#
# On other devices that want to use these routes:
# ```console
# sudo tailscale set --accept-routes
# ```
#
# To access local domains from remote devices, add nameserver in Tailscale DNS:
# 1. Go to https://login.tailscale.com/admin/dns
# 2. Click "Add nameserver"
# 3. Domain: @externalDomain@
# 4. Nameserver: 192.168.50.1 (router IP, balances between 50.3 bee and 50.4 mini)
# 5. Save

{
  services.tailscale = {
    enable = true;
  };
}
