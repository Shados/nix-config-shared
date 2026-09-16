# This module has two main outputs:
# - system.build.diskSetupScript: a script I can use on a running Orange Pi 5
#   Pro to handle eMMC setup: partitioning, formatting, and bootloader
#   installation After that, just need to run nixos-install pointed at the
#   system closure
# - system.build.emmcImage: a pre-baked image I can directly flash onto an eMMC
#   for booting an Orange Pi 5 Pro from Could be flashed to it via maskrom
#   booting the SBC, or by booting the vendor distro on the SBC and SSH'ing it
#   over, etc.
{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption literalExpression types;
in
{
  imports = [ (modulesPath + "/image/file-options.nix") ];

  options.emmcImage = {
    storePaths = mkOption {
      type = with types; listOf package;
      example = literalExpression "[ pkgs.stdenv ]";
      description = ''
        Derivations to be included in the Nix store in the generated eMMC image.
      '';
    };

    ubootPartitionSize = mkOption {
      type = with types; int;
      # Significantly more than really needed :)
      default = 16;
      description = ''
        The size in megabytes to be used for the protective u-boot firmware partition on the eMMC
        image, starting at sector 64.
      '';
    };

    ubootPartitionGUID = mkOption {
      type = with types; str;
      default = "63c4702e-fe41-411d-a040-2b72d8ee0d0b"; # random from uuidgen
      description = ''
        The GUID to use for the protective u-boot firmare partition. For EBBR compliance, this
        should not reuse a GUID used for a non-protective partition type.
      '';
    };

    bootPartitionSize = mkOption {
      type = with types; int;
      default = 1024;
      description = ''
        The size in megabytes to be used for the EXT4 /boot partition on the eMMC image.
      '';
    };

    bootFSLabel = mkOption {
      type = types.str;
      default = "${config.networking.hostName}-boot";
      description = ''
        Label for the NixOS /boot filesystem.
      '';
    };

    rootFSLabel = mkOption {
      type = types.str;
      default = "${config.networking.hostName}-root";
      description = ''
        Label for the NixOS root filesystem.
      '';
    };

    sectorAlignment = mkOption {
      type = with types; int;
      # The FORESEE FEMDNN256G-A3A56 eMMCs I'm using have a 512kb erase block size, so align
      # partitions to 1024 512b sectors
      default = 1024;
      description = ''
        The sector alignment to use when creating partitions for the eMMC image (aside from the
        protective u-boot firmware partition, which starts at sector 64).
      '';
    };

    # TODO populateBootCommands?
    populateRootCommands = mkOption {
      example = literalExpression "''\${lib.getExe' pkgs.systemd \"systemd-machine-id-setup\"} --root ./files''";
      default = "";
      description = ''
        Shell commands to populate the ./files directory.
        All files in that directory are copied to the root (/) partition on the eMMC image.
      '';
    };

    preBuildCommands = mkOption {
      type = types.lines;
      example = literalExpression ''
        '''
          if [ ! -w "$root_fs" ]; then
            cp --no-preserve=mode "$root_fs" ./root-fs.img
            root_fs=./root-fs.img
          fi
          resize2fs $root_fs 15G
        '''
      '';
      default = "";
      description = ''
        Shell commands to run after the root filesystem image has been prepared, but before the
        final eMMC image is assembled.

        The path to the root filesystem image is available in the {var}`root_fs` shell variable.
        This hook can be used to modify the rootfs, for example to resize it or inject additional
        files.

        Note that when {option}`eMMC.compressImage` is disabled, {var}`root_fs` points to a
        read-only store path. To modify it, first copy it to a writable location and update
        {var}`root_fs` to point to the copy.
      '';
    };

    postBuildCommands = mkOption {
      type = types.lines;
      example = literalExpression "'' dd if=\${pkgs.myBootLoader}/SPL of=$img bs=1024 seek=1 conv=notrunc ''";
      default = "";
      description = ''
        Shell commands to run after the eMMC image has been assembled.

        The path to the image is available in the {var}`img` shell variable. This hook is typically
        used for boards that require writing a bootloader (such as u-boot SPL) to a fixed offset
        before the first partition.
      '';
    };

    compressImage = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether the SD image should be compressed using {command}`zstd`.
      '';
    };

    expandOnBoot = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to configure the sd image to expand it's partition on boot.
      '';
    };

    nixPathRegistrationFile = mkOption {
      type = types.str;
      default = "/nix-path-registration";
      description = ''
        Location of the file containing the input for nix-store --load-db once the machine has
        booted. If overriding fileSystems."/" then you should to set this to the root mount +
        /nix-path-registration
      '';
    };
  };

  config =
    let
      imageDirectory = "emmc-image";

      diskSetupScript = pkgs.writers.writeBash "disk-setup-${config.networking.hostName}" ''
        set -x
        set -eEo pipefail
        shopt -s inherit_errexit nullglob
        set -o nounset

        MNT_ROOT="/mnt/emmc"

        function main {
          emmc="/dev/mmcblk0"

          printf "Tearing down any existing mounts & swap\n"
          if sudo mountpoint -q "$MNT_ROOT"; then
            sudo umount -fR "$MNT_ROOT"
          fi

          printf "Wiping disk...\n"
          if ! sudo blkdiscard -vf "$emmc"; then
            # Wipe partition/fs headers first
            for dev in "''${emmc}p"*; do
              sudo wipefs -fa "$dev"
            done
            # Wipe partition table
            sudo wipefs -fa "$emmc"
          fi
          sudo blockdev --rereadpt "$emmc"
          sudo udevadm trigger -w "$emmc"
          printf "Wiped %s\n" "$emmc"

          printf "Partitioning %s\n" "$emmc"
          sudo ${partitionCmd "$emmc"}

          printf "Waiting for disk partitioning changes to settle...\n"
          sudo blockdev --rereadpt "$emmc"
          sudo udevadm trigger -w "$emmc"

          printf "Formatting %s partitions\n" "$emmc"
          sudo ${formatBootCmd} ''${emmc}p2

          printf "Creating root bcachefs filesystem on %sp3\n" "$emmc"
          sudo ${formatRootCmd} ''${emmc}p3

          printf "Flashing u-boot\n"
          uboot=${config.boot.loader.uboot.package}/${config.boot.loader.uboot.fileToFlash}
          sudo dd conv=notrunc if=$uboot of=$emmc seek=64

          printf "Mounting filesystems\n"
          sudo mkdir -p "$MNT_ROOT"
          sudo mount "''${emmc}p3" "$MNT_ROOT"

          sudo mkdir "$MNT_ROOT/boot"
          sudo mount "''${emmc}p2" "$MNT_ROOT/boot"

          printf "All done!\n"
        }

        main "$@"
      '';

      emmcImage = pkgs.callPackage (
        {
          stdenv,
          dosfstools,
          e2fsprogs,
          bcachefs-tools,
          mtools,
          libfaketime,
          util-linux,
          gptfdisk,
          zstd,
        }:
        stdenv.mkDerivation {
          name = config.image.fileName;
          nativeBuildInputs = [
            dosfstools
            e2fsprogs
            bcachefs-tools
            libfaketime
            mtools
            util-linux
            gptfdisk
          ]
          ++ lib.optional config.emmcImage.compressImage zstd;

          inherit (config.emmcImage) compressImage;

          buildCommand = ''
            mkdir -p $out/nix-support $out/${imageDirectory}
            export img=$out/${imageDirectory}/${config.image.baseName}.img

            echo "${pkgs.stdenv.buildPlatform.system}" > $out/nix-support/system
            echo "file emmc-image $img.zst" >> $out/nix-support/hydra-build-products

            root_fs=${rootfsImage}
            ${lib.optionalString config.emmcImage.compressImage ''
              root_fs=./root-fs.img
              echo "Decompressing rootfs image"
              zstd -d --no-progress "${rootfsImage}" -o $root_fs
            ''}

            boot_fs=${bootfsImage}
            ${lib.optionalString config.emmcImage.compressImage ''
              boot_fs=./boot-fs.img
              echo "Decompressing bootfs image"
              zstd -d --no-progress "${bootfsImage}" -o $boot_fs
            ''}

            ${config.emmcImage.preBuildCommands}

            # Create an image file sized to fit protective u-boot partition + / + /boot + GPT headers and protective MBR
            firmwareSizeBlocks=$((${toString config.emmcImage.ubootPartitionSize} * 1024 * 1024 / 512))
            rootSizeBlocks=$(du -B 512 --apparent-size $root_fs | awk '{ print $1 }')
            bootSizeBlocks=$(du -B 512 --apparent-size $boot_fs | awk '{ print $1 }')
            imageSize=$((firmwareSizeBlocks * 512 + rootSizeBlocks * 512 + bootSizeBlocks * 512 + 34 * 512 + 33 * 512))
            truncate -s $imageSize $img

            # Create the partition table
            # 1: protective partition covering the entire region the firmware is written to, starting at sector 64 with the ID block
            # 2: /boot
            # 3: /root
            ${partitionCmd "$img"}

            # Copy the uboot firmware onto the eMMC image
            uboot=${config.boot.loader.uboot.package}/${config.boot.loader.uboot.fileToFlash}
            eval $(partx $img -o START,SECTORS --nr 1 --pairs)
            dd conv=notrunc if=$uboot of=$img seek=$START count=$SECTORS

            # Copy the bootfs onto the eMMC image
            eval $(partx $img -o START,SECTORS --nr 2 --pairs)
            dd conv=notrunc if=$boot_fs of=$img seek=$START count=$SECTORS

            # Copy the rootfs onto the eMMC image
            eval $(partx $img -o START,SECTORS --nr 3 --pairs)
            dd conv=notrunc if=$root_fs of=$img seek=$START count=$SECTORS

            ${config.emmcImage.postBuildCommands}

            if test -n "$compressImage"; then
                zstd -T$NIX_BUILD_CORES --rm $img
            fi
          '';
        }
      ) { };

      bootfsImage = pkgs.callPackage (
        {
          pkgs,
          lib,
          zstd,
          e2fsprogs,
          libfaketime,
          perl,
          fakeroot,
        }:

        pkgs.stdenv.mkDerivation {
          name = "ext4-boot.img${lib.optionalString config.emmcImage.compressImage ".zst"}";

          nativeBuildInputs = [
            e2fsprogs.bin
            libfaketime
            perl
            fakeroot
          ]
          ++ lib.optional config.emmcImage.compressImage zstd;

          buildCommand = ''
            ${if config.emmcImage.compressImage then "img=temp.img" else "img=$out"}
            echo "Preparing extlinux boot setup for image..."
            (
            mkdir -p ./files
            ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files
            )

            mkdir -p ./bootImage
            (
              GLOBIGNORE=".:.."
              shopt -u dotglob

              for f in ./files/*; do
                  cp -a --reflink=auto -t ./bootImage/ "$f"
              done
            )

            # Make a crude approximation of the *minimum* size of the target image.
            numInodes=$(find ./bootImage | wc -l)
            numDataBlocks=$(du -s -c -B 4096 --apparent-size ./bootImage | tail -1 | awk '{ print int($1 * 1.20) }')
            bytes=$((2 * 4096 * $numInodes + 4096 * $numDataBlocks))
            echo "Creating an EXT4 image of $bytes bytes (numInodes=$numInodes, numDataBlocks=$numDataBlocks)"

            mebibyte=$(( 1024 * 1024 ))
            # Round up to the nearest mebibyte.
            if (( bytes % mebibyte )); then
              bytes=$(( ( bytes / mebibyte + 1) * mebibyte ))
            fi

            target_bytes=$((${toString config.emmcImage.bootPartitionSize} * mebibyte))
            if [[ $bytes -gt $target_bytes ]]; then
              echo "Target size of ${toString config.emmcImage.bootPartitionSize}MB is too small to contain image contents ($bytes bytes)"
              exit 1
            fi

            truncate -s $target_bytes $img

            faketime -f "1970-01-01 00:00:01" fakeroot ${formatBootCmd} -d ./bootImage "$img"

            export EXT2FS_NO_MTAB_OK=yes
            # I have ended up with corrupted images sometimes, I suspect that happens when the build machine's disk gets full during the build.
            if ! fsck.ext4 -n -f $img; then
              echo "--- Fsck failed for EXT4 image of $target_bytes bytes (numInodes=$numInodes, numDataBlocks=$numDataBlocks) ---"
              cat errorlog
              return 1
            fi

            if [ ${toString config.emmcImage.compressImage} ]; then
              echo "Compressing image"
              zstd -T$NIX_BUILD_CORES -v --no-progress ./$img -o $out
            fi
          '';
        }
      ) { };

      rootfsImage =
        pkgs.callPackage
          (
            # Builds a bcachefs image containing a populated /nix/store with the closure
            # of store paths passed in the storePaths parameter, in addition to the
            # contents of a directory that can be populated with commands. The
            # generated image is sized to roughly fit its contents, with the expectation
            # that a script resizes the filesystem at boot time.
            {
              pkgs,
              lib,
              # List of derivations to be included
              storePaths,
              # Whether or not to compress the resulting image with zstd
              compressImage ? false,
              zstd,
              # Shell commands to populate the ./files directory.
              # All files in that directory are copied to the root of the FS.
              populateImageCommands ? "",
              bcachefs-tools,
              libfaketime,
              perl,
              fakeroot,
            }:

            let
              sdClosureInfo = pkgs.buildPackages.closureInfo { rootPaths = storePaths; };
            in
            pkgs.stdenv.mkDerivation {
              name = "bcachefs-root.img${lib.optionalString compressImage ".zst"}";

              nativeBuildInputs = [
                bcachefs-tools
                libfaketime
                perl
                fakeroot
              ]
              ++ lib.optional compressImage zstd;

              buildCommand = ''
                ${if compressImage then "img=temp.img" else "img=$out"}
                (
                mkdir -p ./files
                ${populateImageCommands}
                )

                echo "Preparing store paths for image..."

                # Create nix/store before copying path
                mkdir -p ./rootImage/nix/store

                xargs -I % cp -a --reflink=auto % -t ./rootImage/nix/store/ < ${sdClosureInfo}/store-paths
                (
                  GLOBIGNORE=".:.."
                  shopt -u dotglob

                  for f in ./files/*; do
                      cp -a --reflink=auto -t ./rootImage/ "$f"
                  done
                )

                # Also include a manifest of the closures in a format suitable for nix-store --load-db
                cp ${sdClosureInfo}/registration ./rootImage/nix-path-registration

                # Make a crude approximation of the size of the target image.
                # If the script starts failing, increase the fudge factors here.
                numInodes=$(find ./rootImage | wc -l)
                numDataBlocks=$(du -s -c -B 4096 --apparent-size ./rootImage | tail -1 | awk '{ print int($1 * 1.20) }')
                bytes=$((2 * 4096 * $numInodes + 4096 * $numDataBlocks))
                echo "Creating a bcachefs image of $bytes bytes (numInodes=$numInodes, numDataBlocks=$numDataBlocks)"

                mebibyte=$(( 1024 * 1024 ))
                # Round up to the nearest mebibyte.
                # This ensures whole 512 bytes sector sizes in the disk image
                # and helps towards aligning partitions optimally.
                if (( bytes % mebibyte )); then
                  bytes=$(( ( bytes / mebibyte + 1) * mebibyte ))
                fi

                truncate -s $bytes $img

                faketime -f "1970-01-01 00:00:01" fakeroot ${formatRootCmd} --source=./rootImage $img

                # We may want to shrink the file system and resize the image to
                # get rid of the unnecessary slack here

                # # shrink to fit
                # resize2fs -M $img

                # # Add 16 MebiByte to the current_size
                # new_size=$(dumpe2fs -h $img | awk -F: \
                #   '/Block count/{count=$2} /Block size/{size=$2} END{print (count*size+16*2**20)/size}')

                # resize2fs $img $new_size

                if [ ${toString compressImage} ]; then
                  echo "Compressing image"
                  zstd -T$NIX_BUILD_CORES -v --no-progress ./$img -o $out
                fi
              '';
            }
          )
          {
            inherit (config.emmcImage) compressImage storePaths;
            populateImageCommands = config.emmcImage.populateRootCommands;
          };

      # For EBBR compliance, flag the protective u-boot firmware partition as a 'system partition'
      # Setting legacy boot attribute on partition 2 is needed for u-boot bootscan to treat the
      # partition as bootable
      partitionCmd = target: ''
        sgdisk ${target} \
          --set-alignment 1 \
          --new "1:64:${toString config.emmcImage.ubootPartitionSize}M" \
          --typecode "1:${config.emmcImage.ubootPartitionGUID}" \
          --attributes "1:set:0" \
          --set-alignment ${toString config.emmcImage.sectorAlignment} \
          --new "2::+${toString config.emmcImage.bootPartitionSize}M" \
          --attributes "2:set:2" \
          --typecode "2:8300" \
          --new "3::" \
          --typecode "3:8300"
      '';

      formatBootCmd = "mkfs.ext4 -L ${config.emmcImage.bootFSLabel}";

      formatRootCmd = ''
        bcachefs format \
          --metadata_checksum=xxhash \
          --data_checksum=xxhash \
          --compression=lz4 \
          --acl \
          --discard \
          -L ${config.emmcImage.rootFSLabel}'';
    in
    {
      fileSystems."/" = {
        device = "/dev/disk/by-label/${config.emmcImage.rootFSLabel}";
        fsType = "bcachefs";
      };
      fileSystems."/boot" = {
        label = config.emmcImage.bootFSLabel;
        fsType = "ext4";
      };

      boot.loader.grub.enable = false;
      boot.loader.generic-extlinux-compatible.enable = true;

      emmcImage.storePaths = [ config.system.build.toplevel ];

      image.extension = if config.emmcImage.compressImage then "img.zst" else "img";
      image.filePath = "${imageDirectory}/${config.image.fileName}";

      system.build.image = config.system.build.emmcImage;
      system.build.emmcImage = emmcImage;
      system.build.diskSetupScript = diskSetupScript;

      systemd.services.expand-root-partition = lib.mkIf config.emmcImage.expandOnBoot {
        description = "Grow the root partition and filesystem to fill the eMMC";
        unitConfig = {
          DefaultDependencies = false;
          ConditionPathExists = config.emmcImage.nixPathRegistrationFile;
        };
        wantedBy = [ "sysinit.target" ];
        before = [
          "sysinit.target"
          "shutdown.target"
          "register-nix-paths.service"
        ];
        after = [ "local-fs.target" ];
        conflicts = [ "shutdown.target" ];
        restartIfChanged = false;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          # Figure out device names for the boot device and root filesystem.
          rootPart=$(${lib.getExe' pkgs.util-linux "findmnt"} -n -o SOURCE /)
          bootDevice=$(${lib.getExe' pkgs.util-linux "lsblk"} -npo PKNAME $rootPart)
          partNum=$(${lib.getExe' pkgs.util-linux "lsblk"} -npo PARTN $rootPart)

          # Resize the root partition and the filesystem to fit the disk
          ${lib.getExe' pkgs.cloud-utils.guest "growpart"} $bootDevice $partNum
          ${lib.getExe' pkgs.parted "partprobe"}
          ${lib.getExe' pkgs.bcachefs-tools "bcachefs"} device resize ''${bootDevice}p$partNum
        '';
      };

      systemd.services.register-nix-paths =
        let
          inherit (config.emmcImage) nixPathRegistrationFile;
        in
        {
          description = "Register Nix Store Paths";
          unitConfig = {
            DefaultDependencies = false;
            ConditionPathExists = nixPathRegistrationFile;
          };
          wantedBy = [ "sysinit.target" ];
          before = [
            "sysinit.target"
            "shutdown.target"
            "nix-daemon.socket"
            "nix-daemon.service"
          ];
          after = [ "local-fs.target" ];
          conflicts = [ "shutdown.target" ];
          restartIfChanged = false;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            ${lib.getExe' config.nix.package.out "nix-store"} --load-db < ${nixPathRegistrationFile}

            # nixos-rebuild also requires a "system" profile and an /etc/NIXOS tag.
            touch /etc/NIXOS
            ${lib.getExe' config.nix.package.out "nix-env"} -p /nix/var/nix/profiles/system --set /run/current-system

            # Prevents this from running on later boots.
            rm -f ${nixPathRegistrationFile}
          '';
        };
    };
}
