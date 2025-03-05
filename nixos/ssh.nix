{
  # Enable the OpenSSH daemon
  services.openssh = {
    enable = true;

    # All settings moved to the settings attribute as per NixOS warnings
    settings = {
      # Permit root login through SSH for initial setup only
      # Consider changing to "no" after initial setup
      PermitRootLogin = "prohibit-password";

      # Allow password authentication for initial setup
      PasswordAuthentication = true;

      # Enable X11 forwarding if needed
      # X11Forwarding = true;

      # Allow challenge-response authentication for initial setup
      KbdInteractiveAuthentication = true;

      # Only use modern secure ciphers and algorithms
      Ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
        "aes128-gcm@openssh.com"
        "aes256-ctr"
        "aes192-ctr"
        "aes128-ctr"
      ];

      # Log more verbosely for authentication issues
      LogLevel = "VERBOSE";
    };
  };

  # Open firewall port for SSH
  networking.firewall.allowedTCPPorts = [ 22 ];
}
