# TODO:
# - dependencies/ordering for uci-defaults stuff
{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatMapStringsSep
    literalExpression
    mkOption
    types
    ;

  profiles = inputs.openwrt-imagebuilder.lib.profiles { inherit pkgs; };
in
{
  imports = [
    ./files.nix
    ./system.nix
  ];

  options = {
    # High-level options
    release = mkOption {
      type = types.str;
      description = ''
        The OpenWRT release to build.
      '';
      example = "22.03.5";
    };
    profile = mkOption {
      type = types.str;
      description = ''
        Target machine profile to build the image for.
      '';
      example = "netgear_dm200";
    };
    extraPackages = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = ''
        List of additional opkg packages to include in the image.
      '';
    };
    removePackages = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = ''
        List of opkg packages to remove from the image.
      '';
    };
    disabledServices = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = ''
        List of /etc/init.d services to disable.
      '';
    };
    extraImageName = mkOption {
      type = types.str;
      default = "nix";
      description = ''
        String to add to output image file name.
      '';
    };
    pkgs = mkOption {
      type = types.pkgs;
      default = pkgs;
      description = ''
        The nixpkgs package set used to run the image builder.
      '';
    };

    # Mid-level options, should mostly not be needed in normal use, but employed by modules
    fileTrees = mkOption {
      type = with types; listOf path;
      default = [ ];
      description = ''
        List of paths to trees of additional files to include in the image.
        Prefer using the `files` option unless you really just have a local
        tree of files to merge into the image's root.
      '';
    };
    # TODO: Add default stuff to lib passed in, instead?
    lib = lib.mkOption {
      default = { };
      type = lib.types.attrs;
      description = ''
        This option allows modules to define helper functions, constants, etc.
      '';
    };
    finalImage = mkOption {
      type = types.package;
      description = ''
        The output OpenWRT images.
      '';
      readOnly = true;
      internal = true;
    };

    # Low-level internal option representing final arguments passed to openwrt-imagebuilder # {{{
    finalImageBuildConfig = mkOption {
      type = types.submodule ({
        options = {
          pkgs = mkOption {
            type = types.pkgs;
            description = ''
              The nixpkgs package set used to run the image builder.
            '';
            readOnly = true;
            internal = true;
            visible = false;
          };
          release = mkOption {
            type = types.str;
            description = ''
              The OpenWRT release to build.
            '';
            example = "22.03.5";
            readOnly = true;
            internal = true;
            visible = false;
          };
          packages = mkOption {
            type = with types; listOf str;
            description = ''
              List of packages to add to the built image (or remove, for
              packages prefixed with -).
            '';
            readOnly = true;
            internal = true;
            visible = false;
          };
          files = mkOption {
            type = types.path;
            description = ''
              Path to a tree of additional files to include in the image.
            '';
            readOnly = true;
            internal = true;
            visible = false;
          };
          disabledServices = mkOption {
            type = with types; listOf str;
            description = ''
              List of /etc/init.d services to disable.
            '';
            readOnly = true;
            internal = true;
            visible = false;
          };
          extraImageName = mkOption {
            type = types.str;
            description = ''
              String to add to output image file name.
            '';
            readOnly = true;
            internal = true;
            visible = false;
          };

          target = mkOption {
            type = types.str;
            readOnly = true;
            internal = true;
            visible = false;
          };
          variant = mkOption {
            type = types.str;
            readOnly = true;
            internal = true;
            visible = false;
          };
          profile = mkOption {
            type = types.str;
            readOnly = true;
            internal = true;
            visible = false;
          };

          # packagesArch = mkOption {
          #   type = types.str;
          #   readOnly = true;
          #   internal = true;
          #   visible = false;
          # };
          # sha256 = mkOption {
          #   type = types.str;
          #   readOnly = true;
          #   internal = true;
          #   visible = false;
          # };
          # feedsSha256 = mkOption {
          #   type = types.str;
          #   readOnly = true;
          #   internal = true;
          #   visible = false;
          # };
        };
      });
      description = ''
        Final attribute set of arguments to pass to openwrt-imagebuilder.lib.build.
      '';
    };
    # }}}
  };

  config = {
    # Build the image
    finalImage = inputs.openwrt-imagebuilder.lib.build config.finalImageBuildConfig;
    finalImageBuildConfig = profiles.identifyProfile config.profile // {
      inherit (config)
        disabledServices
        extraImageName
        pkgs
        release
        ;
      packages =
        (config.extraPackages or [ ])
        ++ (map (pkg: "-${pkg}") (config.removePackages or [ ]))
        # NOTE: Currently we're dependent on luajit for setup-scripting
        # purposes, in future ucode would be a better alternative but it
        # doesn't seem viable right now, too immature.
        ++ [ "luajit" ];
      files =
        pkgs.runCommandLocal "image-files"
          {
            nativeBuildInputs = [
              pkgs.rsync
            ];
          }
          ''
            mkdir -p $out
            ${concatMapStringsSep "\n" (fileTree: ''
              rsync --no-inc-recursive -rvhp ${fileTree}/ $out/
            '') config.fileTrees}
          '';
    };

    # Some default files to include
    files."/lib/functions/guard.sh".source = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/freifunk-berlin/firmware-packages/5184f2dce5ab85b22a69dc36e09f1d8c7e36ca0b/addons/freifunk-berlin-lib-guard/root/lib/functions/guard.sh";
      sha256 = "017d57fahsvsn038nqc259mq21xsry06ypzhkq3m3126plmpcc29";
    };

    # Default library
    lib = {
      compileMoonBin =
        name: moonScript:
        pkgs.runCommandNoCCLocal "moon-bin-${name}"
          {
            inherit name;
            src = moonScript;
            nativeBuildInputs = [
              (pkgs.luajit.withPackages (p: with p; [ moonscript ]))
            ];
          }
          ''
            echo "#!/usr/bin/env luajit" > $out
            moonc -p "$src" >> $out
            chmod +x $out
          '';
      writeUCIScript =
        name: text:
        pkgs.writeTextFile {
          inherit name text;
          executable = true;
          checkPhase = ''
            runHook preCheck
            # use shellcheck which does not include docs
            ${lib.getExe (pkgs.haskell.lib.compose.justStaticExecutables pkgs.shellcheck.unwrapped)} "$target"
            runHook postCheck
          '';
        };
    };
  };
}
