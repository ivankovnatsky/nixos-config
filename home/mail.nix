{ config, pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;
  configPath = if isDarwin then "Library/Application Support" else ".config";
in
{
  home.file = {
    # Create .keep file to ensure Mail directory exists
    "Mail/.keep".text = "";

    # TODO: Add pkgs interpolation for ks pkg.
    # Create .mbsyncrc
    ".mbsyncrc".text = ''
      IMAPAccount [redacted]
      Host imap.[redacted].com
      User ${config.secrets.iMail}
      PassCmd "pass [redacted]-mail"
      SSLType IMAPS
      CertificateFile /etc/ssl/cert.pem
      PipelineDepth 50
      Timeout 120
      AuthMechs PLAIN

      IMAPStore [redacted]-remote
      Account [redacted]
      UseNamespace yes
      PathDelimiter /

      MaildirStore [redacted]-local
      Path ~/Mail/
      Inbox ~/Mail/INBOX
      SubFolders Verbatim
      Flatten .
      Trash "Deleted Messages"

      # Split into two channels for better control
      Channel [redacted]-inbox
      Far :[redacted]-remote:"INBOX"
      Near :[redacted]-local:INBOX
      Sync Pull
      Create Near
      Expunge None
      SyncState *
      MaxMessages 0
      CopyArrivalDate yes

      Channel [redacted]-others
      Far :[redacted]-remote:
      Near :[redacted]-local:
      Patterns * !INBOX
      Sync Pull
      Create Near
      Expunge None
      SyncState *
      MaxMessages 0
      CopyArrivalDate yes

      # Group to sync all channels
      Group [redacted]
      Channel [redacted]-inbox
      Channel [redacted]-others
    '';

    ".msmtprc".text = ''
      # Set default values for all following accounts.
      defaults
      auth           on
      tls            on
      tls_trust_file /etc/ssl/cert.pem
      logfile        ~/.msmtp.log

      # [redacted]
      account        [redacted]
      host           smtp.[redacted].com
      port           [redacted]
      tls_starttls   on
      auth           on
      from           ${config.secrets.iMail}
      user           ${config.secrets.iMail}
      passwordeval   "pass [redacted]-mail"

      # Set a default account
      account default : [redacted]
    '';

    # Ensure proper permissions for .msmtprc (600)
    ".msmtprc".executable = false;

    "${configPath}/himalaya/config.toml".text = ''
      [accounts.[redacted]]
      default = true
      email = "${config.secrets.iMail}"
      display-name = "[redacted]"
      downloads-dir = "${config.home.homeDirectory}/Mail/Downloads"
      backend = "maildir"
      sync.enable = true
      message.send.backend = "sendmail"
      sendmail.cmd = "${pkgs.msmtp}/bin/msmtp"

      maildir.root-dir = "${config.home.homeDirectory}/Mail"
      maildir.maildirpp = true

      # Standard folder aliases - matching exactly what mbsync created
      folder.alias.inbox = "INBOX"
      folder.alias.sent = "Sent Messages"
      folder.alias.drafts = "Drafts"
      folder.alias.trash = "Deleted Messages"
      folder.alias.junk = "Junk"
      folder.alias.archive = "Archive"
    '';
  };
}
