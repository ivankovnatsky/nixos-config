# NixOS Obsidian vault registration via systemd.
# Settings and documentation live in obsidian-settings.nix.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (import ../../../home/obsidian-settings.nix) appSettings;
  vaultPaths = config.flags.obsidian.vaultPaths;

  appJsonFile = pkgs.writeText "obsidian-app.json" (builtins.toJSON appSettings);

  resolveVault =
    vault: if lib.hasPrefix "/" vault then vault else "${config.home.homeDirectory}/${vault}";

  registerScript = pkgs.writeShellScript "register-obsidian-vaults" ''
    ${lib.concatMapStringsSep "\n" (
      vault:
      let
        resolved = resolveVault vault;
      in
      ''
        ${pkgs.coreutils}/bin/mkdir -p "${resolved}/.obsidian"
        ${pkgs.coreutils}/bin/cp "${appJsonFile}" "${resolved}/.obsidian/app.json"
      ''
    ) vaultPaths}
  '';
in
{
  # NixOS: systemd user oneshot service
  systemd.user.services.obsidian-register-vaults = lib.mkIf (vaultPaths != [ ]) {
    Unit.Description = "Register Obsidian vaults and deploy config";
    Service = {
      Type = "oneshot";
      ExecStart = "${registerScript}";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
