{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sops;

  # Recreate sops-nix's manifest locally. We can't read upstream's manifest
  # via config.launchd.agents.sops-nix.config.Program (IFD on a value we
  # then override is circular), so we rebuild the same JSON from the
  # exposed config.sops.* options. Mirrors `manifestFor` in upstream
  # sops-nix modules/home-manager/sops.nix.
  manifest = pkgs.writeTextFile {
    name = "manifest.json";
    text = builtins.toJSON {
      secrets = builtins.attrValues cfg.secrets;
      templates = builtins.attrValues cfg.templates;
      secretsMountPoint = cfg.defaultSecretsMountPoint;
      symlinkPath = cfg.defaultSymlinkPath;
      inherit (cfg) keepGenerations;
      gnupgHome = cfg.gnupg.home;
      inherit (cfg.gnupg) sshKeyPaths;
      ageKeyFile = cfg.age.keyFile;
      ageSshKeyPaths = cfg.age.sshKeyPaths;
      placeholderBySecretName = cfg.placeholder;
      userMode = true;
      logging = {
        keyImport = builtins.elem "keyImport" cfg.log;
        secretChanges = builtins.elem "secretChanges" cfg.log;
      };
    };
  };
in
{
  imports = [
    ../../../home/sops-secrets.nix
    ../../../shared/sops-nix.nix
  ];

  # Use user SSH key for age decryption (home-manager needs user-owned secrets)
  sops.age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];

  # WORKAROUND: Upstream sops-nix sets KeepAlive=false for the launchd agent,
  # so if sops-install-secrets fails at boot (SSH key not readable yet), it
  # never retries and secrets stay broken until next darwin-rebuild switch.
  # https://github.com/Mic92/sops-nix/issues/801
  launchd.agents.sops-nix.config.KeepAlive = lib.mkForce {
    SuccessfulExit = false;
  };

  # WORKAROUND (2026-05-01): macOS denies open() of script files on the
  # external /nix volume for launchd-spawned children (EPERM). Apple docs:
  # "If your product uses a script as its main executable, you're likely
  # to encounter TCC problems. To resolve these, switch to using a Mach-O
  # executable." Replace upstream's Program=<shebang script> with bash -c
  # <inline command> so launchd never has to open() a script on /nix.
  # See Notes/Log/2026/05/01.md and home-manager#6536.
  launchd.agents.sops-nix.config.Program = lib.mkForce "${pkgs.bash}/bin/bash";
  launchd.agents.sops-nix.config.ProgramArguments = lib.mkForce [
    "${pkgs.bash}/bin/bash"
    "-c"
    "exec ${cfg.package}/bin/sops-install-secrets -ignore-passwd ${manifest}"
  ];
}
