{
  # Enable FlareSolverr service
  #
  # Configure: https://trash-guides.info/Prowlarr/prowlarr-setup-flaresolverr/
  #
  # References:
  # * https://www.reddit.com/r/pihole/comments/1dx0zo4/comment/lbypiws/
  services.flaresolverr = {
    enable = true;
    openFirewall = true;
  };
}
