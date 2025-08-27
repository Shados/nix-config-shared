final: prev: let
  inherit (prev) lib;
  inherit (prev.lib) getVersion versionAtLeast;
in {
  fop = if versionAtLeast (getVersion prev.fop) "2.10" then prev.fop else prev.callPackage ./fop.nix { };

  # FIXME: Remove once nixpkgs #177733 is resolved
  borgbackup = prev.borgbackup.overrideAttrs(finalAttrs: {
    postInstall = finalAttrs.postInstall or "" + ''
      mv $out/bin/borg $out/bin/.borg-real
      echo '#!${prev.stdenv.shell}' > "$out/bin/borg"

      cat << EOF >> "$out/bin/borg"
      realBorg="$out/bin/.borg-real"

      function borg(){
        local returnCode=0
        "\$realBorg" "\$@" || returnCode=\$?

        if [[ \$returnCode -eq 1 ]]; then
          return 0
        else
          return \$returnCode
        fi
      }

      borg "\$@"
      EOF

      chmod +x "$out/bin/borg"
    '';
  });
}
