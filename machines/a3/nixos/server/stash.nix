{
  config,
  lib,
  pkgs,
  ...
}:

let
  pathDir = "/storage0/data/stash";
  dataDir = "${pathDir}/lib";
  stashDir = "${pathDir}/media";
in
{
  users.users.ivan.extraGroups = [ "stash" ];

  sops.secrets = {
    stash-username = {
      key = "stash/username";
      owner = "stash";
      group = "stash";
    };
    stash-password = {
      key = "stash/password";
      owner = "stash";
      group = "stash";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${pathDir}        2775 ivan  stash -"
    "d ${dataDir}        2775 ivan  stash -"
    "d ${stashDir}       2775 ivan  stash -"
    "d ${dataDir}/config 2775 ivan  stash -"
    "d ${dataDir}/keys   2770 stash stash -"
    "Z ${dataDir}        -    ivan  stash -"
    "Z ${dataDir}/keys   -    stash stash -"
    "Z ${stashDir}       -    ivan  stash -"
    "a+ ${pathDir}        - - - - u:ivan:rwx,g:stash:rwx,m::rwx,d:u:ivan:rwx,d:g:stash:rwx,d:m::rwx"
    "a+ ${dataDir}        - - - - u:ivan:rwx,g:stash:rwx,m::rwx,d:u:ivan:rwx,d:g:stash:rwx,d:m::rwx"
    "a+ ${stashDir}       - - - - u:ivan:rwx,g:stash:rwx,m::rwx,d:u:ivan:rwx,d:g:stash:rwx,d:m::rwx"
    "a+ ${dataDir}/config - - - - u:ivan:rwx,g:stash:rwx,m::rwx,d:u:ivan:rwx,d:g:stash:rwx,d:m::rwx"
    "A+ ${dataDir}        - - - - u:ivan:rwX,g:stash:rwX,m::rwX,d:u:ivan:rwx,d:g:stash:rwx,d:m::rwx"
    "A+ ${stashDir}       - - - - u:ivan:rwX,g:stash:rwX,m::rwX,d:u:ivan:rwx,d:g:stash:rwx,d:m::rwx"
  ];

  systemd.services.stash-keys = {
    description = "Generate Stash JWT/session keys if missing";
    wantedBy = [ "stash.service" ];
    before = [ "stash.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "stash";
      Group = "stash";
      UMask = "0007";
    };
    unitConfig.RequiresMountsFor = [ "/storage0" ];
    script = ''
      set -euo pipefail
      [ -s ${dataDir}/keys/jwt ]     || ${pkgs.openssl}/bin/openssl rand -hex 32 > ${dataDir}/keys/jwt
      [ -s ${dataDir}/keys/session ] || ${pkgs.openssl}/bin/openssl rand -hex 32 > ${dataDir}/keys/session
      chmod 0660 ${dataDir}/keys/jwt ${dataDir}/keys/session
    '';
  };

  services.stash = {
    enable = true;
    inherit dataDir;
    openFirewall = true;

    # Match the mini's preStart-rewrite-every-restart behavior: settings are
    # the source of truth, config.yml is regenerated from them on every start.
    # NB: this relies on the upstream module's bash conditional
    #   if [[ -z "${toString cfg.mutableSettings}" || ! -f config.yml ]]
    # where toString false == "" makes -z true → unconditional rewrite. If
    # upstream ever changes that idiom, re-verify this still triggers a rewrite.
    mutableSettings = false;

    # mutablePlugins/mutableScrapers must be true here because we override
    # plugins_path / scrapers_path in settings to point at ${dataDir}/config/
    # {plugins,scrapers} (matching the mini layout). With them at the default
    # false, upstream sets the same options to a Nix-store derivation path and
    # eval fails on conflicting definitions.
    mutablePlugins = true;
    mutableScrapers = true;

    # Real username is loaded from sops in the ExecStartPre append below; the
    # placeholder only satisfies the module's "both username and password set"
    # assertion. With mutableSettings=false the patch runs every restart.
    username = "_sops_placeholder";
    passwordFile = config.sops.secrets.stash-password.path;

    jwtSecretKeyFile = "${dataDir}/keys/jwt";
    sessionStoreKeyFile = "${dataDir}/keys/session";

    # 1:1 mirror of templates/stash-config.yml as used on the mini. Every key
    # from the template is reproduced here even when it matches the upstream
    # module's default — the template is the spec, and matching it explicitly
    # protects against silent drift if upstream defaults ever change.
    #
    # Path note: the mini wrote config.yml at ${dataDir}/config/config.yml; the
    # upstream module hardcodes ${dataDir}/config.yml. So an rsync of mini's
    # .stash/ to a3's .stash/ preserves the sqlite DB, plugins/, scrapers/
    # (still under config/ via the explicit settings below), but a3 will boot
    # from the freshly-rendered .stash/config.yml and ignore the orphaned
    # .stash/config/config.yml from the mini snapshot.
    settings = {
      # Mini hardcoded flags.machineBindAddress = "0.0.0.0"; do the same here
      # rather than fall through to a3's default (a3Ip = 192.168.50.6) so that
      # loopback access and Caddy via @a3Ip@ both work the same.
      host = "0.0.0.0";
      port = 9999;

      stash = [
        {
          excludeimage = false;
          excludevideo = false;
          path = stashDir;
        }
      ];

      # Paths kept under config/ to mirror the mini layout so an rsync of the
      # SQLite DB, plugins/, and scrapers/ from /Volumes/Stash/Data/.stash/
      # lands in the right place under ${dataDir}.
      database = "${dataDir}/config/stash-go.sqlite";
      plugins_path = "${dataDir}/config/plugins";
      scrapers_path = "${dataDir}/config/scrapers";

      blobs_path = "${dataDir}/blobs";
      cache = "${dataDir}/cache";
      generated = "${dataDir}/generated";

      blobs_storage = "FILESYSTEM";
      autostart_video = true;
      calculate_md5 = false;
      create_image_clip_from_videos = false;
      dangerous_allow_public_without_auth = false;
      gallery_cover_regex = "(poster|cover|folder|board)\\.[^\\.]+$";
      max_session_age = 36000000;
      menu_items = [
        "scenes"
        "images"
      ];
      no_proxy = "localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12";
      nobrowser = true;
      notifications_enabled = true;
      parallel_tasks = 12;
      preview_audio = true;
      preview_exclude_end = 0;
      preview_exclude_start = 0;
      preview_segment_duration = 0.75;
      preview_segments = 12;
      # NB: mini template had typo "tripwipe"; upstream's option name (and
      # actual stash key) is "tripwire". We use the correct spelling here.
      security_tripwire_accessed_from_public_internet = "";
      sequential_scanning = false;
      show_one_time_moved_notification = false;
      show_scrubber = false;
      sound_on_preview = true;
      theme_color = "#202b33";
      video_file_naming_algorithm = "OSHASH";
      wall_playback = "video";
      write_image_thumbnails = true;

      defaults.delete_file = true;

      image_lightbox = {
        scale_up = true;
        scroll_attempts_before_change = 0;
        slideshow_delay = 5;
      };

      plugins.package_sources = [
        {
          localpath = "community";
          name = "Community (stable)";
          url = "https://stashapp.github.io/CommunityScripts/stable/index.yml";
        }
      ];
      scrapers.package_sources = [
        {
          localpath = "community";
          name = "Community (stable)";
          url = "https://stashapp.github.io/CommunityScrapers/stable/index.yml";
        }
      ];

      ui = {
        abbreviateCounters = true;
        advancedMode = true;
        compactExpandedDetails = true;
        lastNoteSeen = 20240826;
        showRangeMarkers = false;
        frontPageContent = [
          {
            __typename = "CustomFilter";
            direction = "DESC";
            message = {
              id = "recently_added_objects";
              values.objects = "Scenes";
            };
            mode = "SCENES";
            sortBy = "created_at";
          }
        ];
        taskDefaults = {
          cleanGenerated = {
            blobFiles = true;
            dryRun = false;
            imageThumbnails = true;
            markers = true;
            screenshots = true;
            sprites = true;
            transcodes = true;
          };
          generate = {
            clipPreviews = true;
            covers = true;
            imagePreviews = true;
            imageThumbnails = true;
            interactiveHeatmapsSpeeds = true;
            markerImagePreviews = true;
            markerScreenshots = true;
            markers = true;
            phashes = true;
            previewOptions = {
              previewExcludeEnd = "0";
              previewExcludeStart = "0";
              previewPreset = "slow";
              previewSegmentDuration = "0.75";
              previewSegments = "12";
            };
            previews = true;
            sprites = true;
            transcodes = true;
          };
          scan = {
            rescan = true;
            scanGenerateClipPreviews = true;
            scanGenerateCovers = true;
            scanGenerateImagePreviews = true;
            scanGeneratePhashes = true;
            scanGeneratePreviews = true;
            scanGenerateSprites = true;
            scanGenerateThumbnails = true;
          };
        };
      };
    };
  };

  # Upstream binds settings.stash[*].path read-only into the unit's namespace.
  # The mini's launchd job had read-write access to its media volume, and we
  # set defaults.delete_file = true plus expect "Move to library" to work, so
  # drop the RO bind and add a RW BindPaths for the same path instead.
  systemd.services.stash.serviceConfig.BindReadOnlyPaths = lib.mkForce [ ];
  systemd.services.stash.serviceConfig.BindPaths = [ stashDir ];

  systemd.services.stash.serviceConfig.UMask = "0077";
  systemd.services.stash.unitConfig.RequiresMountsFor = [ "/storage0" ];

  # After the upstream module rewrites config.yml from settings (every restart
  # with mutableSettings=false), patch the placeholder username with the real
  # one from sops so it never lands in /nix/store via the rendered settingsFile.
  #
  # NB: avoid `yq -i` here. Upstream's SystemCallFilter excludes @privileged,
  # which blocks fchownat — and yq -i's in-place write path calls fchownat to
  # preserve ownership on the temp file. The result is SIGSYS ("Bad system
  # call", exit 159). Read+write via shell redirection over a sibling tempfile
  # avoids fchownat entirely; mv within the same directory uses renameat2.
  systemd.services.stash.serviceConfig.ExecStartPre = lib.mkAfter [
    (pkgs.writers.writeBash "stash-username-from-sops" ''
      set -euo pipefail
      umask 0077
      env USERNAME=$(< ${config.sops.secrets.stash-username.path}) \
        ${lib.getExe pkgs.yq-go} '.username = strenv(USERNAME)' \
        ${dataDir}/config.yml > ${dataDir}/config.yml.tmp
      mv ${dataDir}/config.yml.tmp ${dataDir}/config.yml
      chmod 0600 ${dataDir}/config.yml
    '')
  ];
}
