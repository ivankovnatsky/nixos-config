# mini

## Manual configuration

* Cleaned up GarageBand and other non-used non-default apps
* Logged in to Apple ID
  * Disable all iCloud toggles
* Enabled FileVault
* Configured syncthing to use default dir as /Volume/[StorageName]
* Enabled remote login -- this was enabled by `services.openssh.enable = true`
  * Enabled allow full disk access for remote users under `Remote Login`
* Enabled Screen Sharing
* Disabled for now: Enabled remote management, can't enable it using any automation clearly
  (https://www.reddit.com/r/macsysadmin/comments/13dhnmb/enable_remote_management_through_shell_script/?rdt=53927)
* Enabled file sharing
  * Added `/Volume/[StorageName]` to shared folders
  * Enable full disk access for all users, otherwise you can't have access,
    automation can't do it for now or by design?
  * Need to grant all different service with access to disk, namely:
    * Syncthing?
    * watchman / make ?
* Enable auto login in System Settings
* Remove `noauto` from /etc/fstab for /nix store, having issues with launchd
  services that can't be started due to /nix mount point not mounted yet:
  ```logs
  2025-03-25 08:59:04.800168+0200 0xf0c      Error       0x0                  1      0    launchd: [system/org.nixos.stubby [564]:] Service could not initialize: access(/nix/store/6kkfq97xl9p293lxfv59q79kg8bp63sn-stubby-0.4.3/bin/stubby, X_OK) failed with errno 2 - No such file or directory, error 0x6f - Invalid or missing Program/ProgramArguments
  2025-03-25 08:59:04.800170+0200 0xf0c      Error       0x0                  1      0    launchd: [system/org.nixos.stubby [564]:] initialization failure: 24D81: xpcproxy + 36768 [1088][E4C3A3C3-0D57-3E4D-8388-880BC7F5F19E]: 0x6f
  2025-03-25 08:59:04.800172+0200 0xf0c      Default     0x0                  1      0    launchd: [system/org.nixos.stubby [564]:] Service setup event to handle failure and will not launch until it fires.
  2025-03-25 08:59:04.800173+0200 0xf0c      Error       0x0                  1      0    launchd: [system/org.nixos.stubby [564]:] Missing executable detected. Job: 'org.nixos.stubby' Executable: '/nix/store/6kkfq97l9p293lxfv59q79kg8bp63sn-stubby-0.4.3/bin/stubby'
  2025-03-25 08:59:04.800178+0200 0xf0c      Default     0x0                  1      0    launchd: [system/org.nixos.stubby [564]:] internal event: INIT, code = 111
  2025-03-25 08:59:04.800497+0200 0xf0b      Default     0x0                  1      0    launchd: [system/org.nixos.dnsmasq [565]:] Could not find and/or execute program specified by service: 2: No such file or directory: /nix/store/iyda7xpkkwsnji14x6b4370an9h7m97h-dnsmasq-2.90/bin/dnsmasq
  2025-03-25 08:59:04.800499+0200 0xf0b      Error       0x0                  1      0    launchd: [system/org.nixos.dnsmasq [565]:] Service could not initialize: access(/nix/store/iyda7xpkkwsnji14x6b4370an9h7m97h-dnsmasq-2.90/bin/dnsmasq, X_OK) failed with errno 2 - No such file or directory, error 0x6f - Invalid or missing Program/ProgramArguments
  2025-03-25 08:59:04.800501+0200 0xf0b      Error       0x0                  1      0    launchd: [system/org.nixos.dnsmasq [565]:] initialization failure: 24D81: xpcproxy + 36768 [1088][E4C3A3C3-0D57-3E4D-8388-880BC7F5F19E]: 0x6f
  2025-03-25 08:59:04.800502+0200 0xf0b      Default     0x0                  1      0    launchd: [system/org.nixos.dnsmasq [565]:] Service setup event to handle failure and will not launch until it fires.
  2025-03-25 08:59:04.800503+0200 0xf0b      Error       0x0                  1      0    launchd: [system/org.nixos.dnsmasq [565]:] Missing executable detected. Job: 'org.nixos.dnsmasq' Executable: '/nix/store/iyda7xpkkwsnji14x6b4370an9h7m97h-dnsmasq-2.90/bin/dnsmasq'
  ```

  ```
  ivan@Ivans-Mac-mini:~/ > cat /etc/fstab 
  UUID=57dbf488-6645-4357-9356-8e7efc8ab1c9 /nix apfs rw,noatime,noauto,nobrowse,nosuid,owners # Added by the Determinate Nix Installer
  ivan@Ivans-Mac-mini:~/ >
  ```

  * Seems like noauto still did not help
  * This was resolved by using /bin/wait4path utility already used in command
    directive in launchd nix-darwin module and for own modules that using
    external volume we added it to custom scripts
* Disabled encryption/FileVault to be able to autologin
  * Also faced at least once that system wanted to unlock encrypted /nix store
    volume, which it turns out determinate encrypts by defaults and writes key to
    system keychain
  * Decrypted /nix store to avoid issue above:
    ```console
    sudo diskutil apfs decryptVolume disk3s7
    ```

On other machines:

```console
ssh-copy-id ivan@192.168.50.46
```

## Upgrade notes

### `post-build` script hanged

```console
sudo vim /nix/var/determinate/post-build-hook.sh
# Place exit 0 at the top of the file
```

#### References

* https://www.reddit.com/r/Nix/comments/1iuqxrw/nixdarwin_switch_hangs_forever/
* https://github.com/DeterminateSystems/nix-installer/issues/1479
* https://github.com/DeterminateSystems/nix-installer/issues/1500

### Git repo is not owned by current user

```logs
building the system configuration...
error:
       … while fetching the input 'git+file:///Volumes/Storage/Data/Sources/github.com/ivankovnatsky/nixos-config'

       error: opening Git repository "/Volumes/Storage/Data/Sources/github.com/ivankovnatsky/nixos-config": repository path '/Volumes/Storage/Data/Sources/github.com/ivankovnatsky/nixos-config' is not owned by current user
ivan@Ivans-Mac-mini:/Volumes/Storage/Data/Sources/github.com/ivankovnatsky/nixos-config/ >
```

```console
cd ../
cp -rv nixos-config ~/
cd ~/nixos-config
cd -
cd nixos-config
make rebuild-darwin-sudo
```

### Full Disk access / Removable disk

On boot tmux rebuild service can't get access to /Volumes/Storage

Still an issue.

## TODO

- [ ] Add /Volumes/Storage to /etc/fstab
