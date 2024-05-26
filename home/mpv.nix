{ pkgs, ... }:

{
  home.packages = with pkgs; [
    mpv
  ];

  home.file.".config/mpv/config".text = ''
    # Do not show video window when playing audio
    no-audio-display
    alang=eng
    force-seekable=yes
    audio-channels=2

    fs=no
    osc=no
    osd-level=1  # Default osd-level when not seeking
    # When viewing images
    image-display-duration=5
    ytdl-format="bestvideo[height<=1080]+bestaudio/best"
    keepaspect-window=no
    autofit-larger=100%x100%

    save-position-on-quit=yes
    slang=eng
    sub-scale=0.5
  '';

  home.file.".config/mpv/scripts/osd-during-seek.lua".text = ''
    local osd_timer = nil

    mp.observe_property("seeking", "bool", function(name, value)
        if value then
            -- When seeking, set osd-level to 3
            mp.set_property("osd-level", 3)
            -- Reset and disable any existing timer
            if osd_timer then
                osd_timer:kill()
                osd_timer = nil
            end
        else
            -- Start or restart a timer to revert osd-level after 2 seconds
            if osd_timer then
                osd_timer:resume()
            else
                osd_timer = mp.add_timeout(1, function()
                    mp.set_property("osd-level", 1)
                end)
            end
        end
    end)
  '';
}
