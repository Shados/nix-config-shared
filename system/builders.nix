{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.sn.builders;
  nodeOpts = {
    options = {
      address = mkOption {
        type = with types; str;
        description = ''
          IP address or hostname of the builder node.
        '';
      };
      sshKeyFile = mkOption {
        type = with types; str;
        description = ''
          Path to the ssh key used to access the builder node.
        '';
      };
      sshHostPubKey = mkOption {
        type = with types; str;
        description = ''
          A string represneting the public ssh host key for the builder node.
        '';
      };
      machineSpec = mkOption {
        type = with types; attrs;
        default = {};
        description = ''
          Attributes to merge into the configured `nix.buildMachines` option
          for this builder node.
        '';
      };
    };
  };

  mkSshHostName = name: "${name}-builder";
  sshUser = "nix-builder";
  sshPort = 54201;
in
{
  options = {
    sn.builders = {
      enable = mkEnableOption "remote builder node configuration";

      nodes = mkOption {
        type = with types; attrsOf (submodule nodeOpts);
        default = {};
        description = ''
          Attribute set of builder nodes.
        '';
        example = {
          hephaestus = {
            address = "192.168.16.3";
            sshKeyFile = "/etc/nixos/private-keys/nix-builder.id_ed25519";
            machineSpec = {
              system = "x86_64-linux";
              maxJobs = 8;
              speedFactor = 2;
              supportedFeatures = [
                "kvm" "nixos-test" "big-parallel"
              ];
            };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge (
    # Global config
    singleton {
      nix.distributedBuilds = true;
      nix.extraOptions = ''
        builders-use-substitutes = true
      '';
    }
    ++
    # Per-builder config
    singleton {
      nix.buildMachines = mapAttrsToList (name: node: {
        hostName = mkSshHostName name;
        inherit sshUser;
        sshKey = node.sshKeyFile;
      } // node.machineSpec) cfg.nodes;
      programs.ssh.globalHosts = mapAttrs' (name: node: nameValuePair
        (mkSshHostName name)
        { hostName = node.address;
          user = sshUser;
          port = sshPort;
          keyFile = node.sshKeyFile;
        }
      ) cfg.nodes;
      programs.ssh.knownHosts = mapAttrs' (name: node: nameValuePair
        (mkSshHostName name)
        { hostNames = singleton node.address;
          publicKey = node.sshHostPubKey;
        }
      ) cfg.nodes;
    }
  ));
}
