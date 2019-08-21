{ config, lib, pkgs, ... }:

with lib;
let
  lingerDir = "/var/lib/systemd/linger";
in
{
  options = {
    users.users = mkOption {
      options = [{
        linger = mkOption {
          type = with types; enum [ true false "imperative" ];
          default = false;
          description = ''
            Whether to declaratively enable or disable loginctl lingering for
            the user, or allow it to be managed imperatively instead.

            Possible values:
            - true
            - false
            - "imperative"
          '';
        };
      }];
    };
  };

  config = {
    # Fix for https://github.com/systemd/systemd/issues/12401
    systemd.services.systemd-logind.serviceConfig.StateDirectory = mkDefault "systemd/linger";

    system.activationScripts.updateLingering = stringAfter [ "users" ] (let
      allUsers = map (u: u.name) (builtins.attrValues config.users.users);
      lingeringUsers =  map (u: u.name) (builtins.attrValues (filterAttrs (name: user: user.linger == true) config.users.users));
      ephemeralUsers =  map (u: u.name) (builtins.attrValues (filterAttrs (name: user: user.linger == false) config.users.users));
    in ''
      # Skip if the system isn't running (e.g. during nixos-install)
      if [[ -e /run/booted-system ]]; then
        if ! [[ -e ${lingerDir} ]]; then
          mkdir -p ${lingerDir}
        fi

        ${optionalString (! config.users.mutableUsers) ''
        # Disable lingering for any users not in users.users
        declare -A usernames=( ${concatMapStringsSep " " (name: "[${name}]=1") allUsers} )
        for file in ${lingerDir}/*; do
          name=$(basename $file)
          if ! [[ ''${usernames[$name]} ]]; then
            echo "disabling lingering for unmanaged user $name..."
            ${pkgs.systemd}/bin/loginctl disable-linger $name
          fi
        done

        ''}
        # Disable lingering for any users with linger = false
        for name in ${concatStringsSep " " ephemeralUsers}; do
          if [[ -e ${lingerDir}/$name ]]; then
            echo "disabling lingering for user $name..."
            ${pkgs.systemd}/bin/loginctl disable-linger $name
          fi
        done

        # Enable lingering for any users with linger = true
        for name in ${concatStringsSep " " lingeringUsers}; do
          if ! [[ -e ${lingerDir}/$name ]]; then
            echo "enabling lingering for user $name..."
            ${pkgs.systemd}/bin/loginctl enable-linger $name
          fi
        done
      fi
    '');
  };
}
