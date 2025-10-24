{
  writeShellScriptBin,
  python3,
  python3Packages,
  watchman,
}:

writeShellScriptBin "rebuild-daemon" ''
  export PATH="${python3Packages.pywatchman}/bin:${watchman}/bin:$PATH"
  exec ${python3}/bin/python ${./rebuild_daemon/main.py} "$@"
''
