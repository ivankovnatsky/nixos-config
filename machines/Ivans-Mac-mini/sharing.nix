{
  # Import the custom module
  imports = [
    ../../modules/darwin/sharing
  ];

  # Configure file sharing
  services.macosFileSharing = {
    enable = true;
    shares = {
      "Media" = {
        path = "/Volumes/ExternalDrive/Media";
        permissions = "everyone:r,staff:rw";
      };
      "Backups" = {
        path = "/Volumes/ExternalDrive/Backups";
        name = "Backup Storage"; # Custom display name
        permissions = "staff:rw";
        guestAccess = false;
      };
    };
  };
}
