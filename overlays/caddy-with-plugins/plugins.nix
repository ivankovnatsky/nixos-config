# callPackage args
{
  lib,
  stdenv,
  go,
  xcaddy,
  cacert,
  git,
  caddy-with-plugins,
}:

let
  inherit (builtins) hashString;
  inherit (lib)
    assertMsg
    concatMapStrings
    elemAt
    fakeHash
    filter
    hasInfix
    length
    lessThan
    sort
    toShellVar
    ;
in

# pkgs.caddy.withPlugins args
{
  plugins,
  hash ? fakeHash,
}:

let
  pluginsSorted = sort lessThan plugins;
  pluginsList = concatMapStrings (plugin: "${plugin}-") pluginsSorted;
  pluginsHash = hashString "md5" pluginsList;
  pluginsWithoutVersion = filter (p: !hasInfix "@" p) pluginsSorted;
in

# eval barrier: user provided plugins must have tags
# the go module must either be tagged in upstream repo
# or user must provide commit sha or a pseudo-version number
# https://go.dev/doc/modules/version-numbers#pseudo-version-number
assert assertMsg (
  length pluginsWithoutVersion == 0
) "Plugins must have tags present (e.g. ${elemAt pluginsWithoutVersion 0}@x.y.z)!";

caddy-with-plugins.overrideAttrs (
  finalAttrs: prevAttrs: {
    vendorHash = null;
    subPackages = [ "." ];

    src = stdenv.mkDerivation {
      pname = "caddy-src-with-plugins-${pluginsHash}";
      version = finalAttrs.version;

      nativeBuildInputs = [
        go
        xcaddy
        cacert
        git
      ];
      dontUnpack = true;
      buildPhase =
        let
          withArgs = concatMapStrings (plugin: "--with ${plugin} ") pluginsSorted;
        in
        ''
          export GOCACHE=$TMPDIR/go-cache
          export GOPATH="$TMPDIR/go"
          XCADDY_SKIP_BUILD=1 TMPDIR="$PWD" xcaddy build v${finalAttrs.version} ${withArgs}
          (cd buildenv* && go mod vendor)
        '';
      installPhase = ''
        mv buildenv* $out
      '';

      outputHashMode = "recursive";
      outputHash = hash;
      outputHashAlgo = "sha256";
    };

    # xcaddy built output always uses pseudo-version number
    # we enforce user provided plugins are present and have matching tags here
    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck

      ${toShellVar "notfound" pluginsSorted}

      while read kind module version; do
        [[ "$kind" = "dep" ]] || continue
        module="''${module}@''${version}"
        for i in "''${!notfound[@]}"; do
          original_plugin="''${notfound[i]}"
          base="''${original_plugin%@*}"
          specified="''${original_plugin#*@}"
          
          # Check for exact match
          if [[ ''${original_plugin} = ''${module} ]]; then
            unset 'notfound[i]'
            continue
          fi
          
          # Check if it's a commit hash that got converted to a pseudo-version
          # Pseudo-versions end with the first 12 chars of the commit hash
          if [[ "$module" = "$base@"* && "$version" = *"-"* ]]; then
            commit_hash_part="''${version##*-}"
            # If the specified version is a long commit hash and the version includes its prefix
            if [[ ''${#specified} -ge 12 && ''${specified:0:12} = ''${commit_hash_part:0:12} ]]; then
              unset 'notfound[i]'
              continue
            fi
          fi
        done
      done < <($out/bin/caddy build-info)

      if (( ''${#notfound[@]} )); then
        for plugin in "''${notfound[@]}"; do
          base=''${plugin%@*}
          specified=''${plugin#*@}
          found=0

          while read kind module expected; do
            [[ "$kind" = "dep" && "$module" = "$base" ]] || continue
            echo "Plugin \"$base\" have incorrect tag:"
            echo "  specified: \"$base@$specified\""
            echo "  got: \"$base@$expected\""
            found=1
          done < <($out/bin/caddy build-info)

          if (( found == 0 )); then
            echo "Plugin \"$base\" not found in build:"
            echo "  specified: \"$base@$specified\""
            echo "  plugin does not exist in the xcaddy build output, open an issue in nixpkgs or upstream"
          fi
        done

        exit 1
      fi

      runHook postInstallCheck
    '';
  }
)
