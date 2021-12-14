{ pkgs, ... }:

{
  services.autorandr.enable = true;

  services.acpid = {
    enable = true;

    lidEventCommands = ''
      export DISPLAY=:0

      if grep -q open /proc/acpi/button/lid/LID/state; then
        ${pkgs.sudo}/bin/sudo -u ivan ${pkgs.autorandr}/bin/autorandr all
      else
        ${pkgs.sudo}/bin/sudo -u ivan ${pkgs.autorandr}/bin/autorandr monitor
      fi
    '';
  };
}
