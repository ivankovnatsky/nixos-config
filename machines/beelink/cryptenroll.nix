# This file contains systemd-cryptenroll configuration for the beelink machine
# See docs/beelink.md for detailed instructions on how to use this file.

{
  # TPM2 support for LUKS using systemd-cryptenroll
  # NOTE: Before enabling this configuration:
  # 1. First apply the base configuration with TPM2 support enabled
  # 2. Then enroll TPM2 as described in the documentation for both LUKS devices
  # 3. Finally, uncomment the import for this file in default.nix

  boot = {
    # Configure LUKS with TPM2 support
    initrd = {
      # LUKS device configurations
      luks.devices = {
        # Root partition
        "luks-d60d88b5-b111-42bc-a377-dd4cc5630f0f" = {
          device = "/dev/disk/by-uuid/d60d88b5-b111-42bc-a377-dd4cc5630f0f";
          crypttabExtraOpts = [ "tpm2-device=auto" ];
        };

        # Swap partition
        "luks-14c9a632-e607-49b2-ac01-965dbe30d02e" = {
          device = "/dev/disk/by-uuid/14c9a632-e607-49b2-ac01-965dbe30d02e";
          crypttabExtraOpts = [ "tpm2-device=auto" ];
        };
      };

      # Enable systemd in initrd for better TPM2 support
      systemd = {
        enable = true;
        emergencyAccess = true;  # Allow emergency login if needed
      };
    };
  };
}
