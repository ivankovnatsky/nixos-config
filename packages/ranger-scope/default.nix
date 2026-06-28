{ pkgs }:

# ranger's preview dispatcher.
#
# nixpkgs ships scope.sh inside the ranger package (and points preview_script
# at it). We reuse that bundled copy — so it tracks the exact ranger version
# the overlay provides and inherits any nixpkgs patches (e.g. highlight path) —
# and only uncomment the video/*) block, so video files render as thumbnails
# (via ffmpegthumbnailer) instead of falling through to mediainfo/exiftool text.
#
# Referenced by home/ranger.nix as ${pkgs.ranger-scope}/scope.sh.
pkgs.runCommand "ranger-scope" { } ''
  mkdir -p $out
  # Uncomment the video/*) case: within the block delimited by the "## Video"
  # header and the following blank line, strip the leading "# " comment marker.
  # The "## Video" header ("##") and the blank line do not match "# " and are
  # left untouched.
  ${pkgs.gnused}/bin/sed -E '
    /^[[:space:]]*## Video$/,/^$/ s/^([[:space:]]*)# /\1/
  ' ${pkgs.ranger}/share/doc/ranger/config/scope.sh > $out/scope.sh
  chmod 0755 $out/scope.sh

  # Guard against an upstream rewrite silently producing a no-op patch.
  grep -qE '^[[:space:]]*video/\*\)' $out/scope.sh
''
