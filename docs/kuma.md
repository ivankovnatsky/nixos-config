# Kuma

## Issues

### Corrupted DB?

```log
root@Ivans-Mac-mini:/tmp/log/launchd/ > grep -C 5 -i corrupt uptime-kuma.*
uptime-kuma.error.log:Trace: [Error: PRAGMA journal_mode = WAL - SQLITE_CORRUPT: database disk image is malformed] {
uptime-kuma.error.log-  errno: 11,
uptime-kuma.error.log:  code: 'SQLITE_CORRUPT'
uptime-kuma.error.log-}
uptime-kuma.error.log-    at process.unexpectedErrorHandler (/nix/store/7asjn2jb4vl33rp49ppa67l1f2i57ms5-uptime-kuma-1.23.16/lib/node_modules/uptime-kuma/server/server.js:1906:13)
uptime-kuma.error.log-    at process.emit (node:events:519:28)
uptime-kuma.error.log-    at emitUnhandledRejection (node:internal/process/promises:252:13)
uptime-kuma.error.log-    at throwUnhandledRejectionsMode (node:internal/process/promises:388:19)
root@Ivans-Mac-mini:/tmp/log/launchd/ > grep -C 10 -i corrupt uptime-kuma.*
uptime-kuma.error.log:Trace: [Error: PRAGMA journal_mode = WAL - SQLITE_CORRUPT: database disk image is malformed] {
uptime-kuma.error.log-  errno: 11,
uptime-kuma.error.log:  code: 'SQLITE_CORRUPT'
uptime-kuma.error.log-}
uptime-kuma.error.log-    at process.unexpectedErrorHandler (/nix/store/7asjn2jb4vl33rp49ppa67l1f2i57ms5-uptime-kuma-1.23.16/lib/node_modules/uptime-kuma/server/server.js:1906:13)
uptime-kuma.error.log-    at process.emit (node:events:519:28)
uptime-kuma.error.log-    at emitUnhandledRejection (node:internal/process/promises:252:13)
uptime-kuma.error.log-    at throwUnhandledRejectionsMode (node:internal/process/promises:388:19)
uptime-kuma.error.log-    at processPromiseRejections (node:internal/process/promises:475:17)
uptime-kuma.error.log-    at process.processTicksAndRejections (node:internal/process/task_queues:106:32)
uptime-kuma.error.log-If you keep encountering errors, please report to https://github.com/louislam/uptime-kuma/issues
uptime-kuma.error.log-Trace: Error [ERR_SERVER_NOT_RUNNING]: Server is not running.
uptime-kuma.error.log-    at Server.close (node:net:2359:12)
root@Ivans-Mac-mini:/tmp/log/launchd/ >
```

Just moved the db files aside and re-started the service

```console
cd /Volumes/Storage/Data/.uptime-kuma
mkdir -p db-backup
mv kuma* db-backup
launchctl kickstart -k system/org.nixos.uptime-kuma
```
