# Nix Store Migration to External Storage (macOS)

## Migration Status: ✅ SUCCESSFULLY COMPLETED

### Migration Completed (2025-08-29)

**Status**: Nix store successfully migrated to external drive

### Final Configuration

**Successfully migrated /nix to external drive:**

- **Device**: `/dev/disk7s2` (external SSD)
- **Mount**: `/nix`
- **UUID**: `99FFCF5F-7706-42CB-BC36-BD2C548AFCF8`
- **Size**: 186GB total, 176GB available
- **Used**: 10GB (vs 23GB on internal - cleaned up metadata)

**Key discovery**: Removing `noauto` flag from fstab was critical - this allowed the system to automatically mount the external volume at `/nix` on boot.

### Current fstab Configuration (2025-08-29)

```
# UUID=57dbf488-6645-4357-9356-8e7efc8ab1c9 /nix apfs rw,noatime,noauto,nobrowse,nosuid,owners # Added by the Determinate Nix Installer
UUID=2C8AA2DB-28C8-4D59-A271-E37924692C87 /storage apfs rw,noatime,nosuid,owners
# UUID=99FFCF5F-7706-42CB-BC36-BD2C548AFCF8 /nix apfs rw,noatime,noauto,nobrowse,nosuid,owners # External Nix Store
UUID=99FFCF5F-7706-42CB-BC36-BD2C548AFCF8 /nix apfs rw,noatime,nobrowse,nosuid,owners # External Nix Store
```

**Notes:**

- Line 1: Original internal Nix Store UUID (commented out, preserved for rollback)
- Line 2: External storage volume mounted at `/storage`
- Line 3: Initial external Nix Store entry with `noauto` flag (commented out)
- Line 4: Working external Nix Store entry without `noauto` flag (active)

### Verified Working

- ✅ System boots normally with external /nix
- ✅ Nix commands functional
- ✅ External volume auto-mounts at `/nix` on boot
- ✅ Internal storage freed up: 23GB reclaimed
- ✅ Original internal volume still available at `/Volumes/Nix Store` as backup

### Commands Being Used

```console
# Clean volume
sudo rm -rf "/Volumes/Nix Store"/{.Spotlight-V100,.fseventsd,.Trashes,*}

# Copy essentials only
sudo rsync -av --progress /nix/store "/Volumes/Nix Store/"
sudo rsync -av --progress /nix/var "/Volumes/Nix Store/"
sudo cp /nix/.nix-installer-hook.* "/Volumes/Nix Store/"
sudo cp /nix/nix-installer "/Volumes/Nix Store/"
sudo cp /nix/receipt.json "/Volumes/Nix Store/"

# Fix permissions
sudo chgrp nixbld "/Volumes/Nix Store/store"
sudo chmod 1775 "/Volumes/Nix Store/store"
```

---

## Migration Progress (CANCELLED)

### ✅ Phase 1: Volume Creation (COMPLETED then DELETED)

**Created external Nix volume:**

- **Volume**: `/Volumes/Nix Store`
- **Device**: `disk7s2`
- **UUID**: `7E5F5407-515C-45A8-8E9E-6F56F8DB53FF`
- **Size**: 200GB quota
- **Status**: Successfully created and mounted

**Original /nix volume (backup):**

- **Volume**: `/nix`
- **Device**: `disk3s7`
- **UUID**: `57dbf488-6645-4357-9356-8e7efc8ab1c9`
- **Used**: 23GB / 228GB
- **Status**: Keeping as backup during migration

### ✅ Phase 2: Data Migration (COMPLETED)

**Volume remount with ownership support:**

- **Issue**: Initial volume mount didn't support ownership
- **Fix**: `sudo diskutil unmount "/Volumes/Nix Store"` then `sudo diskutil mount -mountOptions owners "/dev/disk7s2"`
- **Status**: Volume properly mounted with ownership support

**Data copy with correct permissions:**

