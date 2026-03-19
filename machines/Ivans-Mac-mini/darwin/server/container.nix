{ pkgs, ... }:

# Cleanup: after migrating from root daemon to user-agent, remove old root state:
# sudo rm -rf /var/root/Library/Application\ Support/com.apple.container/

let
  containerStarter = pkgs.writeShellScript "container-starter" ''
    ${pkgs.nixpkgs-darwin-master-container.container}/bin/container system start --enable-kernel-install
  '';

  # TODO: Make IP forwarding and NAT persistent via /etc/sysctl.conf and
  # /etc/pf.conf instead of re-applying on each boot.
  containerNetworking = pkgs.writeShellScript "container-networking" ''
    # Enable IP forwarding for container internet access
    current=$(sysctl -n net.inet.ip.forwarding)
    if [ "$current" != "1" ]; then
      echo "Enabling IP forwarding..."
      sysctl -w net.inet.ip.forwarding=1
    else
      echo "IP forwarding already enabled"
    fi

    # Enable NAT for container subnet (192.168.64.0/24 via vmnet bridge)
    if pfctl -s nat 2>/dev/null | grep -q "192.168.64.0/24"; then
      echo "NAT rules already active"
    else
      echo "Enabling NAT for container subnet..."
      echo "nat on en0 from 192.168.64.0/24 to any -> (en0)" | pfctl -ef - 2>&1
    fi
  '';
in
{
  environment.systemPackages = [ pkgs.nixpkgs-darwin-master-container.container ];

  local.launchd.services.container = {
    enable = true;
    type = "user-agent";
    command = "${containerStarter}";
  };

  local.launchd.services.container-networking = {
    enable = true;
    type = "daemon";
    command = "${containerNetworking}";
  };
}
