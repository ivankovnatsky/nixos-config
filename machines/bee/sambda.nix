{
  # SMB/CIFS file sharing configuration for bee machine
  # This enables sharing of the /storage directory over the network
  # Optimized for macOS clients

  # Enable the Samba service
  services.samba = {
    enable = true;
    openFirewall = true;
    
    # Enable all components
    smbd.enable = true;
    nmbd.enable = true;
    
    # Configure Samba using the settings structure
    settings = {
      global = {
        # Basic server settings
        workgroup = "WORKGROUP";
        "server string" = "Bee NixOS Server";
        "server role" = "standalone server";
        security = "user";
        
        # Logging settings
        "log file" = "/var/log/samba/log.%m";
        "max log size" = 50;
        
        # Authentication settings
        "map to guest" = "bad user";
        
        # Performance optimization
        "socket options" = ["TCP_NODELAY" "IPTOS_LOWDELAY"];
        "read raw" = "yes";
        "write raw" = "yes";
        
        # macOS specific optimizations
        "fruit:metadata" = "stream";
        "fruit:model" = "MacSamba";
        "fruit:veto_appledouble" = "no";
        "fruit:posix_rename" = "yes";
        "fruit:zero_file_id" = "yes";
        "vfs objects" = ["fruit" "streams_xattr"];
        
        # Security settings
        "server min protocol" = "SMB2";
        "server max protocol" = "SMB3";
        
        # Disable printer sharing
        "load printers" = "no";
        "printing" = "bsd";
        "printcap name" = "/dev/null";
        "disable spoolss" = "yes";
      };
      
      # Main storage share
      storage = {
        path = "/storage";
        comment = "Bee Storage Share";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0664";
        "directory mask" = "0775";
      };
      
      # You could uncomment and customize for more specific shares
      # media = {
      #   path = "/storage/media";
      #   comment = "Media Files";
      #   browseable = "yes";
      #   "read only" = "no";
      #   "guest ok" = "no";
      #   "create mask" = "0664";
      #   "directory mask" = "0775";
      # };
    };
  };
  
  # Ensure Samba-related logs directory exists
  # This is now handled automatically by the systemd.tmpfiles rules in the module
  
  # Note for users:
  # To connect from macOS:
  # 1. In Finder, press Cmd+K
  # 2. Enter: smb://bee/storage (or the appropriate hostname/IP)
  # 3. Provide username and password when prompted
  
  # You'll need to create a Samba user and password with:
  # sudo smbpasswd -a <your-username>
}
