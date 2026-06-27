{
  programs.yazi = {
    enable = true;
    shellWrapperName = "yy";

    # ratio = [ parent, current, preview ]; middle = current dir listing.
    settings.mgr.ratio = [
      1
      2
      4
    ];
  };
}
