{ pkgs }:

# ```json
# [
#   ...
#   ,
#   {
#     "pid": 440,
#     "ppid": 1,
#     "name": "loginwindow",
#     "status": "Sleep",
#     "cpu": 0.0,
#     "mem": 48529408,
#     "virtual": 446171676672,
#     "command": "/System/Library/CoreServices/loginwindow.app/Contents/MacOS/loginwindow console",
#     "start_time": "2025-11-30 21:05:31 +02:00",
#     "user_id": 501,
#     "priority": 48,
#     "process_threads": 5,
#     "cwd": ""
#   }
# ]
# ```

pkgs.writeScriptBin "ps-top-nu" ''
  #!${pkgs.nushell}/bin/nu
  ps --long | sort-by cpu --reverse | first 10 | select pid ppid status cpu mem command
''
