{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    pulseaudio
  ];

  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
  };
}
