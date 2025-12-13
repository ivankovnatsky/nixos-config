# Nix Store Migration Back to Internal Drive

## Current State

- External /nix: `/dev/disk7s2` (19GB store after gc + 21GB Spotlight junk)
- External UUID: `99FFCF5F-7706-42CB-BC36-BD2C548AFCF8`
- Internal disk3: 173GB free (enough for 121GB nix store)
- Internal Nix volume: **deleted** - needs to be recreated

## Commands

```console
# 1. Backup fstab
sudo cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d)

# 2. Create new APFS volume on internal disk
sudo diskutil apfs addVolume disk3 APFS "Nix Store" -quota 50g

# 3. Get new volume UUID (note this for fstab)
diskutil info /dev/disk3s7 | grep "Volume UUID"

# 4. Copy essential data (skip Spotlight/fseventsd junk)
sudo rsync -av --progress /nix/store "/Volumes/Nix Store/"
sudo rsync -av --progress /nix/var "/Volumes/Nix Store/"
sudo cp /nix/nix-installer "/Volumes/Nix Store/"
sudo cp /nix/receipt.json "/Volumes/Nix Store/"
sudo cp /nix/.nix-installer-hook.* "/Volumes/Nix Store/"

# 5. Fix permissions
sudo chgrp nixbld "/Volumes/Nix Store/store"
sudo chmod 1775 "/Volumes/Nix Store/store"

# 6. Update fstab with new internal UUID
sudo vim /etc/fstab
```

## fstab Change

From:
```
# UUID=57dbf488-6645-4357-9356-8e7efc8ab1c9 /nix apfs rw,noatime,noauto,nobrowse,nosuid,owners # Added by the Determinate Nix Installer
UUID=2C8AA2DB-28C8-4D59-A271-E37924692C87 /storage apfs rw,noatime,nosuid,owners
# UUID=99FFCF5F-7706-42CB-BC36-BD2C548AFCF8 /nix apfs rw,noatime,noauto,nobrowse,nosuid,owners # External Nix Store
UUID=99FFCF5F-7706-42CB-BC36-BD2C548AFCF8 /nix apfs rw,noatime,nobrowse,nosuid,owners # External Nix Store
```

To:
```
# UUID=57dbf488-6645-4357-9356-8e7efc8ab1c9 /nix apfs rw,noatime,noauto,nobrowse,nosuid,owners # Added by the Determinate Nix Installer
UUID=2C8AA2DB-28C8-4D59-A271-E37924692C87 /storage apfs rw,noatime,nosuid,owners
# UUID=99FFCF5F-7706-42CB-BC36-BD2C548AFCF8 /nix apfs rw,noatime,noauto,nobrowse,nosuid,owners # External Nix Store
# UUID=99FFCF5F-7706-42CB-BC36-BD2C548AFCF8 /nix apfs rw,noatime,nobrowse,nosuid,owners # External Nix Store
UUID=157F9492-971E-42D1-995A-BA8C87E27179 /nix apfs rw,noatime,nobrowse,nosuid,owners # Internal Nix Store
```

## Reboot and Verify

```console
sudo reboot
```

## Cleanup Old External Volume

After verifying internal nix store works, delete the old external volume to reclaim 45GB:

```console
# Verify disk7s2 is the old external Nix Store
diskutil info /dev/disk7s2 | grep -E "Volume Name|Volume UUID"

# Delete it
sudo diskutil apfs deleteVolume disk7s2
```
