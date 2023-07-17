{
  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host *
        StrictHostKeyChecking accept-new
    '';
  };
}
