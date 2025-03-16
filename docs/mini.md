# mini

## Manual configuration

* Cleaned up GarageBand and other non-used non-default apps
* Logged in to Apple ID
  * Disable all iCloud toggles
* Enabled FileVault
* Configured syncthing to use default dir as /Volume/[StorageName]
* Enabled remote login -- this was enabled by `services.openssh.enable = true`
  * Enabled allow full disk access for remote users under `Remote Login`

On other machines:

```console
ssh-copy-id ivan@192.168.50.46
```
