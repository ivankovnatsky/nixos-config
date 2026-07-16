{ pkgs }:

# ranger's preview dispatcher.
#
# nixpkgs ships scope.sh inside the ranger package (and points preview_script
# at it). We reuse that bundled copy — so it tracks the exact ranger version
# the overlay provides and inherits any nixpkgs patches (e.g. highlight path) —
# and patch in two things:
#   - uncomment the video/*) block, so video files render as thumbnails
#     (via ffmpegthumbnailer) instead of falling through to mediainfo/exiftool text
#   - add a gpg|pgp|asc case that decrypts via gpg-agent (pinentry handles the
#     passphrase prompt since STDIN is disabled in preview scripts) and
#     previews the plaintext
#
# Referenced by home/ranger.nix as ${pkgs.ranger-scope}/scope.sh.
pkgs.runCommand "ranger-scope" { } ''
    mkdir -p $out

    cat > gpg-case.txt <<'CASE_EOF'
          ## GPG
          gpg|pgp|asc)
              ## Tell bat the decrypted-content's original name (extension
              ## before .gpg/.pgp/.asc stripped) so it can pick a language for
              ## syntax highlighting, since piped stdin has no filename of its
              ## own. Fall back to .txt when there's no inner extension.
              inner_name="''${FILE_PATH%.*}"
              base_noext="''${inner_name##*/}"
              if [[ "''${base_noext}" != *.* ]]; then
                  inner_name="''${inner_name}.txt"
              fi
              gpg --batch --quiet --decrypt -- "''${FILE_PATH}" 2>/dev/null | \
                env COLORTERM=8bit bat --color=always --style="''${BAT_STYLE}" --paging=never \
                    --file-name "''${inner_name}" -- 2>/dev/null && exit 5
              gpg --batch --quiet --decrypt -- "''${FILE_PATH}" && exit 5
              exit 1;;

  CASE_EOF

    # Uncomment the video/*) case: within the block delimited by the "## Video"
    # header and the following blank line, strip the leading "# " comment marker.
    # The "## Video" header ("##") and the blank line do not match "# " and are
    # left untouched.
    ${pkgs.gnused}/bin/sed -E '
      /^[[:space:]]*## Video$/,/^$/ s/^([[:space:]]*)# /\1/
    ' ${pkgs.ranger}/share/doc/ranger/config/scope.sh > scope-video.sh

    # Insert the gpg case before the "## BitTorrent" block in handle_extension().
    ${pkgs.gawk}/bin/awk -v inject=gpg-case.txt '
      /^[[:space:]]*## BitTorrent$/ { while ((getline line < inject) > 0) print line }
      { print }
    ' scope-video.sh > $out/scope.sh
    chmod 0755 $out/scope.sh

    # Guard against an upstream rewrite silently producing a no-op patch.
    grep -qE '^[[:space:]]*video/\*\)' $out/scope.sh
    grep -qE '^[[:space:]]*gpg\|pgp\|asc\)' $out/scope.sh
''
