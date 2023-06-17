{ config, lib, pkgs, ... }:
with lib;
let
  pins = import ./sources { };

  mods = [
    (modFromGitSubDir "CDDA-Arcana" pins.cdda-arcana-mod "Arcana")
    (modFromGitSubDir "CDDA-Croppable-Rice" pins.CBN-Rice-Mod "Croppable_Rice")
    (modFromGitSubDir "CDDA-Dorf-Life" pins.Dorf-Life-CDDA "Dorf_Life")
    # (modFromGitSubDir "CDDA-BL9" pins.BL9 "BL9-100%_monster_resilience_version")
    (modFromGitSubDir "CDDA-Fewer-Farms" pins.cdda-fewer-farms-mod "Fewer_Farms")
    # (modFromGitSubDir "CDDA-Maps-HostileArchitecture" pins.CDDA-Maps-HostileArchitecture "data/mods/Hostile_Architecture")
    (modFromGitSubDir "CDDA-MST-Extra" pins.MST_Extra_Mod "MST_Extra")
    (modFromGitSubDir "CDDA-Medieval-Mod-Reborn" pins.cdda_medieval_mod_reborn "Medieval_Mod_Reborn")
    (modFromGitSubDir "CDDA-Nocts-Cata-Mod" pins.nocts_cata_mod "nocts_cata_mod_DDA")
    (modFromGitSubDir "CDDA-Nonperishable-Overhaul" pins.CDDA_Nonperishable_Overhaul "Nonperishable_Overhaul")
    (modFromGitDir "CDDA-PrepperCache" pins.PrepperCache "PrepperCache")
    (modFromGitSubDir "CDDA-Stamina-Regen-Buff" pins.cdda-stamina-regen-buff "stamina_regen_buff")
    (modFromGitSubDir "CDDA-Tankmod-Revived" pins.cdda-tankmod-revived-mod "Tankmod_Revived")
    (modFromGitSubDir "CDDA-Useful-Helicopters" pins.useful_helicopters "Useful_Helicopters_experimental")
    (modFromGitSubDir "CDDA-Learnable-Helicopters" pins.Learnable_Helicopters "Learnable_Helicopters")
  ]
  ++ (modsFromSubDirs "CDDA-Arcana" pins.cdda-arcana-mod.rev (pins.cdda-arcana-mod.outPath + "/Patchmods")
       (path: hasPrefix "DDA_" path))
  ++ zipMods;

  zipMods = flip map zipModFilesList (path: modFromZip (./sources + "/${path}"));
  zipModFilesList = mapAttrsToList (n: v: n) zipModFiles;
  zipModFiles = filterAttrs (n: v: v == "regular" && hasSuffix ".zip" n) (builtins.readDir ./sources);
  modFromZip = zipPath: let
    name = removeSuffix ".zip" (last (splitString "/" zipPath));
  in pkgs.runCommandNoCCLocal name {
    src = zipPath;
    nativeBuildInputs = with pkgs; [
      unzip
    ];
  } ''
    unzip "$src"
    moddir="$out/share/cataclysm-dda/mods/"
    mkdir -p "$moddir"
    for dir in ./*; do
      mv "$dir" "$moddir"/"$(echo "$dir" | tr -d _)"
    done
  '';

  modFromGitSubDir = pname: gitSrc: subdir: pkgs.stdenv.mkDerivation {
    inherit pname;
    version = "unstable-${gitSrc.rev}";
    src = gitSrc.outPath;
    installPhase = ''
      moddir="$out/share/cataclysm-dda/mods/"
      mkdir -p "$moddir"
      cp -r ${subdir} "$moddir"/
    '';
  };

  modFromGitDir = pname: gitSrc: outdir: pkgs.stdenv.mkDerivation {
    inherit pname;
    version = "unstable-${gitSrc.rev}";
    src = gitSrc.outPath;
    installPhase = ''
      moddir="$out/share/cataclysm-dda/mods/${outdir}"
      mkdir -p "$moddir"
      cp -r * "$moddir"/
    '';
  };

  modsFromSubDirs = basename: version: path: filterFn: let
    mods = map (subdir: modFromSubDir basename version (path + "/${subdir}")) filteredDirs;
    filteredDirs = filter filterFn modDirs;
    modDirs = mapAttrsToList (n: v: n) (builtins.readDir path);
  in mods;

  modFromSubDir = basename: version: path: let
    dirName = last (splitString "/" path);
  in pkgs.stdenv.mkDerivation {
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
      # cataclysm-dda-git = (super.cataclysm-dda-git.A rec {
      #   version = "2022-06-20-2312";
      #   rev = "cdda-experimental-${version}";
      #   sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      # }).withMods mods;
      cataclysm-dda-git = let
        inherit (super.cataclysmDDA) attachPkgs pkgs;
      in (attachPkgs pkgs (super.cataclysm-dda-git.overrideAttrs (oa: rec {
        pname = oa.pname + "-git";
        version = "local";

        patches = [];

        src = /mnt/thedreamscape/home/shados/technotheca/media/software/source/Cataclysm-DDA;

        dontStrip = true;
        makeFlags = oa.makeFlags ++ [
          "VERSION=git-${version}"
          # "BACKTRACE=1"
          "DEBUG_SYMBOLS=1"
          "STRING_ID_DEBUG=1"
        ];
      }))).withMods mods;
    })
  ];
}
