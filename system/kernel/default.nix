{ config, pkgs, ... }:

with pkgs.lib;
let
  cfg = config.fragments.kernel;
in

{
  options = {
    fragments.kernel.ck = mkOption {
      description = ''
        Whether or not to enable the ck and the bfq patchesets.
      '';
      default = false;
      type = types.bool;
    };
  };

  config = {
    boot.kernelPackages = pkgs.linuxPackages_4_3;

    nixpkgs.config.packageOverrides = pkgs: { 
      linux_4_3 = pkgs.linux_4_3.override {
        extraConfig = ''
          ${optionalString cfg.ck ''
            SCHED_BFS y # Enable BFS, setting this defaults it. Note: does not support all cgroup functionality, e.g. CPU limiting
            IOSCHED_BFQ y
            DEFAULT_IOSCHED "bfq" # Make BFQ default
            DEFAULT_CFQ n
            DEFAULT_BFQ y
          ''}
        '';
        kernelPatches = [
          # cfg.ck patches
            # BFQ support so we have nice, low-latency, responsive IO scheduling. No more interactivity failures under high disk load :)
            mkIf cfg.ck { name = "bfq1"; patch = ./patches/0001-block-cgroups-kconfig-build-bits-for-BFQ-v7r8-4.3.patch; }
            mkIf cfg.ck { name = "bfq2"; patch = ./patches/0002-block-introduce-the-BFQ-v7r8-I-O-sched-for-4.3.patch; }
            mkIf cfg.ck { name = "bfq3"; patch = ./patches/0003-block-bfq-add-Early-Queue-Merge-EQM-to-BFQ-v7r8-for-4.3.0.patch; }
            # CK patchset so we get BFS, and thus also have nice, low-latency, responsive CPU scheduling :)
            # BFS should also actually outperform CFS in terms of throughput, as long as you have <16 cores
            mkIf cfg.ck { name = "ck"; patch = ./patches/linux-4.3-ck3.patch; } 
            # Had to be modified to remove RCU_TORTURE_TEST change, irrelevant as it is disabled by NixOS kernel .config anyway, removal was necessary due to clunky kernel config builder tool
            # Also had to remove CKVERSION addition to EXTRAVERSION, due to Nix-specific build stuff
        ];
        kernelParams = [
          optionalString cfg.ck "elevator=bfq" # Make BFQ default, AGAIN, for good measure ;)
        ];
      };
    };
  };
}
