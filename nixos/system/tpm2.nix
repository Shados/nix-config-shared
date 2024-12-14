# FIXME: Can probably remove once a resolution to nixpkgs #192771 is in
{ config, lib, pkgs, ... }:
let
  cfg = config.security.tpm2;
  inherit (lib) mkIf mkOption singleton types;

  writeJSON = (pkgs.formats.json { }).generate;

  # NOTE: tpm2-tss doesn't like profiles being symlinks, they need to be actual
  # files in the profiles directory, so we build it as a package.
  tssProfilesDir = pkgs.runCommandNoCCLocal "fapi-profiles" { } ''
    mkdir -p $out
    cp ${pkgs.tpm2-tss}/etc/tpm2-tss/fapi-profiles/* $out/
  '';
in
{
  options = {
    security.tpm2 = {
      tssSystemKeyStore = mkOption {
        type = types.str;
        default = "/var/lib/tpm2-tss/system/keystore";
        description = ''
          Path to use to hold the tpm2-tss system keystore.
        '';
      };
      tssLogDirectory = mkOption {
        type = types.str;
        default = "/run/tpm2-tss/eventlog";
        description = ''
          Path to use to hold the tpm2-tss event log.
        '';
      };
      tssSystemPcrs = mkOption {
        # TODO: constrain int type down to the actual set of possible PCRs
        type = with types; listOf int;
        default = [];
        description = ''
          The PCR registers which are used by the system for tpm2-tss.
        '';
      };
      tssDefaultProfile = mkOption {
        type = types.str;
        default = "P_ECCP256SHA256";
        description = ''
          Name of the default cryptographic profile chosen from the profile
          directory under /etc/tpm2-tss/fapi-profiles.
        '';
      };
    };
  };
  config = mkIf cfg.enable (lib.mkMerge [
    {
      environment.systemPackages = [ pkgs.tpm2-tss ];

      environment.sessionVariables.TSS2_FAPICONF = "/etc/tpm2-tss/fapi-config.json";

      environment.etc."tpm2-tss/fapi-config.json".source = let
        tctiOption = if cfg.tctiEnvironment.interface == "tabrmd"
          then cfg.tctiEnvironment.tabrmdConf
          else cfg.tctiEnvironment.deviceConf;
      in writeJSON "fapi-config.json" {
        profile_name = cfg.tssDefaultProfile;
        profile_dir = tssProfilesDir;
        user_dir = "~/.local/share/tpm2-tss/user/keystore";
        system_dir = cfg.tssSystemKeyStore;
        tcti = config.environment.variables.TPM2_PKCS11_TCTI;
        system_pcrs = cfg.tssSystemPcrs;
        log_dir = cfg.tssLogDirectory;
      };

      systemd.tmpfiles.rules = [
        #Type Path                                                    Mode User Group Age         Argument
        "d    ${cfg.tssSystemKeyStore}                                2775 tss  tss   -           -"
        "a+   ${cfg.tssSystemKeyStore}                                -    -    -     -           default:group:tss:rwx"
        "d    ${cfg.tssLogDirectory}                                  2775 tss  tss   -           -"
        "a+   ${cfg.tssLogDirectory}                                  -    -    -     -           default:group:tss:rwx"
        "z    /sys/kernel/security/tpm[0-9]/binary_bios_measurements  0440  root tss  -           -"
        "z    /sys/kernel/security/ima/binary_runtime_measurements    0440  root tss  -           -"
      ];

      # NOTE: It'd be nice to have a way to unset `environment.variables`
      # entries; perhaps by taking a `null`?
      systemd.services."tpm2-abrmd".serviceConfig.Environment = "G_DEBUG=all";
    }
    {
      environment.sessionVariables = lib.mkIf cfg.tctiEnvironment.enable (
        lib.attrsets.genAttrs [
          "TPM2TOOLS_TCTI"
          "TPM2_PKCS11_TCTI"
        ] (_: ''${cfg.tctiEnvironment.interface}:${
          if cfg.tctiEnvironment.interface == "tabrmd" then
            cfg.tctiEnvironment.tabrmdConf
          else
            cfg.tctiEnvironment.deviceConf
        }'')
      );
    }
  ]);
}
