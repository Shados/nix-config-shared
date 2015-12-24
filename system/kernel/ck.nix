{ config, pkgs, lib, ... }:

let
  cfg = config.fragments.kernel;
in

{
  config = lib.mkIf (cfg.ck) {
    nixpkgs.config.packageOverrides = pkgs: { 
      linux_4_3 = pkgs.linux_4_3.override {
        extraConfig = ''
          SCHED_BFS y # Enable BFS, setting this defaults it. Note: does not support all cgroup functionality, e.g. CPU limiting
          IOSCHED_BFQ y
          DEFAULT_IOSCHED "bfq" # Make BFQ default
          DEFAULT_CFQ n
          DEFAULT_BFQ y
        '';
        kernelPatches = [
          # BFQ support so we have nice, low-latency, responsive IO scheduling. No more interactivity failures under high disk load :)
          { name = "bfq1"; patch = ./patches/0001-block-cgroups-kconfig-build-bits-for-BFQ-v7r8-4.3.patch; }
          { name = "bfq2"; patch = ./patches/0002-block-introduce-the-BFQ-v7r8-I-O-sched-for-4.3.patch; }
          { name = "bfq3"; patch = ./patches/0003-block-bfq-add-Early-Queue-Merge-EQM-to-BFQ-v7r8-for-4.3.0.patch; }
          # CK patchset so we get BFS, and thus also have nice, low-latency, responsive CPU scheduling :)
          # BFS should also actually outperform CFS in terms of throughput, as long as you have <16 cores
          { name = "ck"; patch = ./patches/linux-4.3-ck3.patch; } 
          # Had to be modified to remove RCU_TORTURE_TEST change, irrelevant as it is disabled by NixOS kernel .config anyway, removal was necessary due to clunky kernel config builder tool
          # Also had to remove CKVERSION addition to EXTRAVERSION, due to Nix-specific build stuff
        ];
        kernelParams = [
          "elevator=bfq" # Make BFQ default, AGAIN, for good measure ;)
        ];
      };
    };
  };
}
