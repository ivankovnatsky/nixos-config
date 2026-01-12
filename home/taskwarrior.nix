{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;

  homePath = config.home.homeDirectory;
  iCloudTaskDir = "${homePath}/Library/Mobile Documents/iCloud~com~mav~taskchamp/Documents/taskchamp";
  isWork = config.flags.purpose == "work";
  dataLocation = if isDarwin && !isWork then iCloudTaskDir else "${homePath}/.task";
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
  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;
    inherit dataLocation;
    colorTheme = if config.flags.darkMode then "no-color" else "light-256";
    config = {
      "default.due" = "eod";
      # Use home-manager managed hooks directory
      "hooks.location" = "${config.xdg.configHome}/task/hooks";
    }
    // (
      if isDarwin && !isWork then
        {
          "sync.local.server_dir" = iCloudTaskDir;
        }
      else
        { }
    );
  };

  # Auto-sync hooks: run after task modifications to sync with local server
  # https://taskwarrior.org/docs/hooks/
  # on-add and on-modify only trigger when data changes, unlike on-exit
  # Using Python to properly handle JSON with escaped newlines (\n)
  home.file."${config.xdg.configHome}/task/hooks/on-add-sync" = {
    executable = true;
    text = ''
      #!${pkgs.python3}/bin/python3
      import sys
      import subprocess
      # Pass through the task JSON unchanged (required for on-add hooks)
      for line in sys.stdin:
          print(line, end="")
      subprocess.run(["${pkgs.taskwarrior3}/bin/task", "rc.hooks=off", "rc.verbose=sync", "sync"])
    '';
  };

  home.file."${config.xdg.configHome}/task/hooks/on-modify-sync" = {
    executable = true;
    text = ''
      #!${pkgs.python3}/bin/python3
      import sys
      import subprocess
      # on-modify receives 2 lines: original + modified, must output 1 line: modified
      original = sys.stdin.readline()
      modified = sys.stdin.readline()
      print(modified, end="")
      subprocess.run(["${pkgs.taskwarrior3}/bin/task", "rc.hooks=off", "rc.verbose=sync", "sync"])
    '';
  };
}
