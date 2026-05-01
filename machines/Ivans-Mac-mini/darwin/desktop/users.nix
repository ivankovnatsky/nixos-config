{
  username,
  lib,
  ...
}:
{
  users.users.${username} = {
    uid = 502;
    # Login shell must live on the internal boot volume, not /nix on the
    # external store. If the external volume is unmounted or the launchd
    # EPERM-on-/nix-scripts class of bug bites, terminals still work and
    # we are not locked out of the machine. Fish (from /nix) is configured
    # as the per-terminal-emulator shell instead — see ghostty/kitty.
    shell = lib.mkForce "/bin/bash";
  };
}
