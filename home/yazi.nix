{ pkgs, ... }:
{
  programs.yazi = {
    enable = true;
    shellWrapperName = "yy";

    # ratio = [ parent, current, preview ]; middle = current dir listing.
    settings.mgr.ratio = [
      1
      1
      5
    ];

    # Our flake auto-exposes packages/settings as `pkgs.settings`. nixpkgs'
    # yazi/package.nix has a `settings ? {}` function arg, so callPackage
    # silently injects our `settings` CLI as yazi's settings. That flips the
    # wrapper's `configHome` to non-null and force-sets YAZI_CONFIG_HOME to a
    # store dir without yazi.toml, so ~/.config/yazi/yazi.toml (the settings
    # above) gets ignored. Pass settings = {} to undo the injection so yazi
    # reads ~/.config/yazi normally.
    package = pkgs.yazi.override { settings = { }; };
  };
}
