{ config, pkgs, ... }:

pkgs.lib.mkIf config.services.samba.enable {
  # TODO: Config!
  # TODO: Make services.samba generate the password file
  services.samba = {
    extraConfig = ''
    '';
  };
}
