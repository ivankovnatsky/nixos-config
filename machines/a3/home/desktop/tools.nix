{ ... }:

{
  local.tools = {
    enable = true;

    settings = {
      npm.packages = {
        "@earendil-works/pi-coding-agent" = { };
        "@openai/codex" = { };
        "@bitwarden/cli" = { };
        "@steipete/summarize" = { };
      };

      uv.packages = {
        "yt-dlp" = { };
      };

      go.packages = { };

      curlShell = {
        "https://claude.ai/install.sh" = "bash";
      };

      mcp.servers = { };

      flatpak = {
        remotes.flathub = "https://dl.flathub.org/repo/flathub.flatpakrepo";
        packages = [ "com.bitwarden.desktop" ];
      };
    };
  };
}
