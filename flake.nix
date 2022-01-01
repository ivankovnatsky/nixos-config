{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";
  };

  outputs = inputs:
    let
      editorName = "nvim";

      commonModule = [
        ({ pkgs, ... }: {
          imports = [
            ./system/packages.nix
          ];

          environment = {
            variables = {
              AWS_VAULT_BACKEND = "pass";
              EDITOR = editorName;
              LPASS_AGENT_TIMEOUT = "0";
              VISUAL = editorName;
            };
          };

          nixpkgs.config.allowUnfree = true;

          nix = {
            package = pkgs.nixUnstable;
            extraOptions = ''
              experimental-features = nix-command flakes
            '';
          };
        })
      ];

      linuxModule = [
        ({ pkgs, ... }: {
          imports = [
            ./system/bluetooth.nix
            ./system/boot.nix
            ./system/chromium.nix
            ./system/documentation.nix
            ./system/fonts.nix
            ./system/networking.nix
            ./system/nextdns.nix
            ./system/opengl.nix
            ./system/packages-linux.nix
            ./system/security.nix
            ./system/services.nix
            ./system/users.nix
            ./system/xdg.nix

            ./modules/default.nix
            ./modules/secrets.nix
          ];

          i18n.defaultLocale = "en_US.UTF-8";
          time.timeZone = "Europe/Kiev";
          sound.enable = true;

          programs = {
            seahorse.enable = true;
            dconf.enable = true;
          };

          nix.autoOptimiseStore = true;

          services = {
            xserver = {
              deviceSection = ''
                Option "TearFree" "true"
              '';
            };
          };
        })
      ];

      waylandModule = [
        ({
          imports = [
            ./system/greetd.nix
            ./system/pipewire.nix
            ./system/swaylock.nix
            ./system/xdg-portal.nix
          ];

          nixpkgs.overlays = [
            (
              self: super: {
                firefox = super.firefox.override { forceWayland = true; };
              }
            )
          ];
        })
      ];

      xorgModule = [
        ({
          imports = [
            ./system/autorandr.nix
            ./system/i3.nix
            ./system/pipewire.nix
            ./system/xserver-hidpi.nix
            ./system/xserver.nix
          ];
        })
      ];

    in
    {
      nixosConfigurations = {
        thinkpad = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules =
            commonModule ++
            linuxModule ++
            # xorgModule ++
            waylandModule ++
            [
              ({ config, lib, pkgs, options, ... }: {
                imports = [
                  ./hosts/thinkpad/boot.nix
                  ./hosts/thinkpad/hardware-configuration.nix

                  ./system/tlp.nix
                  ./system/upowerd.nix

                  # ./system/xserver-laptop.nix
                ];

                networking.extraHosts = '''';

                networking.hostName = "thinkpad";

                # device = {
                #   graphicsEnv = "xorg";
                #   videoDriver = "amdgpu";
                # };

                hardware = {
                  # don't install all that firmware:
                  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/hardware/all-firmware.nix
                  enableAllFirmware = false;
                  enableRedistributableFirmware = false;
                  firmware = with pkgs; [ firmwareLinuxNonfree ];

                  cpu.amd.updateMicrocode = true;
                };

                nixpkgs.overlays = [
                  inputs.self.overlay
                  inputs.nur.overlay
                ];

                system.stateVersion = "21.03";
              })

              inputs.home-manager.nixosModules.home-manager
              ({ config, system, ... }: {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.ivan =
                  ({ super, ... }: {
                    imports = [
                      ./home/neovim
                      ./home/alacritty.nix
                      ./home/bat.nix
                      ./home/dotfiles.nix
                      ./home/firefox.nix
                      ./home/nightshift.nix
                      ./home/git.nix
                      ./home/gpg.nix
                      ./home/gtk.nix
                      ./home/i3status.nix
                      ./home/mpv.nix
                      ./home/password-store.nix
                      ./home/ranger.nix
                      ./home/task.nix
                      ./home/tmux.nix
                      ./home/zsh.nix

                      ./home/sway.nix

                      # ./home/autorandr.nix
                      # ./home/i3.nix
                      # ./home/xsession.nix

                      ./modules/default.nix
                      ./modules/secrets.nix
                    ];

                    home.stateVersion = config.system.stateVersion;

                    device = super.device;
                    global = super.global;
                    secrets = super.secrets;
                  });

                home-manager.extraSpecialArgs = {
                  inherit inputs system;
                  super = config;
                };
              })
            ];

          specialArgs = { inherit inputs; };
        };
      };

      overlay = final: prev: { };

      packages.x86_64-linux = (builtins.head (builtins.attrValues inputs.self.nixosConfigurations)).pkgs;

      devShell.x86_64-linux = with inputs.self.packages.x86_64-linux;
        mkShell
          {
            buildInputs = [
            ];
          };
    };
}
