{ config, lib, options, pkgs, utils, ... }:
let
  inherit (lib) attrNames attrValues concatLists concatMapStrings concatMapStringsSep concatStringsSep elem elemAt escapeShellArg escapeShellArgs filter filterAttrs findFirst flip foldl' foldAttrs isAttrs hasPrefix head imap0 length listToAttrs mapAttrs mapAttrs' mapAttrsToList nameValuePair mkEnableOption mkIf mkMerge mkOption optionals optionalString recursiveUpdate splitString stringLength sublist substring types unique zipAttrsWith;
  inherit (utils) escapeSystemdPath;
  cfg = config.disk.fileSystems.zfs;
  opt = options.disk.fileSystems.zfs;
  cfgZfs = config.boot.zfs;
  # TODO a sizeSpec type instead of types.str for things like quota/reservation

  getDatasetMounts = dataset: map
    (fs: let
      name = if fs.mountPoint == "/" then "-" else escapeSystemdPath fs.mountPoint;
    in "${name}.mount")
    (filter (x: x.device == dataset) zfsFilesystems);

  zfsFsDatasets = map (fs: fs.device) zfsFilesystems;
  zfsFsByDataset = listToAttrs (map (fs: nameValuePair fs.device fs) zfsFilesystems);

  allPools = unique ((map fsToPool zfsFilesystems) ++ cfgZfs.extraPools ++ (attrNames cfg.pools));

  # From NixOS zfs.nix
  zfsFilesystems = filter (x: x.fsType == "zfs") config.system.build.fileSystems;
  fsToPool = fs: datasetToPool fs.device;
  datasetToPool = x: elemAt (splitString "/" x) 0;

  # Notes on ZFS handling in NixOS:
  # - Root pool(s) are mounted in the initrd
  # - Non-root pool(s) are mounted by `zfs-import-$POOL.service` units, which
  #   are required by and run before `zfs-import.target`
  # - Datasets with mountpoint=legacy are mounted by normal systemd mount
  #   units, individually
  # - Datasets with a non-legacy mountpoint are mounted collectivley, by
  #   `zfs-mount.service`, which has an after dep on `zfs-import.target`
  # - Individual mount points for datasets in a a non-root pool have a
  #   wants+after dep on their pool's import unit
  # - My own services should by wantedBy zfs.target, it looks like
  # - I don't want to support boot.zfs.extraPools, because that's explicitly
  #   intended as an escape hatch from managing ZFS pools & datasets via NixOS
  #   configuration

  bashBinScript = name: text: let
    baseScript = pkgs.writers.writeBashBin name text;
  in baseScript.overrideAttrs (oa: {
    passthru = oa.passthru or {} // {
      binPath = "${baseScript}/bin/${name}";
    };
  });

  # TODO remove / migrate to lib? {{{
  scriptToDerivation = name: script: runtimeDeps: pkgs.runCommandNoCC name {
    src = script;
    nativeBuildInputs = with pkgs; [
      makeWrapper
    ];
    buildInputs = runtimeDeps;
    inherit runtimeDeps;
    passthru.scriptPath = "bin/${name}";
  } ''
    set -v
    mkdir -p $out/bin
    cp $src $out/bin/$name
    chmod +x $out/bin/$name
    patchShebangs $out/bin
    wrapProgram $out/bin/$name \
      --prefix PATH : $out/bin:${lib.makeBinPath runtimeDeps}
  '';
  # }}}

  # Lexicographically sorted, so we create them in a valid order
  datasetList = builtins.sort (a: b: a < b) (concatLists (flip mapAttrsToList cfg.finalPools (name: poolSpec:
    flip mapAttrsToList poolSpec.datasets (_: datasetSpec: datasetPath poolSpec.name datasetSpec.path)
  )));
  # Take list of pools, generate list of (list of datasets for a pool, with the full path substituted in)
  # Concatenate the lists
  # Convert to attribute set where the keys are the full paths
  datasetAttrs = listToAttrs (map ({path, ...}@attrs: nameValuePair path attrs) (
    concatLists (flip mapAttrsToList cfg.finalPools (name: poolSpec:
      flip mapAttrsToList poolSpec.datasets (_: datasetSpec: datasetSpec // rec {
        pool = poolSpec.name;
        path = datasetPath poolSpec.name datasetSpec.path;
      })
    ))
  ));

  datasetPath = poolName: datasetPath: if stringLength datasetPath > 0
    then "${poolName}/${datasetPath}"
    else poolName;

  escapePathForName = path: lib.replaceChars [ "/" " " ] [ "-" "_" ] (lib.removePrefix "/" path);

  boolToStr = bool: if bool then "on" else "off";
  boolStrType = with types; coercedTo bool boolToStr str;
  boolMatchingStrType = pat: with types; coercedTo bool boolToStr (strMatching "(on)|(off)|(${pat})");
  boolEnumType = enumList: with types; coercedTo bool boolToStr
    (types.enum (enumList ++ [ "on" "off" ]));
  mkNullDefaultProp = attrs: mkOption (attrs // { default = null; type = types.nullOr attrs.type; });

  zfsPoolType = types.submodule ({ config, name, ... }: {
    options.name = mkOption {
      type = with types; str;
      default = name;
      description = ''
        Name of the pool;
      '';
    };
    # TODO
    # options.vdevs = ...;
    options.properties = mkOption {
      default = {};
      description = ''
        Declaratively-specified properties for this pool.
      '';
      type = types.submodule {
        freeformType = with types; attrsOf (nullOr str);
      };
    };
    options.datasets = mkOption {
      default = {};
      description = ''
        Declaratively-specified ZFS datasets for this pool.

        NOTE: You can configure the root dataset by setting the path to an
        empty string ("").
      '';
      type = types.attrsOf zfsDatasetType;
    };
  });

  zfsDatasetType = types.submodule ({ config, name, ...}: {
    options.path = mkOption {
      type = with types; str;
      default = name;
      description = ''
        Path of the dataset, within the pool.

        e.g. if the pool is named "tank", and this value is set to
        "DB/prod", then the resulting dataset will be "tank/DB/prod"

        Defaults to the attribute name of this dataset option item.
      '';
    };
    options.properties = mkOption {
      default = {};
      description = ''
        Declaratively-specified properties for this dataset.
      '';
      type = types.submodule {
        freeformType = with types; attrsOf (nullOr str);
        options.acltype = mkNullDefaultProp {
          type = with types; enum [ "off" "nfsv4" "posix" "noacl" "posixacl" ];
        };
        options.atime = mkNullDefaultProp {
          type = boolStrType;
        };
        options.checksum = mkNullDefaultProp {
          type = boolEnumType [
            "fletcher2" "fletcher4" "sha256" "noparity" "sha512" "skein" "edonr"
          ];
        };
        options.compression = mkNullDefaultProp {
          type = boolMatchingStrType
            ("(gzip(-[1-9])?)|"
            +"(lz4)|"
            +"(lzjb)|"
            +"(zle)|"
            +"(zstd(-([1-9])|(1[0-9]))?)|" # TODO verify/sanitise these last two
            +"(zstd-fast(-(1000|[1-9][0-9]?[0-9]?))?)")
          ;
        };
        options.copies = mkNullDefaultProp {
          type = with types; ints.between 1 3;
        };
        options.devices = mkNullDefaultProp {
          type = boolStrType;
        };
        options.dedup = mkNullDefaultProp {
          type = boolEnumType [
            "verify" "sha256" "sha256,verify" "sha512" "sha512,verify" "skein" "skein,verify" "edonr,verify"
          ];
        };
        # TODO: encryption is pretty much the only creation-time dataset
        # property I'm interested in
        # options.encryption = mkNullDefaultProp {
        #   type = boolEnumType [
        #     "aes-128-ccm" "aes-192-ccm" "aes-256-ccm" "aes-128-gcm" "aes-192-gcm" "aes-256-gcm"
        #   ];
        # };
        # options.keyformat = mkNullDefaultProp {
        #   type = with types; enum [
        #     "raw" "hex" "passphrase"
        #   ];
        # };
        # options.keylocation = mkNullDefaultProp {
        #   type = with types; either (enum [ "prompt" ]) path;
        # };
        options.exec = mkNullDefaultProp {
          type = boolStrType;
        };
        options.logbias = mkNullDefaultProp {
          type = with types; enum [ "latency" "throughput" ];
        };
        options.mountpoint = mkNullDefaultProp {
          type = with types; either (enum [ "none" "legacy" ]) path;
        };
        options.primarycache = mkNullDefaultProp {
          type = with types; enum [ "all" "none" "metadata" ];
        };
        options.quota = mkNullDefaultProp {
          type = with types; either (enum [ "none" ]) str;
        };
        options.recordsize = mkNullDefaultProp {
          type = with types; str;
        };
        options.refreservation = mkNullDefaultProp {
          type = with types; either (enum [ "none" "auto" ]) str;
        };
        options.relatime = mkNullDefaultProp {
          type = boolStrType;
        };
        options.reservation = mkNullDefaultProp {
          type = with types; either (enum [ "none" ]) str;
        };
        options.secondarycache = mkNullDefaultProp {
          type = with types; enum [ "all" "none" "metadata" ];
        };
        options.setuid = mkNullDefaultProp {
          type = boolStrType;
        };
        options.sync = mkNullDefaultProp {
          type = with types; enum [ "standard" "always" "disabled" ];
        };
        # TODO should only be configured for volume datasets, and can't be unset
        # options.volsize = mkNullDefaultProp {
        #   type = with types; str;
        # };
        options.xattr = mkNullDefaultProp {
          type = boolEnumType [ "sa" ];
        };
      };
    };
  });

  # Properties that have restrictions on un/setting them
  propertyRestrictions = {
    mountpoint = "unmounted";
  };
  restrictionCheck = dataset: prop: action: let
    checks = {
      unmounted = action: ''
        mounted=$(zfs get -H -o value mounted ${escapeShellArg dataset})
        if [[ $mounted != "yes" ]]; then
          ${action}
        else
          echo "WARNING: Not changing '${prop}' property; cannot be changed while dataset is mounted without a remount"
        fi
      '';
      setNone = action: ''
      '';
      unrestricted = action: action;
    };
  in checks.${propertyRestrictions.${prop} or "unrestricted"} action;

  # Properties that require something other than `zfs inherit` to default them
  propertyInheritActions = {
    quote = "setNone";
    refreservation = "setNone";
    reservation = "setNone";
  };
  inheritAction = dataset: prop: let
    actions = {
      setNone = ''
        zfs set ${escapeShellArg prop}=none ${escapeShellArg dataset}
      '';
      "inherit" = ''
        zfs inherit ${escapeShellArg prop} ${escapeShellArg dataset}
      '';
    };
  in actions.${propertyInheritActions.${prop} or "inherit"};
in
{
  options.disk.fileSystems.zfs.enable = mkEnableOption "declarative ZFS pool and dataset creation and configuration";
  # TODO option to implicitly pull in minimal pool/dataset specs from `config.fileSystems`
  options.disk.fileSystems.zfs.defineFromMounts = mkEnableOption "automatically defining dataset entries based on `fsType=zfs` `fileSystems` config items";
  options.disk.fileSystems.zfs.verbose = mkEnableOption "verbose log output";
  options.disk.fileSystems.zfs.dryRun = mkOption {
    type = with types; bool;
    default = false;
    internal = true;
    visible = false;
  };
  options.disk.fileSystems.zfs.pools = mkOption {
    default = {};
    description = ''
      Declaratively-specified ZFS pools and datasets.
    '';
    type = types.attrsOf zfsPoolType;
  };
  options.disk.fileSystems.zfs.finalPools = mkOption {
    type = types.attrsOf zfsPoolType;
    readOnly = true;
    internal = true;
    visible = false;
    description = ''
      Merged user-specified pool configuration + automatically-defined
      configuration from `fileSystems` items.
    '';
  };
  options.disk.fileSystems.zfs.reify-datasets = mkOption {
    type = types.path;
    readOnly = true; internal = true; visible = false;
  };
  options.disk.fileSystems.zfs.reify-all-dataset-properties = mkOption {
    type = types.path;
    readOnly = true; internal = true; visible = false;
  };
  options.disk.fileSystems.zfs.reify-dataset-properties-for = mkOption {
    type = with types; attrsOf path;
    readOnly = true; internal = true; visible = false;
  };
  # TODO implement zpool creation
  # TODO implement zpool property management
  config = mkIf cfg.enable (mkMerge [
    ({
      # finalPools includes:
      # - Explicitly configured pools + datasets
      # - Pools and datasets pulled from the `config.fileSystems` options, if
      #   `defineFromMounts` is enabled
      # - Implicitly-defined datasets (e.g. parent datasets of
      #   explicitly-defined child datasets)
      disk.fileSystems.zfs.finalPools = let
        basePools = (if !cfg.defineFromMounts
          then cfg.pools
          # Add in automatically-defined datasets from `fileSystems` config
          # items, replacing mountpoint with the fileSystems-sourced one if it
          # is not otherwise specified
          else let
            combineDsAttrs = sets: zipAttrsWith
              (name: vs: if isAttrs (head vs)
                then combineDsAttrs vs
                else if name == "mountpoint"
                  then findFirst (val: val != null) null vs
                  else head vs
              ) sets;
          in combineDsAttrs [(mapDsToPools mountpointForFsDs zfsFsDatasets) cfg.pools]);

        mountpointForFsDs = ds: let
          fsSpec = zfsFsByDataset.${ds};
        in {
          properties.mountpoint = if elem "zfsutil" fsSpec.options
            then fsSpec.mountPoint
            else "legacy";
        };
        mapDsToPools = dsUpdateFn: dsList:
          listToAttrs (flip map allPools (pool: nameValuePair
            pool
            {
              datasets = let
                poolFs = filter (ds: hasPrefix poolPrefix ds) dsList;
                poolPrefix = "${pool}/";
                prefixLen = stringLength poolPrefix;
              in listToAttrs (flip map poolFs (ds: nameValuePair
                (substring prefixLen (stringLength ds - prefixLen) ds)
                (dsUpdateFn ds)
              ));
            }
          ));

        # Includes all the datasets that aren't configured but are implied
        # based on configured child datasets
        # e.g. takes "ocvm-pool/ROOTS/nixos/tmp", generates: [
        #   "ocvm-pool/ROOTS/nixos/tmp"
        #   "ocvm-pool/ROOTS/nixos"
        #   "ocvm-pool/ROOTS"
        #   "ocvm-pool"
        # ]
        allDatasets = concatLists (flip map configuredDatasets (ds: let
          impliedDs = flip imap0 pathElems (i: e: concatStringsSep "/" (sublist 0 (pathLength - i) pathElems));
          pathElems = splitString "/" ds;
          pathLength = length pathElems;
        in impliedDs));
        configuredDatasets = let
          fsDatasets = map (fs: fs.device) zfsFilesystems;
          explicitDatsets = concatLists (
            flip mapAttrsToList cfg.pools (name: poolSpec: flip mapAttrsToList poolSpec.datasets (name: ds: if ds.path == ""
            then "${poolSpec.name}"
            else "${poolSpec.name}/${ds.path}"))
          );
        in unique (explicitDatsets ++ optionals cfg.defineFromMounts fsDatasets);
      in recursiveUpdate (mapDsToPools (ds: {}) allDatasets) basePools;
    })
    { # ZFS dataset creation
      disk.fileSystems.zfs.reify-datasets = bashBinScript "zfs-reify-datasets" ''
        set -e

        changed=0

        function debug_log() {
          if [[ $VERBOSE == 1 ]]; then
            echo DEBUG: "$@"
          fi
        }

        # Get set of extant pools
        declare -A pools
        while read -r pool; do
          debug_log "Existing pool: $pool"
          pools[$pool]=1
        done < <(zpool list -H -o name)

        # Get set of extant datasets
        declare -A datasets
        while read -r dataset; do
          debug_log "Existing dataset: $dataset"
          datasets[$dataset]=1
        done < <(zfs list -H -o name)

        # Ensure any missing, specified datasets are created
        for dataset in ${escapeShellArgs datasetList}; do
          debug_log "Checking for dataset $dataset"
          pool="''${dataset%%/*}"
          if ! [ ''${pools[$pool]+_} ]; then
            echo "Pool '$pool' has not been imported / not found!"
            exit 1
          fi
          if ! [ ''${datasets[$dataset]+_} ]; then
            # TODO Should set creation-time-only properties here, too
            echo "Creating dataset $dataset"
            $DRY_RUN_CMD zfs create "$dataset"
            changed=1
          fi
        done

        if [[ $changed == 0 ]]; then
          echo "All specified datasets already exist, no changes made"
        fi
      '';

      systemd.services.zfs-reify-datasets = rec {
        description = "Ensures declaratively-specified ZFS datasets exist";
        after = [ "zfs-import.target" ]; wants = after;
        before = [ "zfs-mount.service" "zfs.target" ] ++ (concatLists (map getDatasetMounts datasetList));
        wantedBy = before;
        path = with pkgs; [
          bash cfgZfs.package
        ];
        environment.VERBOSE = if cfg.verbose then "1" else "0";
        environment.DRY_RUN_CMD = if cfg.dryRun then "echo" else "";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = cfg.reify-datasets.binPath;
        };
        unitConfig.DefaultDependencies = "no";
      };
    }
    { # ZFS dataset property management
      disk.fileSystems.zfs.reify-dataset-properties-for = flip mapAttrs datasetAttrs (datasetPath: datasetSpec: let
        dataset = datasetSpec.path;
        inheritPropsList = flip mapAttrsToList inheritProps (prop: _: prop);
        inheritProps = flip filterAttrs datasetSpec.properties (_: val: val == null);

        setPropsList = flip mapAttrsToList setProps (prop: val: "${prop}=${val}");
        setPropsAttrsList = mapAttrsToList nameValuePair setProps;
        setProps =  flip filterAttrs datasetSpec.properties (_: val: val != null);
      in bashBinScript "zfs-reify-dataset-properties-${escapePathForName dataset}" ''
        set -e

        changed=0

        function debug_log() {
          if [[ $VERBOSE == 1 ]]; then
            echo DEBUG: "$@"
          fi
        }

        ${optionalString (inheritPropsList != []) ''
        # Default/un-set/inherit propreties that have a 'null'
        # declaratively-specified value, if not already done
        ${flip concatMapStrings inheritPropsList (name: ''
        debug_log "Checking if property ${escapeShellArg name} is default..."
        source=$(zfs get -H -o source ${escapeShellArg name} ${escapeShellArg dataset})
        if [[ $source != inherit* ]] && [[ $source != "default" ]]; then
          ${restrictionCheck dataset name ''
          echo "Inheriting/defaulting property" ${escapeShellArg name}
          $DRY_RUN_CMD ${inheritAction dataset name}
          changed=1
          ''}
        fi
        '')}
        ''}

        ${optionalString (setPropsList != []) ''
        # Set properties that have a non-null declaratively-specified value
        ${flip concatMapStrings setPropsAttrsList ({name, value}: ''
        debug_log "Checking if property ${escapeShellArg name} is set to ${escapeShellArg value}..."
        # TODO Account for zpool 'altroot' property's interaction with
        # per-dataset mountpoint property value?
        source=$(zfs get -H -o source ${escapeShellArg name} ${escapeShellArg dataset})
        value=$(zfs get -H -o value ${escapeShellArg name} ${escapeShellArg dataset})
        if [[ $source != "local" ]] || [[ $value != ${escapeShellArg value} ]]; then
          ${restrictionCheck dataset name ''
          echo "Setting property ${escapeShellArg name}=${escapeShellArg value}"
          $DRY_RUN_CMD zfs set ${escapeShellArg name}=${escapeShellArg value} ${escapeShellArg dataset}
          changed=1
          ''}
        fi
        '')}

        if [[ $changed == 0 ]]; then
          echo "Dataset properties already match specification, no changes made"
        fi
        ''}
      '');

      disk.fileSystems.zfs.reify-all-dataset-properties = bashBinScript "zfs-reify-all-dataset-properties" ''
        ${concatMapStringsSep "\n" (drv: drv.binPath) (attrValues cfg.reify-dataset-properties-for)}
      '';

      systemd.services = flip mapAttrs' datasetAttrs (datasetPath: datasetSpec: let
        dataset = datasetSpec.path;
      in nameValuePair
        "zfs-reify-dataset-properties-${escapeSystemdPath dataset}"
        rec {
          description = "Ensures declaratively-specified ZFS dataset properties are configured";
          after = [ "zfs-reify-datasets.service" ]; wants = after;
          before = [ "zfs-mount.service" "zfs.target" ] ++ getDatasetMounts dataset;
          wantedBy = before;
          path = with pkgs; [
            bash cfgZfs.package gnugrep
          ];
          environment.VERBOSE = if cfg.verbose then "1" else "0";
          environment.DRY_RUN_CMD = if cfg.dryRun then "echo" else "";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = cfg.reify-dataset-properties-for.${datasetPath}.binPath;
          };
          unitConfig.DefaultDependencies = "no";
        }
      );
    }
  ]);
}
