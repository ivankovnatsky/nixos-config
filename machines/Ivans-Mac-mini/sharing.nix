{
  # Manual configuration:
  # Enabled Windows File Sharing to be able to connect with user/password
  # Import the custom module
  imports = [
    ../../modules/darwin/sharing
  ];

  # Configure file sharing
  local.services.macosFileSharing = {
    enable = true;
    shares = {
      "Storage" = {
        path = "/Volumes/Storage/Data";
      };
    };
  };
}
