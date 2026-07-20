{ config, pkgs, ... }:

let
  commonSettings = {
    settings = (import ../../../../home/firefox.nix) // {
      "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    };

    userContent = ''
      @-moz-document domain("github.com") {
        :root {
          --fontStack-sansSerif: "Noto Sans", sans-serif !important;
          --fontStack-sansSerifDisplay: "Noto Sans", sans-serif !important;
          --fontStack-system: "Noto Sans", sans-serif !important;
        }

        *,
        *::before,
        *::after {
          font-family: "Noto Sans", sans-serif !important;
        }

        pre,
        pre *,
        code,
        code *,
        .blob-code,
        .blob-code *,
        .blob-code-content,
        .blob-code-content *,
        .blob-code-inner,
        .blob-code-inner *,
        .blob-code-marker,
        .blob-code-marker *,
        .react-blob-textarea,
        .react-blob-textarea *,
        .react-line-numbers,
        .react-line-numbers *,
        .react-code-text,
        .react-code-text * {
          font-family: "Hack Nerd Font", monospace !important;
        }
      }
    '';

    extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
      bitwarden
    ];
  };

  configPath = ".mozilla/firefox";
  configPathAbs = "${config.home.homeDirectory}/${configPath}";

in
{
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-devedition;
    inherit configPath;

    policies = {
      ExtensionSettings = {
        "selecttab@ivankovnatsky.net" = {
          installation_mode = "force_installed";
          install_url = "file://${configPathAbs}/dev-edition-default/extensions/selecttab@ivankovnatsky.net.xpi";
        };
      };
    };

    profiles = {
      "dev-edition-default" = commonSettings // {
        id = 0;
        isDefault = true;
        settings = commonSettings.settings // {
          # Disable extension signature requirement for unsigned extensions
          "xpinstall.signatures.required" = false;
        };
      };
      "default" = commonSettings // {
        id = 1;
      };
    };
  };

  home.file = {
    "${configPath}/dev-edition-default/extensions/selecttab@ivankovnatsky.net.xpi" = {
      source = "${pkgs.firefox-selecttab}/share/extensions/firefox-selecttab.zip";
    };
    "${configPath}/default/extensions/selecttab@ivankovnatsky.net.xpi" = {
      source = "${pkgs.firefox-selecttab}/share/extensions/firefox-selecttab.zip";
    };
  };
}
