{ config, lib, pkgs, ... }:
# - Most of my patches are selected from the conveniently-packaged set hosted at:
#   https://gitlab.com/sirlucjan/kernel-patches
# - ck's patch set is taken from its page (http://users.on.net/~ckolivas/kernel/)
# - Other patches typically have their source listed in the patch

# Modifications:
# - ck1 modified to remove modDirVersion/EXTRAVERSION changes

# Future TODO planning, in some kind of 'order of fuckery required':
# - Patches could have dependencies on one another? But I don't actually need that so far.
# - Patches could have assertions that apply to the state of the final kernel.
# - Patches could specifiy NixOS modules (that is, provide `{ imports = ...;
#   options = ...; config = ...; }` attribute sets that would be added to the
#   system modules if a kernel using them is set in `boot.kernelPackages`).
{
  config = lib.mkMerge [
    # Some generic configuration
    {
      boot.kernelParams = [
        # Enable use of multi-queue (MQ) block IO scheduling mode
        # "scsi_mod.use_blk_mq=1"
        # Default IO scheduler to bfq-sq
        # "elevator=bfq-mq"
      ];
      boot.kernel.sysctl = {
        # As we have a patch to implement this sysctl; it isn't expected by
        # NixOS yet
        # TODO tie this to the patch that implements it -- allow associating
        # NixOS module `config` sets with patches?!
        "kernel.unprivileged_userns_clone" = 1;
      };
    }
    # Expose the kernel-customization/creation functions as part of `pkgs`.
    # mkBefore ensures this is done prior to any attempt to use this, in an
    # evaluation-order-independent manner.
    { nixpkgs.overlays = lib.mkBefore [(self: super: {
        sn = (super.sn or {}) // { kernelLib = with self.sn.kernelLib; with super.lib; {
          mkLinuxPackage = kernel: super.recurseIntoAttrs (super.linuxPackagesFor kernel);
          mkLinux = name: ver: patchFuncs: kConfig: { ... } @ mAttrs: let
            newLinux = super.callPackage ./generic_kernel.nix (let
              version = selectKernelVer ver;
              rawPatches = patchesFor version patchFuncs;
              kernelPatches = foldl' (collectedPatches: rawPatch: collectedPatches ++ rawPatch.patches or [ ]) [ ] rawPatches;
              patchConfig = foldl' (collectedConfig: rawPatch: collectedConfig + rawPatch.kConfig or "") "" rawPatches;
            in {
              inherit version kernelPatches;
              src = kernelSources.${version};
              extraConfig = kConfig + patchConfig;
              customVersion = "-${name}.shados.net";
            } // mAttrs);
          in
            mkLinuxPackage newLinux;

          # Kernel sources {{{
          mkKernelSource = version: sha256: super.fetchurl {
            url = "mirror://kernel/linux/kernel/v4.x/linux-${version}.tar.xz";
            inherit sha256;
          };
          mkKernelSources = sourceList: mapAttrs
            (ver: sha256: mkKernelSource ver sha256)
            sourceList;
          # If given majorMinor instead of exact version, choose the most-recent
          selectKernelVer = version: let
            approxMatches = filterAttrs (v: _src: versions.majorMinor v == version || v == version) kernelSources;
            sortedMatches = reverseList (sort (versionOlder) (attrNames approxMatches));
          in assert sortedMatches != []; head sortedMatches;

          # For these, get the hash with:
          # nix-prefetch-url https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-${version}.tar.xz
          kernelSources = mkKernelSources {
            "4.15.18" = "0hdg5h91zwypsgb1lp1m5q1iak1g00rml54fh6j7nj8dgrqwv29z";
            "4.17.4"  = "0n5by04hshjdc8mh86yg4zkq9y6hhvjx78ialda9ysv2ac63gmk6";
            "4.18.12" = "1icz2nkhkb1xhpmc9gxfhc3ywkni8nywk25ixrmgcxp5rgcmlsl4";
            "4.18.14" = "1lv2hpxzlk1yzr5dcjb0q0ylvlwx4ln2jvfvf01b9smr1lvd3iin";
            "4.18.16" = "1rjjkhl8lz4y4sn7icy8mp6p1x7rvapybp51p92sanbjy3i19fmy";
          };
          # }}}

          # Available patches {{{
          approxVer = super.lib.versions.majorMinor;

          patchDefWithConfig = kConfig: verPatches: kVer: let
            patchVers = patchesWithConfig kConfig verPatches;
            ver = approxVer kVer;
          in assert hasAttr ver patchVers; patchVers.${ver};
          patchesWithConfig = kConfig: verPatches: mapAttrs (version: patches: { inherit patches kConfig; }) verPatches;

          patchesFor = kVer: patchFuncs: map (patchFunc: patchFunc kVer) patchFuncs;

          soloPatch = name: patch: [ { inherit name patch; } ];
          ckpdsSharedConfig = ''
            # Because ck-patchset's MUQSS and PDS are both based on BFS, they
            # are many of the same negative deps
            CFS_BANDWIDTH? n
            RT_GROUP_SCHED? n
            SCHED_AUTOGROUP? n
          '';
          patches = with super.lib; {
            # TODO add equivalent to this back
            # # PDS-mq and MUQSS patches can't be applied at the same time, currently, which
            # # is not surprising as they are both forks of the same previous scheduler (BFS)
            # assert hasPatch "ck" -> ! hasPatch "pds";
            mnative = stdenv: _kVer: {
              patches = let
                # Effectively enable use of -march=native by using a local-only impure
                # derivation to determine its actual value, then pass that as input to the
                # pure kernel derivation in the form of a patch
                mNativeOptions = builtins.readFile (super.callPackage ./march.nix { inherit stdenv; });
                purifiedPatch = patchTemplate: super.runCommand "purify-patch" {
                  inherit patchTemplate mNativeOptions;
                } ''
                  substituteAll $patchTemplate $out
                '';
              in soloPatch "mnative" (purifiedPatch ./patches/4.13+-pure-mnative.patch.template);
              kConfig = ''
                MNATIVE y # -march=native kernel optimizations
              '';
            };
            # TODO update this to take into account the differing standard
            # patches for various versions?
            nixos = _kver: {
              patches = with super.kernelPatches; [
                bridge_stp_helper
                modinst_arg_list_too_long
              ];
              kConfig = "";
            };

            # General BFQ improvements, and multi-queue BFQ
            bfq = patchDefWithConfig ''
                BLK_CGROUP y
                BLK_WBT y # CoDeL-based writeback throttling
                BLK_WBT_SQ y
                BLK_WBT_MQ y
                IOSCHED_BFQ n
                BFQ_GROUP_IOSCHED? n

                SCSI_MQ_DEFAULT n
                DM_MQ_DEFAULT n
                MQ_IOSCHED_BFQ y
                MQ_BFQ_GROUP_IOSCHED y

                IOSCHED_BFQ_SQ y
                BFQ_SQ_GROUP_IOSCHED y
                DEFAULT_BFQ_SQ y
              '' {
                "4.15" = soloPatch "bfq" ./patches/4.15/bfq-sq-mq-git-20180404.patch;
                "4.17" = [
                  { name = "bfq"; patch = ./patches/4.17/bfq-sq-mq-v8r12-2K180625.patch; }
                  { name = "bfq-fixes-1"; patch = ./patches/4.17/0100-Check-presence-on-tree-of-every-entity-after-every-a.patch; }
                  { name = "bfq-fixes-2"; patch = ./patches/4.17/0915-block-fixes-from-pfkernel.patch; }
                  { name = "bfq-fixes-3"; patch = ./patches/4.17/0916-block-fixes-from-pfkernel.patch; }
                ];
                "4.18" = [
                  { name = "bfq"; patch = ./patches/4.18/bfq-sq-mq-v9r1-2K181012.patch; }
                  { name = "bfq-fixes-1"; patch = ./patches/4.18/0100-Check-presence-on-tree-of-every-entity-after-every-a.patch; }
                  { name = "bfq-fixes-2"; patch = ./patches/4.18/0915-fixes-from-pfkernel-v4.18.10.patch; }
                  { name = "bfq-fixes-3"; patch = ./patches/4.18/0916-fixes-from-pfkernel-v4.18.7.patch; }
                  # { name = "bfq-fixes-4"; patch = ./patches/4.18/0917-fixes-from-pfkernel.patch; } # Included in 4.18.14 at least
                  { name = "bfq-fixes-5"; patch = ./patches/4.18/0918-fixes-from-pfkernel.patch; }
                  { name = "bfq-fixes-6"; patch = ./patches/4.18/0919-fixes-from-pfkernel.patch; }
                ];
              };
            ck = patchDefWithConfig (''
                SCHED_MUQSS y
                RQ_SMT y # RQ_MC is better for 6 or less cores, apparently, as a rule of thumb
              '' + ckpdsSharedConfig) {
                "4.15" = soloPatch "ck" ./patches/4.15/ck1.patch;
                "4.17" = soloPatch "ck" ./patches/4.17/ck1.patch;
                "4.18" = soloPatch "ck" ./patches/4.18/ck1.patch;
              };
            fixes = patchDefWithConfig "" {
              "4.17" = [
                { name = "sysctl-disallow-newuser"; patch = ./patches/4.17/0001-add-sysctl-to-disallow-unprivileged-CLONE_NEWUSER-by.patch; }
                { name = "revert-i915-alternate-fix-mode"; patch = ./patches/4.17/0002-Revert-drm-i915-edp-Allow-alternate-fixed-mode-for-e.patch; }
              ];
            };
            kvm-preemption-warning = _kVer: {
              patches = soloPatch "kvm-preemption-warning" ./patches/kvm-fix-preemption-warnings-in-kvm_vcpu_block.patch;
            };
            pds = patchDefWithConfig (''
                SCHED_PDS y
              '' + ckpdsSharedConfig) {
                "4.15" = soloPatch "pds" ./patches/4.15/pds-098k.patch;
                "4.17" = soloPatch "pds" ./patches/4.17/pds-098s.patch;
                "4.18" = [
                  { name = "pds-1"; patch = ./patches/4.18/0001-pds-4.18-merge-v0.98u.patch; }
                  { name = "pds-2"; patch = ./patches/4.18/0002-pds-4.18-drop-irrelevant-bits-merged-by-mistake.patch; }
                  { name = "pds-3"; patch = ./patches/4.18/0003-pds-4.18-merge-v0.98v.patch; }
                  { name = "pds-4"; patch = ./patches/4.18/0004-pds-4.18-merge-v0.98w.patch; }
                  { name = "pds-5"; patch = ./patches/4.18/0005-pds-4.18-merge-v0.98x.patch; }
                  { name = "pds-6"; patch = ./patches/4.18/0006-pds-Enable-SMT_NICE-scheduling.patch; }
                  { name = "pds-7"; patch = ./patches/4.18/0007-Tag-PDS-0.98y.patch; }
                  { name = "pds-8"; patch = ./patches/4.18/0008-pds-Replace-task_queued-by-task_on_rq_queued.patch; }
                  { name = "pds-9"; patch = ./patches/4.18/0009-pds-Don-t-balance-on-an-idle-task.patch; }
                  { name = "pds-10"; patch = ./patches/4.18/0010-pds-Improve-idle-task-SMT_NICE-handling-in-ttwu.patch; }
                  { name = "pds-11"; patch = ./patches/4.18/0011-pds-Re-mapping-SCHED_DEADLINE-to-SCHED_FIFO.patch; }
                  { name = "pds-12"; patch = ./patches/4.18/0012-Tag-PDS-0.98z.patch; }
                  { name = "pds-13"; patch = ./patches/4.18/0013-pds-Fix-sugov_kthread_create-fail-to-set-policy.patch; }
                  { name = "pds-14"; patch = ./patches/4.18/0014-pds-Fix-task-burst-fairness-issue.patch; }
                  { name = "pds-15"; patch = ./patches/4.18/0015-Tag-PDS-0.99a.patch; }
                ];
              };
            uksm = patchDefWithConfig ''
                UKSM y # Ultra Kernel Same-page Matching
              '' {
                "4.15" = soloPatch "uksm" ./patches/4.15/uksm.patch;
                "4.17" = soloPatch "uksm" ./patches/4.17/uksm.patch;
                "4.18" = [
                  { name = "uksm-1"; patch = ./patches/4.18/0001-uksm-4.18-initial-submission.patch; }
                  { name = "uksm-2"; patch = ./patches/4.18/0002-uksm-4.18-rework-exit_mmap-locking.patch; }
                ];
              };
          };
          # }}}
        }; };
      })];
    }
    # Some machine-specific kernels, mostly as examples. On most machines this
    # is used, I just set `boot.kernelPackages = with pkgs.sn.kernelLib; mkLinux ...`
    # directly.
    { nixpkgs.overlays = [(self: super: with super.sn.kernelLib; with super.lib; let
          # .config partials {{{
          kConfig = {
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
              r8169? y
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
          gcc8Stdenv = with super; overrideCC stdenv gcc8;
        in {
          kernels.dreamlogic = mkLinux "dreamlogic" "4.18" (with patches;
            [ nixos bfq uksm ck ] ++ singleton (mnative gcc8Stdenv))
            kConfig.dreamlogic
            { stdenv = gcc8Stdenv; };
          kernels.greymatters = mkLinux "greymatters" "4.18" (with patches;
            # [ nixos uksm ck kvm-preemption-warning ] ++ singleton (mnative gcc8Stdenv))
            [ nixos uksm ck ] ++ singleton (mnative gcc8Stdenv))
            kConfig.greymatters
            { stdenv = gcc8Stdenv; };
        }
      )];
    }
  ];
}
