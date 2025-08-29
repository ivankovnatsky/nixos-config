{ config, lib, ... }:

# To get the public key for the cache server, run on the bee machine after deployment:
# cat /var/lib/nix-serve/cache-pub-key.pem

let
  inherit (config.secrets) externalDomain;
  cacheUrl = "https://cache.${externalDomain}";
in
{
  nix.settings = {
    # Add the local cache server as a trusted substituter
    trusted-substituters = [ cacheUrl ];
    
    # Public key for cache verification
    trusted-public-keys = [
      "bee:/9R3r9DsSErFv0A1yBIzgaF1XCcF7XmKJBSrPE+axp0="
    ];
    
    # Prefer local cache over remote caches for better performance
    substituters = lib.mkBefore [ cacheUrl ];
  };
}