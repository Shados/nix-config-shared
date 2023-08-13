{ config, lib, inputs, pkgs, ... }:
let
  inherit (lib) mkIf mkMerge mkOption singleton types;
  inherit (inputs.lib.fs) dsToBootFs dsToFs pristineSnapshot;
in
{
  options = {
    sn.statelessRoot = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether or not to use the impermanence flake to enforce a stateless root filesystem.
      '';
    };
    sn.statelessRootPool = mkOption {
      type = with types; nullOr str;
      default = null;
      description = ''
        If root is hosted on a ZFS pool, this must be set to the name of the
        pool.
      '';
    };
    sn.statelessRootDataset = mkOption {
      type = with types; str;
      default = "ROOTS/nixos";
      description = ''
        If root is hosted on a ZFS pool, this must be set to the path to the
        dataset which should contain this NixOS installation, which I'll call
        the 'abstract root'. You must also set `sn.statelessRootPool` in order
        for this to function.

        Preconditions on the abstract root:
        - `mountpoint` property must be `none`; the abstract root dataset is
          not the *actual* root and is instead used as a container for a single
          NixOS system's system-level datasets
        - The `/root` sub-dataset must exist, have `mountpoint=/`, and have a
          snapshot called `${pristineSnapshot}` with absolutely no
          contents, to facilitate fast reset to that blank state on each boot.
        - The `/tmp` sub-dataset must exist, have `mountpoint=/tmp`, and have a
          snapshot called `${pristineSnapshot}` with absolutely no
          contents, to facilitate fast reset to that blank state on each boot.
        - The `/nix` sub-dataset must exist and have `mountpoint=/nix`, to
          contain the Nix store

        Note that this module does not persist `/home`, so unless user home(s)
        are on a separate dataset or filesystem, they will be ephemeral.
      '';
    };
  };
  config = mkIf config.sn.statelessRoot (mkMerge [
    # Default, baseline config
    {
      environment.persistence."/nix/persist" = {
        hideMounts = true;
        directories = [
          "/var/cron"
          "/var/lib"
          "/var/log"
        ];
        files = [
          "/etc/machine-id"
          "/etc/adjtime"
          "/etc/zfs/zpool.cache"
        ];
      };
      # Rather than persisting the file
      # TODO maybe move this to general config?
      security.sudo.extraConfig = ''
        Defaults lecture = never
      '';
    }
    # ZFS-backed setup
    (mkIf (config.sn.statelessRootPool != null) (let
      rpool = config.sn.statelessRootPool;
      abstractRoot = "${rpool}/${config.sn.statelessRootDataset}";
    in {
      fileSystems = {
        "/nix/persist" = dsToBootFs "${abstractRoot}/nix/persist";
        "/nix/persist/etc" = dsToBootFs "${abstractRoot}/nix/persist/etc";
        "/nix/persist/var" = dsToBootFs "${abstractRoot}/nix/persist/var";
        "/nix/persist/var/lib" = dsToBootFs "${abstractRoot}/nix/persist/var/lib";
        "/nix/persist/var/log" = dsToBootFs "${abstractRoot}/nix/persist/var/log";
      };
    }))
    # Integrations with various other modules
    (mkIf (config.boot.initrd.storeSecrets != {}) {
      environment.persistence."/nix/persist".directories = singleton config.boot.initrd.secretsDir;
    })
    (mkIf config.services.openssh.enable {
      environment.persistence."/nix/persist".files = [
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
    })
    (mkIf config.networking.networkmanager.enable {
      environment.persistence."/nix/persist".directories = singleton "/etc/NetworkManager/system-connections";
    })
  ]);
}
