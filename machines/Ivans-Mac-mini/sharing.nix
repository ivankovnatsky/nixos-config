{
  # Import the custom module
  imports = [
    ../../modules/darwin/sharing
  ];

  # Configure file sharing
  local.services.macosFileSharing = {
    enable = true;
    shares = {
      "Samsung2TB" = {
        path = "/Volumes/Samsung2TB";
      };
    };
  };
}
