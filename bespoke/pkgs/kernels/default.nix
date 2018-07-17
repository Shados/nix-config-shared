{ config, pkgs, ... }:
# Most of my patches are selected from the conveniently-packaged set hosted at:
# https://gitlab.com/sirlucjan/kernel-patches
# graysky's gcc patch and ck's patch sent are taken directly from their sources
# Modifications:
# - ck1 modified to remove modDirVersion/EXTRAVERSION changes

# TODOs:
# - [ ] Handle kernel -march more explicitly
# - [ ] Prefer local build for the native kernel -march

let
  kernels = { # {{{
    "4.15" = {
      version = "4.15.18";
      verHash = "0hdg5h91zwypsgb1lp1m5q1iak1g00rml54fh6j7nj8dgrqwv29z";
    };
    "4.17" = {
      version = "4.17.4";
      verHash = "0n5by04hshjdc8mh86yg4zkq9y6hhvjx78ialda9ysv2ac63gmk6";
    };
  }; # }}}

  patches = { # {{{
    gcc-optimize = {
      "4.9" = [ { name = "gcc-optimize"; patch = ./patches/4.13+-gcc_v4.9+-enable_additional_cpu_optimizations.patch; } ];
      "8.1" = [ { name = "gcc-optimize"; patch = ./patches/4.13+-gcc_v8.1+-enable_additional_cpu_optimizations.patch; } ];
    };

    other = {
      kvm-preemption-warning = [ { name = "kvm-preemption-warning"; patch = ./patches/kvm-fix-preemption-warnings-in-kvm_vcpu_block.patch; } ];
    };

    "4.15" = {
      uksm = [
        { name = "uksm"; patch = ./patches/4.15-uksm.patch; }
      ];
      bfq-improvements = [
        { name = "bfq-improvements"; patch = ./patches/4.15-bfq-sq-mq-git-20180404.patch; }
      ];
      ck = [
        { name = "ck"; patch = ./patches/4.15-ck1.patch; }
      ];
      pds = [
        { name = "pds"; patch = ./patches/4.15-pds-098k.patch; }
      ];
    };

    "4.17" = {
      fixes = [
        { name = "sysctl-disallow-newuser"; patch = ./patches/4.17-0001-add-sysctl-to-disallow-unprivileged-CLONE_NEWUSER-by.patch; }
        { name = "revert-i915-alternate-fix-mode"; patch = ./patches/4.17-0002-Revert-drm-i915-edp-Allow-alternate-fixed-mode-for-e.patch; }
      ];
      bfq-improvements = [
        { name = "bfq-improvements"; patch = ./patches/4.17-bfq-sq-mq-v8r12-2K180625.patch; }
        { name = "tree-entity-presence"; patch = ./patches/4.17-0100-Check-presence-on-tree-of-every-entity-after-every-a.patch; }
        { name = "pfkernel-block-fixes-1"; patch =./patches/4.17-0915-block-fixes-from-pfkernel.patch; }
        { name = "pfkernel-block-fixes-2"; patch =./patches/4.17-0916-block-fixes-from-pfkernel.patch; }
      ];
      uksm = [
        { name = "uksm"; patch = ./patches/4.17-uksm.patch; }
      ];
      ck = [
        { name = "ck"; patch = ./patches/4.17-ck1.patch; }
      ];
      pds = [
        { name = "pds"; patch = ./patches/4.17-pds-098s.patch; } 
      ];
    };
  }; # }}}
  sn_patches = version: patchnames: builtins.foldl' (col: pname: col ++ patches.${version}.${pname}) [ ] patchnames;

  nixos_patches = with pkgs; [
    kernelPatches.bridge_stp_helper kernelPatches.modinst_arg_list_too_long
  ];
  baseline_patches = nixos_patches ++ patches.gcc-optimize."4.9";

  sn_4_15_patch_baseline = baseline_patches ++ sn_patches "4.15" [
    "bfq-improvements" "uksm"
  ];

  # .config partials {{{
  kconfig = {
    dreamlogic = ''
      # Disable hardware I don't/won't use on this box
      VGA_SWITCHEROO n # Hybrid graphics support
      DRM_GMA600 n
      DRM_GMA3600 n

      # No wifi or BT, kthx
      WLAN n
      WIRELESS n
      CFG80211? n
      CFG80211_WEXT? n # Without it, ipw2200 drivers don't build
      IPW2100_MONITOR? n # support promiscuous mode
      IPW2200_MONITOR? n # support promiscuous mode
      HOSTAP_FIRMWARE? n # Support downloading firmware images with Host AP driver
      HOSTAP_FIRMWARE_NVRAM? n
      ATH9K_PCI? n # Detect Atheros AR9xxx cards on PCI(e) bus
      ATH9K_AHB? n # Ditto, AHB bus
      B43_PHY_HT? n
      BCMA_HOST_PCI? n
      BT n
      BT_HCIUART? n
      WAN n
      SCSI_LOWLEVEL_PCMCIA n

      # Embed r8169 for use with netconsole
      r8169 y
    '';
    greymatters = ''
      # Disable hardware I don't/won't use on this box
      VGA_SWITCHEROO n # Hybrid graphics support
      DRM_GMA600 n
      DRM_GMA3600 n

      # No BT or modems, kthx
      BT n
      BT_HCIUART? n
      WAN n
    '';
  };
  # }}}
in

{
  boot.kernelParams = [
    # Enable use of multi-queue (MQ) block IO scheduling mode
    # "scsi_mod.use_blk_mq=1"
    # Default IO scheduler to bfq-sq
    # "elevator=bfq-mq"
  ];
  boot.kernel.sysctl = {
    "kernel.unprivileged_userns_clone" = 1; # As we have a patch to implement this sysctl; it isn't expected by NixOS yet
  };
  nixpkgs.config.packageOverrides = with pkgs; let
    mkLinuxPackage = kernel: recurseIntoAttrs (linuxPackagesFor kernel);
    mkSNLinux = name: version: patches: { ... } @ mAttrs: let
      newLinux = callPackage ./generic_kernel.nix (kernels.${version} // {
        kernelPatches = patches;
        extraConfig = kconfig.${name};
        customVersion = "-${name}.shados.net";
      } // mAttrs);
    in
    mkLinuxPackage newLinux;
  in rec {
    kernel_dreamlogic_4_15 = mkSNLinux "dreamlogic" "4.15" (
      sn_4_15_patch_baseline ++ sn_patches "4.15" [ "ck" ]
    ) {};
    kernel_dreamlogic_4_17 = mkSNLinux "dreamlogic" "4.17" (
      nixos_patches ++ patches.gcc-optimize."8.1" ++ sn_patches "4.17" [
        "fixes" "bfq-improvements" "uksm"
        "ck"
      ])
    {
      stdenv = overrideCC stdenv gcc8;
    };
    kernel_greymatters_4_17 = mkSNLinux "greymatters" "4.17" (
      nixos_patches ++ patches.gcc-optimize."8.1" ++ sn_patches "4.17" [
        "fixes" "bfq-improvements" "uksm"
        "ck"
      ]
      ++ patches.other.kvm-preemption-warning)
    {
      stdenv = overrideCC stdenv gcc8;
    };
  };
}
