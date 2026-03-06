{
  config,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;

  homePath = config.home.homeDirectory;
  iCloudTaskDir = "${homePath}/Library/Mobile Documents/iCloud~com~mav~taskchamp/Documents/taskchamp";
  isWork = config.flags.purpose == "work";
  # Keep Mac replica local to avoid iCloud corruption — iOS owns the iCloud
  # taskchampion.sqlite3, Mac syncs through taskchampion-local-sync-server.sqlite3
  dataLocation = "${homePath}/.task";

  # Light-optimized theme (foreground-only, no background colors)
  # taskColorsLightOptimized = {
  #   "color.header" = "bold color237";
  #   "color.id" = "color26";
  #   "color.active" = "bold color22";
  #   "color.overdue" = "bold color160";
  #   "color.due.today" = "bold color202";
  #   "color.due" = "color33";
  #   "color.pri.H" = "bold color160";
  #   "color.pri.M" = "color202";
  #   "color.pri.L" = "color244";
  #   "color.completed" = "color241";
  #   "color.deleted" = "color238";
  #   "color.tag.next" = "color55";
  #   "color.tagged" = "color97";
  #   "color.project.none" = "color244";
  #   "color.alternate" = "";
  #   "color.recurring" = "color63";
  #   "color.blocking" = "bold color130";
  #   "color.blocked" = "color244";
  #   "color.undo.before" = "color160";
  #   "color.undo.after" = "color28";
  #   "color.calendar.today" = "bold color26";
  #   "color.calendar.due" = "color160";
  #   "color.calendar.due.today" = "bold color160";
  #   "color.calendar.overdue" = "bold color124";
  #   "color.calendar.weekend" = "color237";
  #   "color.calendar.holiday" = "bold color100";
  #   "color.calendar.weeknumber" = "color244";
  #   "color.sync.added" = "color28";
  #   "color.sync.changed" = "color202";
  #   "color.sync.rejected" = "color160";
  # };

  # Dual-mode theme (foreground-only, ANSI 256 mid-range 60–210)
  taskColorsDualMode = {
    "color.header" = "bold color244";
    "color.id" = "color69";
    "color.active" = "bold color64";
    "color.overdue" = "bold color160";
    "color.due.today" = "bold color160";
    "color.due" = "color69";
    "color.pri.H" = "bold color160";
    "color.pri.M" = "color166";
    "color.pri.L" = "color244";
    "color.completed" = "color242";
    "color.deleted" = "color238";
    "color.tag.next" = "bold color62";
    "color.tagged" = "color97";
    "color.project.none" = "color244";
    "color.alternate" = "";
    "color.recurring" = "color30";
    "color.blocking" = "bold color136";
    "color.blocked" = "color244";
    "color.undo.before" = "color160";
    "color.undo.after" = "color64";
    "color.calendar.today" = "bold color69";
    "color.calendar.due" = "color166";
    "color.calendar.due.today" = "bold color160";
    "color.calendar.overdue" = "bold color160";
    "color.calendar.weekend" = "color244";
    "color.calendar.holiday" = "bold color136";
    "color.calendar.weeknumber" = "color244";
    "color.sync.added" = "color64";
    "color.sync.changed" = "color166";
    "color.sync.rejected" = "color160";
  };
in
{
  # https://github.com/nix-community/home-manager/blob/master/modules/programs/taskwarrior.nix
  #
  # Fix orphaned tasks in backlog.data (if export returns fewer tasks than expected):
  #
  # The backlog.data file may contain tasks that never made it to pending.data/completed.data.
  # To rebuild the database from backlog, extract latest version of each task by UUID:
  #
  # ```console
  # python3 -c "
  # import json
  # tasks = {}
  # with open('$HOME/.task/backlog.data', 'r') as f:
  #     for line in f:
  #         line = line.strip()
  #         if not line:
  #             continue
  #         try:
  #             t = json.loads(line)
  #             uuid = t.get('uuid')
  #             if uuid:
  #                 tasks[uuid] = line
  #         except:
  #             pass
  # for line in tasks.values():
  #     print(line)
  # " > /tmp/unique-backlog.data
  # grep '"status":"pending"' /tmp/unique-backlog.data >> ~/.task/pending.data
  # grep -E '"status":"(completed|deleted)"' /tmp/unique-backlog.data >> ~/.task/completed.data
  # ```
  #
  # Then deduplicate completed.data (original entries may overlap with backlog):
  #
  # ```console
  # cd ~/.task && python3 -c "
  # import json
  # tasks = {}
  # with open('completed.data', 'r') as f:
  #     for line in f:
  #         line = line.strip()
  #         if not line: continue
  #         try:
  #             t = json.loads(line)
  #             tasks[t['uuid']] = line
  #         except: pass
  # with open('completed.data', 'w') as f:
  #     for line in tasks.values():
  #         f.write(line + '\n')
  # print(f'Deduped: {len(tasks)} unique tasks')
  # "
  # ```
  #
  # Migration from taskwarrior 2.x to 3.x
  #
  # 1. Backup current task directory:
  #
  # ```console
  # cp -r ~/.task ~/.task.backup
  # ```
  #
  # 2. Export tasks from old taskwarrior 2.x:
  #
  # ```console
  # nix run nixpkgs#taskwarrior2 -- \
  #   rc.data.location=~/.task rc.gc=off export 2>/dev/null \
  #   > /tmp/tasks-backup.json
  # ```
  #
  # 3. Configure iCloud sync (Darwin only):
  #
  # Reference: https://github.com/marriagav/taskchamp#setup-with-icloud-drive
  #
  # Prerequisites:
  # - Disable "Optimize Mac Storage" in System Settings → Apple ID → iCloud → iCloud Drive
  # - Open TaskChamp on iOS and select "iCloud Sync" to create the iCloud folder
  #
  # 4. Backup iCloud taskchamp directory:
  #
  # ```console
  # cp -r ~/Library/Mobile\ Documents/iCloud~com~mav~taskchamp/Documents/taskchamp \
  #   ~/Library/Mobile\ Documents/iCloud~com~mav~taskchamp/Documents/taskchamp.backup
  # ```
  #
  # 5. Import tasks into new taskwarrior3:
  #
  # ```console
  # nix run nixpkgs#taskwarrior3 -- \
  #   rc.data.location="~/Library/Mobile Documents/iCloud~com~mav~taskchamp/Documents/taskchamp" \
  #   import /tmp/tasks-backup.json
  # ```
  #
  # 6. Sync to local server:
  #
  # ```console
  # task sync
  # ```
  #
  # 7. Wait for iOS to load the database, then delete taskchampion.sqlite3 and sync again:
  #    (This triggers iOS to perform a correct sync)
  #    https://github.com/marriagav/taskchamp#setup-with-icloud-drive
  #
  # ```console
  # rm ~/Library/Mobile\ Documents/iCloud~com~mav~taskchamp/Documents/taskchamp/taskchampion.sqlite3*
  # task sync
  # ```
  #
  # 8. Remove empty .data files (leftover from v2 format that cause warnings):
  #
  # ```console
  # rm ~/Library/Mobile\ Documents/iCloud~com~mav~taskchamp/Documents/taskchamp/*.data
  # ```
  #
  # 9. Initialize git in iCloud Documents dir to track unneeded changes:
  #
  # ```console
  # git init ~/Library/Mobile\ Documents/iCloud~com~mav~taskchamp/Documents
  # ```
  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;
    inherit dataLocation;
    # https://taskwarrior.org/docs/themes/
    # colorTheme = if config.flags.darkMode then "dark-256" else "light-256";
    config = {
      # Use home-manager managed hooks directory
      "hooks.location" = "${config.xdg.configHome}/task/hooks";
    }
    // taskColorsDualMode
    // (
      if isDarwin && !isWork then
        {
          "sync.local.server_dir" = iCloudTaskDir;
        }
      else
        { }
    );
  };

}
