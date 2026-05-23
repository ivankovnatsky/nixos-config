{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.home.mail;

  passwordFile = config.sops.secrets."mail/iCloud/appPassword".path;
  addr = config.sops.placeholder."mail/iCloud/address";
  himalayaConfig = "${config.home.homeDirectory}/.config/himalaya/config.toml";
in
{
  options.modules.home.mail = {
    enable = mkEnableOption "iCloud Mail (Himalaya + mbsync + msmtp) with sops-backed secrets";

    realName = mkOption {
      type = types.str;
      default = config.flags.git.userName;
      description = "Display name for outbound mail (From header).";
    };

    maildirRoot = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/Mail/iCloud";
      description = "Maildir root for the iCloud account.";
    };

    syncInterval = mkOption {
      type = types.int;
      default = 600;
      description = "mbsync sync interval, in seconds (launchd StartInterval / systemd OnUnitActiveSec).";
    };

    waitForPath = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        External volume mountpoint to wait for before mbsync starts.
        Darwin only — passed to launchd's wait4path. Set this when
        maildirRoot lives on a removable disk so the agent blocks until
        the volume is mounted. Must be a path that exists once the volume
        is online — typically the volume root, NOT maildirRoot itself
        (which is created on first sync).
      '';
    };
  };

  config = mkIf cfg.enable {
    sops.secrets."mail/iCloud/address" = {
      key = "mail/iCloud/address";
    };
    sops.secrets."mail/iCloud/appPassword" = {
      key = "mail/iCloud/appPassword";
    };

    home.packages = [
      pkgs.isync
      pkgs.msmtp
      pkgs.himalaya
    ];

    sops.templates."mbsyncrc".content = ''
      IMAPAccount icloud
      Host imap.mail.me.com
      Port 993
      User ${addr}
      PassCmd "cat ${passwordFile}"
      SSLType IMAPS
      CertificateFile ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      PipelineDepth 50
      Timeout 120

      IMAPStore icloud-remote
      Account icloud
      UseNamespace yes
      PathDelimiter /

      MaildirStore icloud-local
      Path ${cfg.maildirRoot}/
      Inbox ${cfg.maildirRoot}/INBOX
      SubFolders Verbatim
      Trash "Deleted Messages"

      Channel icloud
      Far :icloud-remote:
      Near :icloud-local:
      Patterns *
      Sync Pull
      Create Near
      Expunge None
      SyncState *
      MaxMessages 0
      CopyArrivalDate yes
    '';

    sops.templates."msmtprc".content = ''
      defaults
      auth           on
      tls            on
      tls_trust_file ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      logfile        ${config.home.homeDirectory}/.msmtp.log

      account        icloud
      host           smtp.mail.me.com
      port           587
      tls_starttls   on
      from           ${addr}
      user           ${addr}
      passwordeval   "cat ${passwordFile}"

      account default : icloud
    '';

    sops.templates."himalaya-config.toml".content = ''
      [accounts.icloud]
      default = true
      email = "${addr}"
      display-name = "${cfg.realName}"
      downloads-dir = "${cfg.maildirRoot}/Downloads"

      backend.type = "maildir"
      backend.root-dir = "${cfg.maildirRoot}"

      message.send.backend.type = "sendmail"
      message.send.backend.cmd = "${pkgs.msmtp}/bin/msmtp"

      folder.aliases.inbox = "INBOX"
      folder.aliases.sent = "Sent Messages"
      folder.aliases.drafts = "Drafts"
      folder.aliases.trash = "Deleted Messages"
      folder.aliases.junk = "Junk"
      folder.aliases.archive = "Archive"
    '';

    home.activation.linkMailConfigs =
      lib.hm.dag.entryAfter
        [
          "writeBoundary"
          "sops-nix"
        ]
        ''
          run mkdir -p "$(dirname "${himalayaConfig}")"
          run ln -sf ${config.sops.templates."mbsyncrc".path} ${config.home.homeDirectory}/.mbsyncrc
          run ln -sf ${config.sops.templates."msmtprc".path} ${config.home.homeDirectory}/.msmtprc
          run ln -sf ${config.sops.templates."himalaya-config.toml".path} "${himalayaConfig}"
        '';

    local.launchd.services = mkIf pkgs.stdenv.isDarwin {
      mbsync-icloud = {
        enable = true;
        command = "${pkgs.isync}/bin/mbsync -a";
        waitForSecrets = true;
        waitForPath = cfg.waitForPath;
        dataDir = cfg.maildirRoot;
        runAtLoad = true;
        keepAlive = false;
        extraServiceConfig = {
          StartInterval = cfg.syncInterval;
        };
      };
    };

    systemd.user.services = mkIf pkgs.stdenv.isLinux {
      mbsync-icloud = {
        Unit = {
          Description = "mbsync iCloud sync";
          After = [ "sops-nix.service" ];
          Wants = [ "sops-nix.service" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.isync}/bin/mbsync -a";
        };
      };
    };

    systemd.user.timers = mkIf pkgs.stdenv.isLinux {
      mbsync-icloud = {
        Unit.Description = "mbsync iCloud sync timer";
        Timer = {
          OnBootSec = "1min";
          OnUnitActiveSec = "${toString cfg.syncInterval}s";
          Unit = "mbsync-icloud.service";
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
  };
}
