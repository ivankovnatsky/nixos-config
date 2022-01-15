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
            ./system/bluetooth.nix
            ./system/boot.nix
            ./system/chromium.nix
            ./system/documentation.nix
            ./system/fonts.nix
            ./system/networking.nix
            ./system/nextdns.nix
            ./system/opengl.nix
            ./system/packages.nix
            ./system/pipewire.nix
            ./system/security.nix
            ./system/services.nix
            ./system/users.nix
            ./system/xdg.nix

            ./modules/default.nix
            ./modules/secrets.nix
          ];

          environment = {
            variables = {
              AWS_VAULT_BACKEND = "pass";
              EDITOR = editorName;
              LPASS_AGENT_TIMEOUT = "0";
              VISUAL = editorName;
            };
          };

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

          nixpkgs.config.allowUnfree = true;

          nix = {
            package = pkgs.nixUnstable;
            extraOptions = ''
              experimental-features = nix-command flakes
            '';
          };
        })
      ];

      waylandModule = [
        ({
          imports = [
            ./system/greetd.nix
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
            # xorgModule ++
            waylandModule ++
            [
              ({ ... }: {
                imports = [
                  ./hosts/thinkpad
                ];

                nixpkgs.overlays = [
                  inputs.self.overlay
                  inputs.nur.overlay
                ];

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
                      ./home/gh.nix
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
                    variables = super.variables;
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

        xps = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules =
            commonModule ++
            waylandModule ++
            [
              ({ ... }: {
                imports = [
                  ./hosts/xps
                ];

                nixpkgs.overlays = [
                  inputs.self.overlay
                  inputs.nur.overlay
                ];
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
                      ./home/gh.nix
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

                      ./modules/default.nix
                      ./modules/secrets.nix
                    ];

                    home.stateVersion = "21.11";

                    device = super.device;
                    variables = super.variables;
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
