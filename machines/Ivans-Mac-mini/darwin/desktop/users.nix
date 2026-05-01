{
  username,
  lib,
  ...
}:
{
  users.users.${username} = {
    uid = 502;
    # fish-from-nix on aarch64-darwin (nixpkgs-25.11) SIGKILLs at exec
    # due to invalid linker-signed adhoc cdhash. See
    # Notes/Configs/NixConfig/Issues/NixStoreExternalDiskDarwinFragility.md
    # Session 5. Pin login shell to brew fish until upstream fix lands.
    # `dscl . -read /Users/ivan UserShell` flips to /opt/homebrew/bin/fish
    # once the rebuild applies.
    shell = lib.mkForce "/opt/homebrew/bin/fish";
  };

  environment.shells = [ "/opt/homebrew/bin/fish" ];
}
