{ pkgs, ... }:

let
  # https://lazamar.co.uk/nix-versions/?package=terraform&version=1.9.8&fullName=terraform-1.9.8&keyName=terraform&revision=882842d2a908700540d206baa79efb922ac1c33d&channel=nixpkgs-unstable#instructions
  # https://lazamar.co.uk/nix-versions/?package=terragrunt&version=0.68.7&fullName=terragrunt-0.68.7&keyName=terragrunt&revision=882842d2a908700540d206baa79efb922ac1c33d&channel=nixpkgs-unstable#instructions
  pinnedPkgs =
    import
      (builtins.fetchGit {
        # Descriptive name to make the store path easier to identify
        name = "tf-1.9.8-tg-0.68.7";
        url = "https://github.com/NixOS/nixpkgs/";
        ref = "refs/heads/nixpkgs-unstable";
        rev = "882842d2a908700540d206baa79efb922ac1c33d";
      })
      {
        system = pkgs.system;
        config = {
          allowUnfree = true;
          allowUnfreePredicate = _: true;
        };
      };
in
{
  home = {
    packages = [
      # Manage terraform versions
      # https://github.com/tofuutils/tenv/issues/121
      #
      # ```console
      # Failure during terragrunt call : fork/exec /etc/profiles/per-user/Ivan.Kovnatskyi/bin/tenv: operation not supported by device
      # ```
      # pkgs.tenv
      # pkgs.terraform
      # pkgs.terragrunt
      pkgs.tflint
      pinnedPkgs.terraform
      pinnedPkgs.terragrunt
    ];
    file = {
      ".terraform.d/plugin-cache/.keep" = {
        text = ''
          keep
        '';
      };
      ".terraformrc" = {
        # https://developer.hashicorp.com/terraform/cli/config/config-file
        text = ''
          plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
          plugin_cache_may_break_dependency_lock_file = true
          disable_checkpoint = true
        '';
      };
    };
  };
}
