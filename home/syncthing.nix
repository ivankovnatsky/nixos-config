{
  #  https://github.com/nix-community/home-manager/blob/master/modules/services/syncthing.nix
  services.syncthing = {
    enable = true;
  };

  home.file.".config/syncthing/ignore".text = ''
    // Rust-specific ignores
    target/
    Cargo.lock
    **/*.rs.bk
    
    // Incomplete Downloads
    // Firefox downloads
    *.part
    // Chrom(ium|e) downloads
    *.crdownload
    // Transmission downloads
    *.part

    // Temporary/Backup Files
    *~
    .*.swp

    // OS-generated files (linux)
    .directory
    .Trash-*

    // OS-generated files (macOS)
    .DS_Store
    .AppleDouble
    .LSOverride
    // Icon must end with two \r
    Icon
    // Thumbnails (metadata)
    ._*
    // Files that might appear in the root of a volume
    .DocumentRevisions-V100
    .fseventsd
    .Spotlight-V100
    .TemporaryItems
    .Trashes
    .VolumeIcon.icns
    .com.apple.timemachine.donotpresent
    .localized
    // Directories potentially created on remote AFP share
    .AppleDB
    .AppleDesktop
    Network Trash Folder
    Temporary Items
    .apdisk
    // iCloud temp files
    .iCloud*

    // OS-generated files (Windows)
    // Windows thumbnail cache files
    Thumbs.db
    Thumbs.db:encryptable
    ehthumbs.db
    ehthumbs_vista.db
    // Dump file
    *.stackdump
    // Folder config file
    [Dd]esktop.ini
    // Recycle Bin used on file shares
    $RECYCLE.BIN/
    // Windows Installer files
    *.cab
    *.msi
    *.msix
    *.msm
    *.msp
    // Windows shortcuts
    *.lnk
    // Microsoft Office temp files
    (?d)~*

    // BTSync files
    .sync
    *.bts
    *.!Sync
    .SyncID
    .SyncIgnore
    .SyncArchive
    *.SyncPart
    *.SyncTemp
    *.SyncOld

    // Synology files
    @eaDir

    // Syncthing files
    .stignore
    .stfolder
    .stversions
    .syncthing.*

    // vim swap files
    (?d)*.*.sw[a-p]
  '';
}
