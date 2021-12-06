{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

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
            ./system/opengl.nix
            ./system/packages-linux.nix
            ./system/security.nix
            ./system/services.nix
            ./system/users.nix
            ./system/xdg-mime.nix

            ./modules/device.nix
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
            ./system/xdg.nix
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
            ./system/i3.nix
            # ./system/dwm.nix
            ./system/packages-xserver.nix
            ./system/pulseaudio.nix
            ./system/xserver-hidpi.nix
            ./system/xserver.nix
          ];
        })
      ];

      darwinModule = [
        ({ pkgs, ... }: {
          environment.systemPackages = with pkgs; [
            gnupg
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
            xorgModule ++
            # waylandModule ++
            [
              ({ config, lib, pkgs, options, ... }: {
                imports = [
                  ./hosts/thinkpad/boot.nix
                  ./hosts/thinkpad/hardware-configuration.nix

                  ./system/tlp.nix
                  ./system/upowerd.nix

                  ./system/xserver-laptop.nix
                ];

                networking.hostName = "thinkpad";

                device = {
                  graphicsEnv = "xorg";
                  videoDriver = "amdgpu";
                };

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
                      ./home/gammastep.nix
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

                      # ./home/sway.nix

                      ./home/autorandr.nix
                      ./home/i3.nix
                      ./home/xsession.nix

                      ./modules/device.nix
                    ];

                    home.stateVersion = config.system.stateVersion;

                    device = super.device;
                  });

                home-manager.extraSpecialArgs = {
                  inherit inputs system;
                  super = config;
                };
              })
            ];

          specialArgs = { inherit inputs; };
        };

        desktop = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules =
            commonModule ++
            linuxModule ++
            xorgModule ++
            [
              ({ config, lib, pkgs, options, ... }: {
                imports = [
                  ./hosts/desktop/boot.nix
                  ./hosts/desktop/hardware-configuration.nix

                  ./system/opengl-intel.nix
                ];

                networking.hostName = "desktop";
                hardware.cpu.intel.updateMicrocode = true;

                device = {
                  type = "desktop";
                  graphicsEnv = "xorg";
                };

                nixpkgs.overlays = [
                  inputs.self.overlay
                  inputs.nur.overlay
                ];

                system.stateVersion = "21.11";
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
                      ./home/gammastep.nix
                      ./home/git.nix
                      ./home/gpg.nix
                      ./home/gtk.nix
                      ./home/i3status.nix
                      ./home/mpv.nix
                      ./home/password-store.nix
                      ./home/task.nix
                      ./home/tmux.nix
                      ./home/zsh.nix

                      ./home/i3.nix
                      ./home/xsession.nix

                      ./modules/device.nix
                    ];

                    home.stateVersion = config.system.stateVersion;

                    device = super.device;
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

      darwinConfigurations = {
        "workbook" = inputs.darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          modules =
            commonModule ++
            darwinModule ++
            [
              ({ config, lib, pkgs, options, ... }:
                {
                  imports = [
                    ./modules/darwin/security/pam.nix

                    ./hosts/workbook

                    ./system/darwin.nix
                    ./system/homebrew.nix
                  ];

                }
              )

              inputs.home-manager.darwinModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.ivan =
                  ({ config, ... }: {
                    imports = [
                      ./home/alacritty.nix
                      ./home/bat.nix
                      ./home/dotfiles.nix
                      ./home/git.nix
                      ./home/hammerspoon
                      ./home/mpv.nix
                      ./home/neovim
                      ./home/task.nix
                      ./home/tmux.nix
                      ./home/zsh.nix
                    ];

                    home.stateVersion = config.system.stateVersion;
                  });
              }
            ];
        };
      };

      overlay = final: prev: {
        inherit (final.callPackages ./overlays/openvpn.nix { })
          openvpn;

        kubecolor = final.callPackage ./overlays/kubecolor.nix { };
        kubectl-tree = final.callPackage ./overlays/kubectl-tree.nix { };
      };

      packages.x86_64-linux = (builtins.head (builtins.attrValues inputs.self.nixosConfigurations)).pkgs;

      devShell.x86_64-linux = with inputs.self.packages.x86_64-linux;
        mkShell
          {
            buildInputs = [
            ];
          };
    };
}
