{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  pins = import ./sources { };

  mods = [
    (modFromGitSubDir "CDDA-Arcana" pins.cdda-arcana-mod "Arcana")
    (modFromGitSubDir "CDDA-Croppable-Rice" pins.CBN-Rice-Mod "Croppable_Rice")
    (modFromGitSubDir "CDDA-Dorf-Life" pins.Dorf-Life-CDDA "Dorf_Life")
    # (modFromGitSubDir "CDDA-BL9" pins.BL9 "BL9-100%_monster_resilience_version")
    # (modFromGitSubDir "CDDA-Maps-HostileArchitecture" pins.CDDA-Maps-HostileArchitecture "data/mods/Hostile_Architecture")
    # (modFromGitSubDir "CDDA-MST-Extra" pins.MST_Extra_Mod "MST_Extra")
    # (modFromGitSubDir "CDDA-Medieval-Mod-Reborn" pins.cdda_medieval_mod_reborn "Medieval_Mod_Reborn")
    # (modFromGitSubDir "CDDA-Nocts-Cata-Mod" pins.nocts_cata_mod "nocts_cata_mod_DDA")
    # (modFromGitDir "CDDA-PrepperCache" pins.PrepperCache "PrepperCache")
    # (modFromGitSubDir "CDDA-Stamina-Regen-Buff" pins.cdda-stamina-regen-buff "stamina_regen_buff")
    # (modFromGitSubDir "CDDA-Tankmod-Revived" pins.cdda-tankmod-revived-mod "Tankmod_Revived")
    # (modFromGitSubDir "CDDA-Useful-Helicopters" pins.useful_helicopters
    #   "Useful_Helicopters_experimental"
    # )
    # (modFromGitSubDir "CDDA-Learnable-Helicopters" pins.Learnable_Helicopters "Learnable_Helicopters")
    (modFromGitDir "CDDA-StatsThroughSkills" pins.cdda-stats-through-skills "StatsThroughSkills")
  ]
  ++ (modsFromSubDirs "CDDA-Arcana" pins.cdda-arcana-mod.rev (
    pins.cdda-arcana-mod.outPath + "/Patchmods"
  ) (path: hasPrefix "DDA_" path))
  ++ zipMods;

  zipMods = flip map zipModFilesList (path: modFromZip (./sources + "/${path}"));
  zipModFilesList = mapAttrsToList (n: v: n) zipModFiles;
  zipModFiles = filterAttrs (n: v: v == "regular" && hasSuffix ".zip" n) (builtins.readDir ./sources);
  modFromZip =
    zipPath:
    let
      name = removeSuffix ".zip" (last (splitString "/" zipPath));
    in
    pkgs.runCommandLocal name
      {
        src = zipPath;
        nativeBuildInputs = with pkgs; [
          unzip
        ];
      }
      ''
        unzip "$src"
        moddir="$out/share/cataclysm-dda/mods/"
        mkdir -p "$moddir"
        for dir in ./*; do
          mv "$dir" "$moddir"/"$(echo "$dir" | tr -d _)"
        done
      '';

  modFromGitSubDir =
    pname: gitSrc: subdir:
    pkgs.stdenv.mkDerivation {
      inherit pname;
      version = "unstable-${gitSrc.rev}";
      src = gitSrc.outPath;
      installPhase = ''
        moddir="$out/share/cataclysm-dda/mods/"
        mkdir -p "$moddir"
        cp -r ${subdir} "$moddir"/
      '';
    };

  modFromGitDir =
    pname: gitSrc: outdir:
    pkgs.stdenv.mkDerivation {
      inherit pname;
      version = "unstable-${gitSrc.rev}";
      src = gitSrc.outPath;
      installPhase = ''
        moddir="$out/share/cataclysm-dda/mods/${outdir}"
        mkdir -p "$moddir"
        cp -r * "$moddir"/
      '';
    };

  modsFromSubDirs =
    basename: version: path: filterFn:
    let
      mods = map (subdir: modFromSubDir basename version (path + "/${subdir}")) filteredDirs;
      filteredDirs = filter filterFn modDirs;
      modDirs = mapAttrsToList (n: v: n) (builtins.readDir path);
    in
    mods;

  modFromSubDir =
    basename: version: path:
    let
      dirName = last (splitString "/" path);
    in
    pkgs.stdenv.mkDerivation {
      pname = "${basename}-${dirName}";
      inherit version;
      src = path;
      installPhase = ''
        moddir="$out/share/cataclysm-dda/mods/"
        mkdir -p "$moddir"
        cp -r "$src" "$moddir"/
      '';
    };
in
{
  nixpkgs.overlays = [
    (self: super: {
      cdda = self.cataclysm-dda-git.withMods [
        (modFromGitDir "CDDA-StatsThroughSkills" pins.cdda-stats-through-skills "StatsThroughSkills")
      ];
      cataclysm-dda-git =
        let
          # basePkg = super.cataclysm-dda;
          basePkg = super.cataclysm-dda-git.overrideAttrs (oa: rec {
            version = "0.I-2026-06-11-1250";
            src = super.fetchFromGitHub {
              owner = "Shados";
              repo = "Cataclysm-DDA";
              # branch shados-local-changes-experimental-2026-07-02-0353
              rev = "c8a178a8a94d31ad8565e9cf00a90090cda5253b";
              hash = "sha256-okB08k/9jSu345JEwCd7TL7wWG/vVVXc1/6ZJdI8/Cg=";
            };

            # TODO remove once upstream is using sdl3 build
            buildInputs = with super; [
              libx11
              sdl3
              sdl3-image
              sdl3-mixer
              sdl3-ttf
              freetype
              glslang
            ];
            makeFlags = oa.makeFlags ++ [
              "SDL3=1"
            ];
            nativeBuildInputs =
              oa.nativeBuildInputs or [ ]
              ++ (with super; [
                gettext
                (python3.withPackages (ps: with ps; [ pyvips ]))
              ]);

            postPatch = oa.postPatch or "" + ''
              substituteInPlace data/fontdata.json \
                --replace-fail 'data/font/' 'font/'
            '';

            # TODO remove once tilesets are integrated in upstream nixpkgs deriv
            tilesetSrc = super.fetchFromGitHub {
              owner = "I-am-Erk";
              repo = "CDDA-Tilesets";
              rev = "4e53fc3aeee85cfa6f2df7a58ebf04323460d629";
              hash = "sha256-noAzgecbHLRE71TZQmG8aC4IATjbyM+n7k3LWUs8usI=";
            };
            postInstall =
              let
                tilesets = {
                  Altica = {
                    dir = "Altica";
                    args = "--use-all --obsolete-fillers";
                  };
                  ASCII_Overmap = {
                    dir = "ASCII_Overmap";
                    args = "--use-all";
                  };
                  BrownLikeBears = {
                    dir = "BrownLikeBears";
                    args = "--use-all --obsolete-fillers";
                  };
                  ChibiUltica = {
                    dir = "Chibi_Ultica";
                    args = "--use-all";
                  };
                  HollowMoon = {
                    dir = "HollowMoon";
                    args = "--use-all --obsolete-fillers";
                  };
                  Larwick_Overmap = {
                    dir = "Larwick_Overmap";
                    args = "--use-all";
                  };
                  "MShockXotto+" = {
                    dir = "MShockXotto+";
                    args = "--use-all";
                  };
                  NeoDays = {
                    dir = "NeoDays";
                    args = "--use-all";
                  };
                  Retrodays = {
                    dir = "Retrodays";
                    args = "--use-all";
                  };
                  GiantDays = {
                    dir = "GiantDays";
                    args = "--use-all";
                  };
                  SmashButton_iso = {
                    dir = "HitButton_iso";
                    args = "--use-all";
                  };
                  SurveyorsMap = {
                    dir = "SurveyorsMap";
                    args = "--use-all";
                  };
                  UltimateCataclysm = {
                    dir = "UltimateCataclysm";
                    args = "--use-all --obsolete-fillers";
                  };
                  Ultica_iso = {
                    dir = "Ultica_iso";
                    args = "--use-all";
                  };
                  PenAndPaper = {
                    dir = "PenAndPaper";
                    args = "--use-all";
                  };
                };
              in
              oa.postInstall or ""
              + (lib.foldlAttrs (acc: name: value: ''
                export SOURCE="$tilesetSrc/gfx/${value.dir}"
                export DEST="$out/share/cataclysm-dda/gfx"
                python3 tools/gfx_tools/compose.py ${value.args} \
                  --feedback CONCISE \
                  --format-json \
                  --loglevel INFO \
                  "$SOURCE" "$DEST"

                cp "$SOURCE/tileset.txt" "$DEST/"
                if [[ -f "$SOURCE/fallback.png" ]]; then
                  cp "$SOURCE/fallback.png" "$DEST/"
                fi
                if [[ -f "$SOURCE/layering.json" ]]; then
                  cp "$SOURCE/layering.json" "$DEST/"
                fi
              '') "" tilesets);
          });
          overriddenPkg = basePkg.overrideAttrs (oa: {
            env.NIX_CFLAGS_COMPILE = oa.env.NIX_CFLAGS_COMPILE or "" + " -Wno-error=unused-parameter";
          });
        in
        super.cataclysmDDA.attachPkgs super.cataclysmDDA.pkgs overriddenPkg;
      # cataclysm-dda-git = let
      #   inherit (super.cataclysmDDA) attachPkgs pkgs;
      # in (attachPkgs pkgs (super.cataclysm-dda-git.overrideAttrs (oa: rec {
      #   pname = oa.pname + "-git";
      #   version = "local";

      #   patches = [];

      #   src = /mnt/thedreamscape/home/shados/technotheca/media/software/source/Cataclysm-DDA;

      #   dontStrip = true;
      #   makeFlags = oa.makeFlags ++ [
      #     "VERSION=git-${version}"
      #     # "BACKTRACE=1"
      #     "DEBUG_SYMBOLS=1"
      #     "STRING_ID_DEBUG=1"
      #   ];
      # }))).withMods mods;
    })
  ];
}
