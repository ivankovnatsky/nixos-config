{ config, ... }:

{
  home.file."Notes".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notes";
}
