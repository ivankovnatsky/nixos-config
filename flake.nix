{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    master.url = "github:nixos/nixpkgs/master";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";
  };

  outputs = inputs:
    let
      editorName = "nvim";
      timezone = builtins.readFile ./.secrets/personal/timezone;

      commonModule = [
        ({ pkgs, ... }: {
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
        ({ ... }: {
          i18n.defaultLocale = "en_US.UTF-8";
          time.timeZone = timezone;
          sound.enable = true;

          programs = {
            seahorse.enable = true;
            dconf.enable = true;
          };

          nix.autoOptimiseStore = true;
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
            [
              ({ config, lib, pkgs, options, ... }: {
                imports = [
                  ./hosts/thinkpad/boot.nix
                  ./hosts/thinkpad/hardware-configuration.nix

                  # ./system/bluetooth.nix
                  ./system/boot.nix
                  ./system/chromium.nix
                  ./system/documentation.nix
                  # ./system/fprintd.nix
                  ./system/greetd.nix
                  ./system/fonts.nix
                  # ./system/monitoring.nix
                  ./system/networking.nix
                  ./system/opengl.nix
                  ./system/packages.nix
                  ./system/packages-linux.nix
                  ./system/security.nix
                  ./system/services.nix
                  ./system/xdg.nix
                  ./system/tlp.nix
                  ./system/users.nix
                  ./system/upowerd.nix

                  ./modules/device.nix
                ];

                networking.hostName = "thinkpad";

                device = {
                  type = "laptop";
                  cpuTempPattern = "CPU";
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

                  (
                    self: super: {
                      inherit (super.callPackages system/overlays/openvpn.nix { })
                        openvpn;

                      awscurl = self.callPackage ./system/overlays/generic.nix {
                        name = "awscurl";
                        owner = "legal90";
                        repo = "awscurl";
                        version = "0.1.2";
                        platform = "linux_amd64";
                        sha256 = "sha256-DfH46NGZyqmK8dwOz6QQm/ctoMcrhj+Eu4OjZyyYVBM=";
                      };
                    }
                  )
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
                      ./home/neovim/default.nix
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
                      ./home/rbw.nix
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

        desktop = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules =
            commonModule ++
            linuxModule ++
            [
              ({ config, lib, pkgs, options, ... }: {
                imports = [
                  ./hosts/desktop/boot.nix
                  ./hosts/desktop/hardware-configuration.nix

                  ./system/boot.nix
                  ./system/chromium.nix
                  ./system/documentation.nix
                  ./system/greetd.nix
                  ./system/fonts.nix
                  ./system/networking.nix
                  ./system/opengl.nix
                  ./system/packages.nix
                  ./system/packages-linux.nix
                  ./system/security.nix
                  ./system/services.nix
                  ./system/xdg.nix
                  ./system/users.nix

                  ./modules/device.nix
                ];

                networking.hostName = "desktop";

                device = {
                  type = "desktop";
                };

                hardware = {
                  # don't install all that firmware:
                  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/hardware/all-firmware.nix
                  enableAllFirmware = false;
                  enableRedistributableFirmware = false;
                  firmware = with pkgs; [ firmwareLinuxNonfree ];

                  cpu.intel.updateMicrocode = true;
                };

                nixpkgs.overlays = [
                  inputs.self.overlay
                  inputs.nur.overlay

                  (
                    self: super: {
                      inherit (super.callPackages system/overlays/openvpn.nix { })
                        openvpn;

                      awscurl = self.callPackage ./system/overlays/generic.nix {
                        name = "awscurl";
                        owner = "legal90";
                        repo = "awscurl";
                        version = "0.1.2";
                        platform = "linux_amd64";
                        sha256 = "sha256-DfH46NGZyqmK8dwOz6QQm/ctoMcrhj+Eu4OjZyyYVBM=";
                      };
                    }
                  )
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
                      ./home/neovim/default.nix
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
                      ./home/rbw.nix
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

        xps = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules =
            commonModule ++
            linuxModule ++
            [
              ({ config, lib, pkgs, options, ... }: {
                imports = [
                  ./hosts/xps/boot.nix
                  ./hosts/xps/hardware-configuration.nix

                  ./system/boot.nix
                  ./system/chromium.nix
                  ./system/documentation.nix
                  ./system/greetd.nix
                  ./system/fonts.nix
                  ./system/networking.nix
                  ./system/opengl.nix
                  ./system/opengl-intel.nix
                  ./system/packages.nix
                  ./system/packages-linux.nix
                  ./system/security.nix
                  ./system/services.nix
                  ./system/xdg.nix
                  # ./system/tlp.nix
                  ./system/upowerd.nix
                  ./system/users.nix

                  ./modules/device.nix
                ];

                networking.hostName = "xps";

                device = {
                  type = "laptop";
                  monitorName = "DP-3";
                };

                hardware = {
                  enableAllFirmware = true;
                  enableRedistributableFirmware = true;

                  cpu.intel.updateMicrocode = true;
                };

                nixpkgs.overlays = [
                  inputs.self.overlay
                  inputs.nur.overlay

                  (
                    self: super: {
                      inherit (super.callPackages system/overlays/openvpn.nix { })
                        openvpn;

                      neovide = self.callPackage ./system/overlays/neovide { };

                      awscurl = self.callPackage ./system/overlays/generic.nix {
                        name = "awscurl";
                        owner = "legal90";
                        repo = "awscurl";
                        version = "0.1.2";
                        platform = "linux_amd64";
                        sha256 = "sha256-DfH46NGZyqmK8dwOz6QQm/ctoMcrhj+Eu4OjZyyYVBM=";
                      };
                    }
                  )
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
                      ./home/neovim/default.nix
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
                      ./home/rbw.nix
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
        "Ivans-MacBook-Pro" = inputs.darwin.lib.darwinSystem {
          modules =
            commonModule ++
            darwinModule ++
            [
              ({ config, lib, pkgs, options, ... }:
                {
                  imports = [
                    ../../system/darwin.nix
                    ../../system/homebrew.nix
                    ../../system/packages.nix
                  ];

                  homebrew.casks = [
                    "coconutbattery"
                  ];
                }
              )

              inputs.home-manager.darwinModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.ivan =
                  {
                    imports = [
                      ../../home/alacritty.nix
                      ../../home/bat.nix
                      ../../home/dotfiles.nix
                      ../../home/git.nix
                      ../../home/hammerspoon
                      ../../home/mpv.nix
                      ../../home/neovim
                      ../../home/password-store.nix
                      ../../home/task.nix
                      ../../home/tmux.nix
                      ../../home/zsh.nix
                    ];
                  };
              }
            ];
        };

        "workbook" = inputs.darwin.lib.darwinSystem {
          modules =
            commonModule ++
            darwinModule ++
            [
              ({ config, lib, pkgs, options, ... }:
                {
                  imports = [
                    ./system/darwin.nix
                    ./system/homebrew.nix
                    ./system/packages.nix

                    ./modules/darwin/security/pam.nix
                  ];

                  homebrew.taps = [
                    "fabianishere/personal"
                  ];

                  homebrew.brews = [
                    "pam_reattach"
                  ];

                  homebrew.casks = [
                    "aws-vpn-client"
                  ];

                  nixpkgs.overlays = [
                    inputs.self.overlay

                    (
                      self: super: {
                        inherit (super.callPackages system/overlays/openvpn.nix { })
                          openvpn;

                        awscurl = self.callPackage ./system/overlays/generic.nix {
                          name = "awscurl";
                          owner = "legal90";
                          repo = "awscurl";
                          version = "0.1.2";
                          platform = "linux_amd64";
                          sha256 = "sha256-DfH46NGZyqmK8dwOz6QQm/ctoMcrhj+Eu4OjZyyYVBM=";
                        };
                      }
                    )
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
        master = import inputs.master { system = final.system; config = final.config; };
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
