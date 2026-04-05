# Darwin-specific Obsidian vault registration via launchd.
# Registers vaults with the obs CLI and deploys config files.
# Settings and documentation live in obsidian-settings.nix.
{ config, lib, pkgs, ... }:

let
  inherit (import ./obsidian-settings.nix) appSettings;
  vaultPaths = config.flags.obsidian.vaultPaths;

  appJsonFile = pkgs.writeText "obsidian-app.json" (builtins.toJSON appSettings);

  resolveVault = vault:
    if lib.hasPrefix "/" vault then vault
    else "${config.home.homeDirectory}/${vault}";

  registerScript = pkgs.writeShellScript "register-obsidian-vaults" ''
    ${lib.concatMapStringsSep "\n" (vault:
      let resolved = resolveVault vault;
      in ''
        /bin/wait4path "${resolved}"
        ${pkgs.obs}/bin/obs create "${resolved}"
        ${pkgs.coreutils}/bin/mkdir -p "${resolved}/.obsidian"
        ${pkgs.coreutils}/bin/cp "${appJsonFile}" "${resolved}/.obsidian/app.json"
      '') vaultPaths}
  '';
in
{
  local.launchd.services.obsidian-register-vaults = lib.mkIf (vaultPaths != [ ]) {
    enable = true;
    command = "${registerScript}";
    keepAlive = false;
    runAtLoad = true;
  };
}
