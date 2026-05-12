# Disable sleep/suspend/hibernate, keep screen blanking.
# Reference: machines/Ivans-Mac-mini/darwin/server/power.nix
# https://wiki.nixos.org/wiki/NVIDIA#Graphical_corruption_and_system_crashes_on_suspend/resume
{
  # Disable suspend/hibernate via logind
  services.logind.settings.Login = {
    HandleSuspendKey = "ignore";
    HandleSuspendKeyLongPress = "ignore";
    HandleHibernateKey = "ignore";
    HandleHibernateKeyLongPress = "ignore";
    IdleAction = "ignore";
  };

  # Prevent systemd from entering sleep/hibernate states
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };
}
