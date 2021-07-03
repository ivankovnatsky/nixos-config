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

      commonModule = [
        ({ pkgs, ... }: {
          environment = {
            variables = {
              EDITOR = editorName;
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

          modules = commonModule ++ [
            ({ config, lib, pkgs, options, ... }: {
              imports = [
                ./hosts/thinkpad/boot.nix
                ./hosts/thinkpad/hardware-configuration.nix

                ./system/bluetooth.nix
                ./system/general.nix
                ./system/greetd.nix
                ./system/packages.nix
                ./system/packages-linux.nix
                ./system/programs.nix
                ./system/services.nix
                ./system/tlp.nix
                ./system/upowerd.nix
              ];

              networking.hostName = "thinkpad";

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

                (import ./system/overlays/linux)
              ];

              nix.autoOptimiseStore = true;

              system.stateVersion = "21.03";
            })

            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.ivan = {
                imports = [
                  ./home/general.nix

                  ./home/neovim/default.nix

                  ./home/alacritty.nix
                  ./home/bat.nix
                  ./home/dotfiles.nix
                  ./home/firefox.nix
                  ./home/git.nix
                  ./home/gtk.nix
                  ./home/i3status.nix
                  ./home/mpv.nix
                  ./home/password-store.nix
                  ./home/task.nix
                  ./home/tmux.nix
                  ./home/zsh.nix

                  ./home/sway.nix
                  ./home/mako.nix
                ];
              };
            }
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
              ./hosts/macbook

              inputs.home-manager.darwinModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.ivan = import ./hosts/macbook/home.nix;
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

                    (import ./system/overlays/darwin)
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
        mkShell {
          buildInputs = [
          ];
        };

    };
}
