{ config, lib, pkgs, ... }:
with lib;
{
  services.syncthing = {
    declarative = {
      devices = {
        dap = {
          id = "5M7O2NR-PLA6D77-3IO7BY4-RD2TZVE-7KBS63J-ZF3DT4U-HD5E4SU-WQIIIAU";
        };
        dreamlogic = {
          addresses = [ "tcp://home.shados.net:22000" ];
          id = "DOXL73C-CUSNSZU-L2RMPH2-A72HBTQ-X6DKNFU-UTRQPA5-GYZDISE-HP75MQY";
        };
        # greymatters = {
        #   id = "5BMCLMS-DU4TLRP-JFCPR2G-57GUPO3-VL4SAXV-7UZHQD7-VIORCUO-IJC36QM";
        # };
        forcedperspective = {
          id = "MEXG6FO-SQRPG3F-ZZFUX3L-KOCA5Q4-ZNXACON-PAKDDFL-ZQIZPNY-IINY2AL";
        };
        inabsentia = {
          id = "PVEBK44-4N4QOX7-RDXABYQ-FIYJFSI-PNBQISX-YQVGRHV-CGA2P6N-IVXOAAC";
        };
        mi_mix_3 = {
          id = "H7TGIVN-IYMTGHV-73E7SEP-MP5YWY7-52QNQ4T-UZL73YC-TA5LEJR-4XWAMQO";
        };
        stowaway = {
          addresses = [ "tcp://stowaway.shados.net:22000" ];
          id = "IOLIFRQ-SCKCXRM-HXGGTMY-TB3GSAL-3HUGL4S-G3MOK6C-MOD6EDU-TYOTHA6";
        };
        theroadnottaken = {
          id = "HZUS7FV-2IDGXML-KQ2J527-3LY4ERQ-RVRMSWG-MW64N4Z-MJKV5NR-KTNIEQE";
        };
      };
      folders = let inherit (config.services.syncthing) dataDir; in {
        "${dataDir}/notes" = {
          id = "notes"; label = "Notes";
          devices = [
            "dap" "dreamlogic" "forcedperspective" "inabsentia" "mi_mix_3" "stowaway" "theroadnottaken"
          ];
        };
        "${dataDir}/secure" = {
          id = "secure"; label = "Secure";
          devices = [
            "dap" "dreamlogic" "forcedperspective" "inabsentia" "mi_mix_3" "stowaway" "theroadnottaken"
          ];
        };
        "${dataDir}/photos/mi_mix_3" = {
          id = "mi_mix_3_exbj-photos"; label = "Mi Mix 3 Photos";
          devices = [
            "dreamlogic" "inabsentia" "mi_mix_3" "stowaway"
          ];
        };
        "${dataDir}/photos/dap" = {
          id = "lg-us998_c3tg-photos"; label = "DAP Photos";
          devices = [
            "dap" "dreamlogic" "inabsentia" "stowaway"
          ];
        };
        "${dataDir}/MiMix3/TitaniumBackup" = {
          id = "d73zd-qu596"; label = "MiMix3-TitaniumBackup";
          devices = [
            "dreamlogic" "inabsentia" "mi_mix_3" "stowaway"
          ];
        };
      };
    };
  };
}
