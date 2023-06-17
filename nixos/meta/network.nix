{ config, lib, pkgs, ... }:
with lib;
{
  options = {
    registry.network = mkOption {
      type = with types; attrsOf (submodule ({ name, ... }: {
        options = {
          name = mkOption {
            type = str;
            description = ''
              The registry name of this network entity. If unspecified, defaults
              to the name of the attribute set containing this definition.
            '';
            default = name;
          };
          mac = mkOption {
            type = nullOr str; # TODO checked type
            description = "The MAC address of this network entity.";
            default = null;
          };
          ipv4 = mkOption {
            type = str; # TODO checked type
            description = "The IP address of this network entity.";
          };
        };
      }));
      default = {};
      description = ''
        An internal registry of names to network information, to be used by
        other modules.
      '';
    };
  };
}
