{
  # Indexers configured:
  # * toloka.to
  # * EZTV
  # * TheRARBG
  # * LimeTorrents
  # * The Private Bay
  #
  # Manual configuration:
  # * Get API Key:
  #   * Settings → General → Security → API Key (save to modules/secrets/default.nix)
  # * Add indexers via Settings → Indexers
  # * Add apps via Settings → Apps:
  #   * Radarr: localhost:7878, get API key from Radarr → Settings → General
  #   * Sonarr: localhost:8989, get API key from Sonarr → Settings → General
  # * Sync indexers to apps via Settings → Apps → Sync App Indexers
  #
  # References:
  # * https://www.reddit.com/r/radarr/comments/1dbx8u2/comment/l7u08gc/
  # * https://www.reddit.com/r/trackers/comments/1h4l0sa/comment/lzzkwaj/
  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };
}
