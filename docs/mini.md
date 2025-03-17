# mini

## Manual configuration

* Cleaned up GarageBand and other non-used non-default apps
* Logged in to Apple ID
  * Disable all iCloud toggles
* Enabled FileVault
* Configured syncthing to use default dir as /Volume/[StorageName]
* Enabled remote login -- this was enabled by `services.openssh.enable = true`
  * Enabled allow full disk access for remote users under `Remote Login`
* Enabled remote management, can't enable it using any automation clearly
  (https://www.reddit.com/r/macsysadmin/comments/13dhnmb/enable_remote_management_through_shell_script/?rdt=53927)
* Enabled file sharing
  * Added `/Volume/[StorageName]` to shared folders

On other machines:

```console
ssh-copy-id ivan@192.168.50.46
```
