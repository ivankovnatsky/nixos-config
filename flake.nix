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
              EDITOR = editorName;
              VISUAL = editorName;
              LPASS_AGENT_TIMEOUT = "0";
              AWS_VAULT_BACKEND = "pass";
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

            ./modules/device.nix
          ];

          i18n.defaultLocale = "en_US.UTF-8";
          time.timeZone = "Europe/Uzhgorod";
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
        })
      ];

      xorgModule = [
        ({
          imports = [
            ./system/i3.nix
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
                      ./home/task.nix
                      ./home/tmux.nix
                      ./home/zsh.nix

                      # ./home/sway.nix
                      # ./home/mako.nix

                      ./home/autorandr.nix
                      ./home/dunst.nix
                      ./home/i3.nix
                      ./home/xsession.nix

                      ./modules/device.nix
                    ];

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

                      ./home/dunst.nix
                      ./home/i3.nix
                      ./home/xsession.nix

                      ./modules/device.nix
                    ];

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

        xps = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules =
            commonModule ++
            linuxModule ++
            waylandModule ++
            [
              ({ config, lib, pkgs, options, ... }: {
                imports = [
                  ./hosts/xps/boot.nix
                  ./hosts/xps/hardware-configuration.nix

                  ./system/opengl-intel.nix
                  ./system/upowerd.nix
                ];

                networking.hostName = "xps";

                hardware = {
                  enableAllFirmware = true;
                  enableRedistributableFirmware = true;
                  firmware = with pkgs; [ firmwareLinuxNonfree ];

                  cpu.intel.updateMicrocode = true;
                };

                device = {
                  name = "xps";
                  monitorName = "DP-3";
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

                      ./home/sway.nix
                      ./home/mako.nix

                      ./modules/device.nix
                    ];

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
                    ./system/darwin.nix
                    ./system/homebrew.nix

                    ./modules/darwin/security/pam.nix
                  ];

                  homebrew.taps = [
                    "fabianishere/personal"
                  ];

                  homebrew.brews = [
                    "pam_reattach"
                    "awscli"
                  ];

                  homebrew.casks = [
                    "aws-vpn-client"
                  ];

                  nixpkgs.overlays = [
                    inputs.self.overlay
                  ];

                  security.pam.enableSudoTouchIdAuth = true;
                }
              )

              inputs.home-manager.darwinModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.ivan = {
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
                };
              }
            ];
        };
      };

      overlay = final: prev: {
        rbw = final.callPackage ./system/overlays/rbw.nix {
          withFzf = true;
          withGitCredential = true;
          inherit (inputs.nixpkgs.pkgs.darwin.apple_sdk.frameworks) Security;
        };

        inherit (final.callPackages system/overlays/openvpn.nix { })
          openvpn;
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
