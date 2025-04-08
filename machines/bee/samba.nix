{
  # SMB/CIFS file sharing configuration for bee machine
  # This enables sharing of the /storage directory over the network
  # Optimized for discovery and use with both Windows and macOS clients

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
  
  # Enable Web Services Discovery Daemon for Windows discovery
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
    workgroup = "WORKGROUP"; # Should match your Samba workgroup
    hostname = "BEE";        # Custom hostname for Windows network
  };

  # Enable Avahi/mDNS for macOS discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true; # Name resolution via mDNS
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
      userServices = true;
    };
    # Publish Samba shares via Bonjour
    extraServiceFiles = {
      smb = ''<?xml version="1.0" standalone="no"?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">%h</name>
  <service>
    <type>_smb._tcp</type>
    <port>445</port>
  </service>
  <service>
    <type>_device-info._tcp</type>
    <port>0</port>
    <txt-record>model=RackMac</txt-record>
  </service>
</service-group>'';
    };
  };
  
  # Note for users:
  # To connect from macOS:
  # 1. Open Finder, look for "bee" in the Network section
  # 2. OR press Cmd+K and enter: smb://bee.local/storage or smb://bee/storage
  # 3. Provide username and password when prompted
  #
  # To connect from Windows:
  # 1. Open File Explorer, look for "BEE" in the Network section
  # 2. OR enter \\\\bee\\storage in the address bar
  # 3. Provide username and password when prompted
  
  # You'll need to create a Samba user and password with:
  # sudo smbpasswd -a <your-username>
}
