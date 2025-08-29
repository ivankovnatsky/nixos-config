# Not sure why or do not recall now, but I don't have a /etc/nix/nix.conf file
# on my system. Normally determinate nix should create it. But let's add it
# manully for now. Because rinning:
#
# ```console
# /nix/nix-installer plan --out-file /tmp/nix-determinate-install.plan
# /nix/nix-installer install /tmp/nix-determinate-install.plan
# ```
#
# is quite tricky.
#
# https://docs.determinate.systems/determinate-nix/#determinate-nix-configuration says:
#
# ```
# For the most part, Determinate Nix handles configuration for you. In fact,
# one of the core virtues of Determinate Nix is that it enables you to
# confidently use Nix while making fewer decisions about it—including decisions
# about configuration. When you install Determinate Nix, the installer writes a
# nix.conf configuration file to /etc/nix/nix.conf with carefully chosen
# values.
#
# If you need to provide custom configuration beyond this, however, you can
# write that configuration to /etc/nix/nix.custom.conf.
#
# It’s important that you not change the generated values in /etc/nix/nix.conf.
# If you do need to supply custom configuration, nix.custom.conf is the only
# supported way to do so in Determinate Nix.
# ```

# Excerpt from the Determinate Nix installer JSON plan:
# "create_or_merge_nix_config": {
#   "action": {
#     "action_name": "create_or_merge_nix_config",
#     "path": "/etc/nix/nix.conf",
#     "pending_nix_config": {
#       "settings": {
#         "build-users-group": "nixbld",
#         "experimental-features": "nix-command flakes",
#         "always-allow-substitutes": "true",
#         "extra-trusted-substituters": "https://cache.flakehub.com",
#         "extra-trusted-public-keys": "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM= cache.flakehub.com-4:Asi8qIv291s0aYLyH6IOnr5Kf6+OF14WVjkE6t3xMio= cache.flakehub.com-5:zB96CRlL7tiPtzA9/WKyPkp3A2vqxqgdgyTVNGShPDU= cache.flakehub.com-6:W4EGFwAGgBj3he7c5fNh9NkOXw0PUVaxygCVKeuvaqU= cache.flakehub.com-7:mvxJ2DZVHn/kRxlIaxYNMuDG1OvMckZu32um1TadOR8= cache.flakehub.com-8:moO+OVS0mnTjBTcOUh2kYLQEd59ExzyoW1QgQ8XAARQ= cache.flakehub.com-9:wChaSeTI6TeCuV/Sg2513ZIM9i0qJaYsF+lZCXg0J6o= cache.flakehub.com-10:2GqeNlIp6AKp4EF2MVbE1kBOp9iBSyo0UPR9KoR0o1Y=",
#         "bash-prompt-prefix": "(nix:$name)\\040",
#         "max-jobs": "auto",
#         "extra-nix-path": "nixpkgs=flake:nixpkgs",
#         "upgrade-nix-store-path-url": "https://install.determinate.systems/nix-upgrade/stable/universal"
#       }
#     }
#   },
#   "state": "Uncompleted"
# }

{ config, ... }:

let
  inherit (config.secrets) externalDomain;
  localCacheUrl = "https://cache.${externalDomain}";
  localCacheKey = "bee:/9R3r9DsSErFv0A1yBIzgaF1XCcF7XmKJBSrPE+axp0=";
in
{
  environment.etc."nix/nix.conf".text = ''
    build-users-group = nixbld
    experimental-features = nix-command flakes
    always-allow-substitutes = true
    extra-trusted-substituters = https://cache.flakehub.com ${localCacheUrl}
    extra-trusted-public-keys = cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM= cache.flakehub.com-4:Asi8qIv291s0aYLyH6IOnr5Kf6+OF14WVjkE6t3xMio= cache.flakehub.com-5:zB96CRlL7tiPtzA9/WKyPkp3A2vqxqgdgyTVNGShPDU= cache.flakehub.com-6:W4EGFwAGgBj3he7c5fNh9NkOXw0PUVaxygCVKeuvaqU= cache.flakehub.com-7:mvxJ2DZVHn/kRxlIaxYNMuDG1OvMckZu32um1TadOR8= cache.flakehub.com-8:moO+OVS0mnTjBTcOUh2kYLQEd59ExzyoW1QgQ8XAARQ= cache.flakehub.com-9:wChaSeTI6TeCuV/Sg2513ZIM9i0qJaYsF+lZCXg0J6o= cache.flakehub.com-10:2GqeNlIp6AKp4EF2MVbE1kBOp9iBSyo0UPR9KoR0o1Y= ${localCacheKey}
    bash-prompt-prefix = (nix:$name)\040
    max-jobs = auto
    extra-nix-path = nixpkgs=flake:nixpkgs
    upgrade-nix-store-path-url = https://install.determinate.systems/nix-upgrade/stable/universal
  '';
}
