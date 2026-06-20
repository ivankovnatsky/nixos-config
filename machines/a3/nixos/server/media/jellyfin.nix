{ lib, ... }:

{
  # Initial Setup (manual, one-time):
  # 1. Access the web UI at https://jellyfin.{externalDomain}
  # 2. Create the root user during the wizard.
  # 3. Generate API key: Administration -> Dashboard -> Advanced -> API Keys
  #    -> New API Key. Name it "Default" and store the value in
  #    secrets/default.yaml under jellyfin/apiKey (rotating the existing
  #    placeholder if needed) so jellyfin-mgmt can take over library setup.
  #
  # After initial setup, jellyfin-mgmt declaratively manages Libraries and
  # the LocalNetworkAddresses bind. Media paths are shared with the *arr
  # services via the `media` group set up in ./default.nix; the movies/tv
  # roots are declared in ./radarr.nix and ./sonarr.nix respectively.

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    group = "media";
  };

  # Make jellyfin able to read media imported by radarr/sonarr (group=media,
  # UMask=0002 elsewhere). UMask 0002 on jellyfin keeps anything it writes
  # group-writable too, so the *arr services can clean up after it.
  systemd.services.jellyfin = {
    serviceConfig.UMask = lib.mkForce "0002";
    unitConfig.RequiresMountsFor = [ "/storage" ];
  };
}