1. **Clear incorrect data**: `sudo rm -rf "/Volumes/Nix Store"/{store,var,*.log,nix-installer,receipt.json,.Trashes,.nix-installer-hook.*}`
2. **Copy with preserved permissions**: `sudo rsync -a --numeric-ids --progress /nix/ "/Volumes/Nix Store/"`
3. **Fix store directory ownership**: `sudo chgrp nixbld "/Volumes/Nix Store/store"` and `sudo chmod 1775 "/Volumes/Nix Store/store"`

**Results:**

- **Data copied**: 35.6GB on external (vs 23GB original - expected overhead)
- **Permissions**: Correct `root wheel` and `root nixbld` ownership verified
- **Store directory**: Properly set to `root:nixbld` with `1775` permissions

### ✅ Phase 3: System Configuration (COMPLETED)

**fstab backup and update:**

1. **Backup created**: `sudo cp /etc/fstab /etc/fstab.backup.20250829`
2. **Original commented**: `#UUID=57dbf488-6645-4357-9356-8e7efc8ab1c9 /nix apfs rw,noatime,noauto,nobrowse,nosuid,owners # Added by the Determinate Nix Installer`
3. **New entry added**: `UUID=7E5F5407-515C-45A8-8E9E-6F56F8DB53FF /nix apfs rw,noatime,noauto,nobrowse,nosuid,owners # External Nix Store`

**Status**: fstab updated, ready for reboot test

### ❌ Phase 4: System Integration Testing (FAILED - MOUNT ISSUE)

**Issue discovered in ISSUES_MIGRATION_REBOOT_2nd.md:**

- External volume `/Volumes/Nix Store` mounts successfully (disk7s2)
- `sudo mount /nix` fails with "unknown special file or file system"
- fstab entry exists but manual mount doesn't work

**Root cause analysis:**

1. **External drive dependency**: `/Volumes/Nix Store` must be mounted first
2. **Manual mount limitation**: `sudo mount /nix` doesn't work with UUID-only reference
3. **Device path required**: Need explicit device path for manual mounting

**Corrected approach needed:**

1. **Manual mount command**: `sudo mount -t apfs /dev/disk7s2 /nix`
2. **Verify fstab UUID**: Ensure external volume UUID is correct in fstab
3. **Test auto-mount**: Reboot to test if daemon can auto-mount from fstab
4. **Alternative**: Use symlink approach if mount issues persist

**Status**: Migration paused due to mount failure - need revised approach

### 🔧 Troubleshooting Session (2025-08-29 17:19)

**Issue confirmed**: External volume auto-remounts to `/Volumes/Nix Store` after unmount
**Mount conflict**: Cannot mount `/dev/disk7s2` to `/nix` while it's mounted at `/Volumes/Nix Store`
**Error**: `mount_apfs: volume could not be mounted: Resource busy`

**Working solution sequence:**

1. `sudo diskutil unmount "/Volumes/Nix Store"` ✅ (successfully unmounted)
2. `sudo mount -t apfs /dev/disk7s2 /nix` ✅ (SUCCESS - external volume mounted to /nix)

**⚠️ CRITICAL DISCOVERY**: Dual mount situation detected!

```console
df -h | grep /nix
/dev/disk3s7         228Gi    32Gi   143Gi    19%    2.0M  1.5G    0%   /nix  ← Internal (original)
/dev/disk7s2         186Gi    32Gi   154Gi    18%    3.8M  1.6G    0%   /nix  ← External (new)
```

**Problem**: Both internal and external volumes mounted at `/nix` - external is shadowing internal
**Unmount attempt**: `sudo diskutil unmount /dev/disk3s7` failed - system processes using internal /nix
**Error**: `dissented by PID 390 (/System/Library/Frameworks/CoreServices.framework/.../mds)`

**SOLUTION**: Reboot required to cleanly switch from internal to external /nix

### 🔄 Phase 4: fstab Dependency Configuration (IN PROGRESS)

