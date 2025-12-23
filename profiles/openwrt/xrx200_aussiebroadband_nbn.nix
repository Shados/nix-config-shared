{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mapAttrs;
  inherit (config.lib) writeUCIScript;

  # TODO include guard.sh by default?
  uciScript = writeUCIScript "90_aussiebroadband_vdsl_baseline" ''
    #!/bin/sh
    # shellcheck disable=1091
    . /lib/functions/guard.sh

    guard "aussiebroadband_vdsl_baseline"

    # Configure the VDSL properties and firmware blob
    uci -q batch <<EOF
    set network.dsl.annex='b'
    set network.dsl.tone='bv'
    set network.dsl.xfer_mode='ptm'
    set network.dsl.line_mode='vdsl'
    set network.dsl.firmware='${firmwarePath}'

    set network.atm.vpi='8'
    set network.atm.vci='35'
    EOF
    # FIXME: Determine if I should add this?
    # set network.dsl.ds_snr_offset='10'

    uci commit network
    /etc/init.d/network restart
  '';

  # Download and extract NBN-compatible XRX200 modem firmware
  currentFirmwareVersion = "07.29";
  firmwarePath = "/lib/firmware/${firmwareFilename}";
  firmwareFilename = "${firmwarePackage.outputPrefix}-vr9-B-dsl.bin";

  firmwarePackage =
    pkgs.runCommandLocal "netgear_dm200_modem_firmware"
      {
        src = firmwareImages.${currentFirmwareVersion};
        nativeBuildInputs = with pkgs; [
          p7zip
          squashfsAvmBe
        ];
        passthru.outputPrefix = "FRITZ.Box_7490-${currentFirmwareVersion}";
      }
      ''
        mkdir -p $out
        7z e "$src" -r filesystem.image

        unsquashfs filesystem.image -e filesystem_core.squashfs
        mv squashfs-root/filesystem_core.squashfs ./
        rmdir squashfs-root

        unsquashfs filesystem_core.squashfs -e lib/modules/dsp_vr9/
        for name in vr9-B-dsl.bin vr9-A-dsl.bin.bsdiff vr9-A-dsl.bin.md5sum; do
          cp "squashfs-root/lib/modules/dsp_vr9/$name" "$out/FRITZ.Box_7490-${currentFirmwareVersion}-$name"
        done
      '';
  squashfsAvmBe = pkgs.callPackage ./squashfs4-avm-be.nix { };
  firmwareImages =
    mapAttrs
      (
        version:
        { archiveStamp, sha256 }:
        pkgs.fetchurl {
          url = "https://web.archive.org/web/${archiveStamp}/https://download.avm.de/fritzbox/fritzbox-7490/other/fritz.os/FRITZ.Box_7490-${version}.image";
          inherit sha256;
        }
      )
      {
        "07.29" = {
          archiveStamp = "20221219142803";
          sha256 = "17zvswfs4fdfcmiqccbr5fwn1h5w5w5absqdnz36l10y4mrmv18j";
        };
        "07.56" = {
          archiveStamp = "20230725133212";
          sha256 = "13rn1z592ibihs5w6mbyflahzyjm03qbff7s8b77p1rfrq30iaw6";
        };
      };
in
{
  files.${firmwarePath}.source = "${firmwarePackage}/${firmwareFilename}";
  files."/etc/uci-defaults/${uciScript.name}".source = uciScript;
}
