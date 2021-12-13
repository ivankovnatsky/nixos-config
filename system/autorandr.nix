{ pkgs, ... }:

let
  autorandr-change-script = pkgs.writeScriptBin "change" ''
    #!${pkgs.bash}/bin/bash

    ${pkgs.autorandr}/bin/autorandr --change
  '';
in
{
  services.autorandr.enable = true;
  services.acpid.enable = true;

  environment.etc."acpi/events/lid-switch" = {
    text = ''
      event=button/lid LID (open|close)
      action=${autorandr-change-script}/bin/change
    '';
  };
}