**Current state**: Migration 95% complete - data copied, manual mount works, fstab updated
**Issue**: External Storage volume needs to mount before `/nix` for proper dependency order
**Discovery**: Storage volume UUID = `0B97C785-04A6-4D11-84EE-2FE2B120FB84`

**Next steps:**

1. **Add Storage to fstab**: Ensure `/Volumes/Storage` mounts before `/nix`
2. **Test Storage dependency**: Verify mount order works correctly
3. **Consider keeping noauto**: May keep `noauto` flag for Nix daemon control
4. **Reboot test**: Full system reboot to verify auto-mount sequence

**fstab update command:**

```console
sudo bash -c 'echo "UUID=0B97C785-04A6-4D11-84EE-2FE2B120FB84 /Volumes/Storage apfs rw,noatime,nosuid,owners # External Storage Drive" >> /etc/fstab'
```

**Key insight**: Manual `mount` command successfully changes mount point from `/Volumes/Nix Store` to `/nix`
**Nix test result**: `nix-env --version` works (using external store - shadowing internal)

## Current System State

- External Storage drive: 2.6TB available space
- New Nix Store volume: Ready for data migration
- Original /nix: Preserved as backup
- Performance tested: ~800MB/s read/write (sufficient for Nix operations)

## Corrected Migration Plan

### Option 1: Manual Mount + Daemon Test

**Steps to complete migration:**

1. **Manual mount for testing**: `sudo mount -t apfs /dev/disk7s2 /nix`
2. **Test Nix functionality**: Verify `/nix` access and basic commands work
3. **If successful**: Reboot to test automatic mount via daemon
4. **If auto-mount works**: Migration complete
5. **If auto-mount fails**: Proceed to Option 2

### Option 2: Symlink Approach (Fallback)

**If fstab auto-mount doesn't work:**

1. **Remove fstab entry**: Comment out external UUID line
2. **Restore original**: Uncomment original internal UUID
3. **Create symlink**: `sudo ln -sf "/Volumes/Nix Store" /nix-external`
4. **Update daemon**: Configure Nix to use /nix-external instead of /nix

**Benefits of symlink approach:**

- No fstab changes required
- External drive can mount normally to `/Volumes/Nix Store`
- Less risky than fstab modifications
- Easy rollback by removing symlink

### Testing Commands

**Current state verification:**

```console
df -h | grep -E "(disk3s7|disk7s2|Nix)"
mount | grep nix
cat /etc/fstab | grep -v "^#"
```

**Manual mount test:**

```console
sudo umount /nix                        # Unmount current
sudo mount -t apfs /dev/disk7s2 /nix     # Mount external
ls -la /nix/store | head                 # Verify contents
nix-env --version                        # Test functionality
```

## Recovery Information

**Immediate rollback if needed:**

```console
# Restore original fstab
sudo cp /etc/fstab.backup.20250829 /etc/fstab

# Or manually edit to uncomment original UUID:
# UUID=57dbf488-6645-4357-9356-8e7efc8ab1c9 /nix apfs rw,noatime,noauto,nobrowse,nosuid,owners
```

**Boot Recovery if system fails:**

- **Boot Recovery**: Hold Command+R, fix fstab in Terminal
- **Original UUID**: `57dbf488-6645-4357-9356-8e7efc8ab1c9`
- **Backup volume**: Original /nix volume preserved until migration verified

---

**Session 2 Progress (2025-08-29 17:19-17:23):**

- ✅ Confirmed external volume auto-mounts to `/Volumes/Nix Store`
- ✅ Discovered manual mount changes mount point to `/nix`
- ✅ Verified Nix functionality works on external store
- ⚠️ Found dual mount issue (both internal and external at `/nix`)
- 🎯 Ready for reboot to complete migration

---

_Migration started: 2025-08-29 16:01_
_Session 2: 2025-08-29 17:19 - Manual mount testing_
_Migration cancelled: 2025-08-29 - External volume deleted, keeping Nix on internal storage_
_Recommendation: Upgrade internal SSD using expandmacmini.com instead_
