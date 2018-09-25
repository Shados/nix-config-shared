{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.sn.programs.flake8;
in
{
  options = {
    sn.programs.flake8 = {
      enable = mkEnableOption "installing flake8 with plugins.";
      plugins = mkOption {
        type = with types; listOf package;
        default = [];
        description = ''
          List of flake8 plugins to enable for the system-wide flake8
          installation.
        '';
      };
      package = mkOption {
        type = with types; package;
        default = pkgs.python36Packages.flake8;
        description = ''
          The base flake8 package to use.
        '';
      };
    };
  };

  config = mkIf cfg.enable (let
    unwrappedPythonPrograms = proglist: map(unwrapPythonProgram) proglist;
    unwrapPythonProgram = pp: pp.overridePythonAttrs { dontWrapPythonPrograms = true; };
    flake8-with-plugins = pkgs.symlinkJoin rec {
      name = "flake8-with-plugins-${cfg.package.version}";

      # Unwrap the python binaries so we can re-wrap them to $out later
      paths = unwrappedPythonPrograms([ cfg.package ] ++ cfg.plugins);

      buildInputs = with cfg.package.passthru.pythonModule.pkgs; [ wrapPython ];
      propagatedBuildInputs = paths;

      postBuild = ''
        # Manually add paths to $out/nix-support/propagated-build-inputs
        # (symlinkJoin is runCommand, which does not run the default fixupPhase)
        echo "Removing incorrect propagated-build-inputs symlink"
        rm -f $out/nix-support/propagated-build-inputs

        echo "Adding correct propagated build inputs"
        for dep in ${lib.concatStringsSep " " propagatedBuildInputs}; do
          echo "Adding $dep"
          echo -n "$dep " >> $out/nix-support/propagated-build-inputs
        done

        # Dereference binary symlink so wrapPythonPrograms will wrap them
        echo "Dereferencing binary symlinks"
        for f in $out/bin/*; do
          fname=$(basename $f)
          cp -L $f $fname
          rm -f $f
          cp $fname $f
        done

        echo "Wrapping python programs"
        wrapPythonPrograms
      '';
    };
  in {
    environment.systemPackages = [
      flake8-with-plugins
    ];
  });
}
