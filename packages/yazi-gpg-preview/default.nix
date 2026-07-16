{ pkgs }:

# Decrypts a gpg/pgp/asc-encrypted file and pipes the plaintext through bat
# for syntax highlighting. Used as a yazi previewer via piper.yazi (see
# home/yazi.nix).
#
# bat can't infer a language from piped stdin, so we pass --file-name with
# the .gpg/.pgp/.asc suffix stripped (falling back to .txt when nothing is
# left) so it picks up the inner extension instead.
pkgs.writeShellScript "yazi-gpg-preview" ''
  file_path="$1"
  inner_name="''${file_path%.*}"
  base_noext="''${inner_name##*/}"
  if [[ "''${base_noext}" != *.* ]]; then
    inner_name="''${inner_name}.txt"
  fi
  ${pkgs.gnupg}/bin/gpg --batch --quiet --decrypt -- "''${file_path}" 2>/dev/null | \
    ${pkgs.bat}/bin/bat --color=always --style=plain --paging=never --file-name "''${inner_name}" -- 2>/dev/null
''
