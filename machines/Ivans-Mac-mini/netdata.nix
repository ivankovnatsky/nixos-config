{ ... }:
{
  services.netdata.enable = true;
  
  # Create the opt-out file in the Netdata configuration directory
  environment.etc."netdata/.opt-out-from-anonymous-statistics".text = "";
}
