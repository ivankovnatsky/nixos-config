# This file contains systemd-cryptenroll configuration for the a3 machine
# See docs/a3.md for detailed instructions on how to use this file.

{
  # TPM2 support for LUKS using systemd-cryptenroll
  # NOTE: Before enabling this configuration:
  # 1. First apply the base configuration with TPM2 support enabled
  # 2. Then enroll TPM2 as described in the documentation
  # 3. Finally, ensure this file is imported in default.nix

  boot = {
    # Configure LUKS with TPM2 support
    initrd = {
      # LUKS device configuration
      luks.devices = {
        # Single encrypted partition containing both root and swap via LVM
        "crypted" = {
          device = "/dev/disk/by-uuid/b63f3e81-c6d5-4dc6-af60-f5eef6c79af9";
          crypttabExtraOpts = [ "tpm2-device=auto" ];
        };
      };

      # Enable systemd in initrd for better TPM2 support
      systemd = {
        enable = true;
        emergencyAccess = true; # Allow emergency login if needed
      };
    };
  };
}
