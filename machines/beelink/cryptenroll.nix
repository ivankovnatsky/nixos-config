# This file contains systemd-cryptenroll configuration for the beelink machine
# See docs/beelink.md for detailed instructions on how to use this file.

{ config, lib, pkgs, ... }:

{
  # TPM2 support for LUKS using systemd-cryptenroll
  # NOTE: Before enabling this configuration:
  # 1. First enroll TPM2 as described in the documentation
  # 2. Then uncomment the import for this file in default.nix
  # Enable TPM2 support
  security.tpm2.enable = true;

  # Configure LUKS with TPM2 support
  boot.initrd.luks.devices."luks-d60d88b5-b111-42bc-a377-dd4cc5630f0f" = {
    device = "/dev/disk/by-uuid/d60d88b5-b111-42bc-a377-dd4cc5630f0f";
    crypttabExtraOpts = [ "tpm2-device=auto" ];
  };
}
