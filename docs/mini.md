# mini

## Manual configuration

- Cleaned up GarageBand and other non-used non-default apps
- Logged in to Apple ID
  - Disable all iCloud toggles
- Enabled FileVault
- Configured syncthing to use default dir as /Volume/[StorageName]
- Enabled remote login -- this was enabled by `services.openssh.enable = true`
  - Enabled allow full disk access for remote users under `Remote Login`
- Enabled Screen Sharing
- Disabled for now: Enabled remote management, can't enable it using any automation clearly
  (https://www.reddit.com/r/macsysadmin/comments/13dhnmb/enable_remote_management_through_shell_script/?rdt=53927)
- Enabled file sharing
  - Added `/Volume/[StorageName]` to shared folders
  - Enable full disk access for all users, otherwise you can't have access,
    automation can't do it for now or by design?
  - Need to grant all different service with access to disk, namely:
    - Syncthing?
    - watchman / make ?
- Enable auto login in System Settings
- Remove `noauto` from /etc/fstab for /nix store, having issues with launchd
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

  - Seems like noauto still did not help
  - This was resolved by using /bin/wait4path utility already used in command
    directive in launchd nix-darwin module and for own modules that using
    external volume we added it to custom scripts

- Disabled encryption/FileVault to be able to autologin
  - Also faced at least once that system wanted to unlock encrypted /nix store
    volume, which it turns out determinate encrypts by defaults and writes key to
    system keychain
  - Decrypted /nix store to avoid issue above:
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

- https://www.reddit.com/r/Nix/comments/1iuqxrw/nixdarwin_switch_hangs_forever/
- https://github.com/DeterminateSystems/nix-installer/issues/1479
- https://github.com/DeterminateSystems/nix-installer/issues/1500

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

## OrbStack Kubernetes Networking

### NodePort Localhost Binding

OrbStack binds NodePorts to localhost only, unlike standard Kubernetes which binds to all interfaces:

```console
lsof -i :30080
COMMAND    PID USER   FD   TYPE            DEVICE SIZE/OFF NODE NAME
OrbStack  1109 ivan  129u  IPv4 0xf5c8c1e43046b90      0t0  TCP localhost:30080 (LISTEN)
```

This means NodePort services are not accessible from external machines (like bee) without additional forwarding.

**Solution**: Use Caddy to forward from external interface to localhost NodePort:

```caddyfile
# K8s NodePort forwarding (mini machine only)
:30080 {
    bind @bindAddress@
    reverse_proxy localhost:30080
}
```

This enables the routing chain: `External machine → Mini external IP:30080 → Mini localhost:30080 → OrbStack NodePort → K8s Service`

### OrbStack HTTPS/TLS Configuration

OrbStack requests keychain access to automatically configure HTTPS for its local VM services using the `orb.local` domain.

**Keychain Access Request**: When granted, OrbStack can automatically manage TLS certificates for local development services, making them accessible via `https://service.orb.local`.

**Implications for Caddy Routing**:

- Services in mini-vm may be accessible via both `http://service.orb.local` and `https://service.orb.local`
- When configuring Caddy to route to mini-vm services, consider the TLS termination:
  - **Option 1**: Route to HTTP endpoint and let Caddy handle TLS
  - **Option 2**: Route to HTTPS endpoint (requires proper certificate handling)

**Configuration Considerations**:

```caddyfile
# Route to HTTP service in mini-vm (Caddy handles TLS)
service.externalDomain {
    reverse_proxy http://service.orb.local:8080
}

# Or route to HTTPS service (if OrbStack manages certificates)
service.externalDomain {
    reverse_proxy https://service.orb.local:8443
}
```

**Note**: The `orb.local` domain is only accessible from the mini machine, so external routing must go through Caddy on the mini host.

## OrbStack VM Network Limitations

### Link-Local Address Access (169.254.0.0/16)

- **Cannot reach** devices using link-local addresses from OrbStack VMs or K8s pods
- Link-local addresses are not routable by design (RFC 3927)
- Only work within the same network segment/broadcast domain
- **hostNetwork: true** in K8s does NOT solve this - the "host" is still the OrbStack VM

### Services That Should NOT Be Moved to OrbStack K8s

- **Homebridge with Elgato plugins** - Needs direct access to 169.254.x.x devices
- **Matter-bridge** - Requires mDNS discovery on physical network
- **IoT device integrations** - Many devices fall back to link-local addressing
- **Hardware coordinators** - Zigbee/Z-Wave need direct USB access

### Alternative Solutions

1. **Keep on physical machines** - Deploy on bee/mini host with full network access
2. **Docker with --network=host on physical host** - Container shares host networking (not VM host)

### Testing Connectivity

```console
# From mini host (should work)
ping 169.254.1.144

# From OrbStack VM or K8s pod (will fail)
kubectl exec -n homebridge pod-name -- curl --connect-timeout 5 http://169.254.1.144:9123
```

## TODO

- [ ] Add /Volumes/Storage to /etc/fstab
