# hetzner-install

Hetzner remote dedicated server.

## Automation

Use this
[script](https://raw.githubusercontent.com/ivankovnatsky/nixos-install-scripts/5aae4e42a4749edf49f42a5aa360eca7290f422f/hosters/hetzner-dedicated/hetzner-dedicated-wipe-and-install-nixos.sh)
to bootstrap NixOS on hetzner dedicated, unencrypted.

Mostly copied over here: <https://github.com/serokell/nixos-install-scripts/pull/1>.

## New Machine setup

1. Copy hardware-configuration.nix from newly created machine
1. Copy configuration.nix from newly created machine
1. Adapt to variables

## Security

1. Set password for root
1. Set password for local user
1. Configure ssh key for local user
1. Remove ssh key from root
1. Set firewall rules using ansible playbook
