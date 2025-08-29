{ config, lib, ... }:

# To get the public key for the cache server, run on the bee machine after deployment:
# cat /var/lib/nix-serve/cache-pub-key.pem

let
  inherit (config.secrets) externalDomain;
  cacheUrl = "https://cache.${externalDomain}";
in
{
  # NOTE: Since nix-darwin is disabled for Determinate Nix, these settings
  # should be added manually to /etc/nix/nix.custom.conf on Darwin machines
  # For reference, the required configuration would be:
  #
  # extra-trusted-substituters = ${cacheUrl}
  # extra-trusted-public-keys = bee:/9R3r9DsSErFv0A1yBIzgaF1XCcF7XmKJBSrPE+axp0=
  
  # For NixOS systems, this would work directly:
  # nix.settings = {
  #   trusted-substituters = [ cacheUrl ];
  #   trusted-public-keys = [
  #     "bee:REPLACE_WITH_ACTUAL_PUBLIC_KEY_CONTENT"
  #   ];
  # };
}