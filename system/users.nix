{ config, pkgs, ... }:

{
  users.mutableUsers = false;
  users.users.shados = {
    createHome = true;
    home = "/home/shados";
    description = "Alexei Robyn";
    extraGroups = [
      "wheel"
      "adm"
      "users"
      "systemd-journal"
      "grsecurity"
    ];
    uid = 1000;
    shell = "/run/current-system/sw/bin/fish";
    openssh.authorizedKeys.keyFiles = [
      "/etc/nixos/modules/keys/shados@nhnt.shados.net.id_ecdsa.pub"
      "/etc/nixos/modules/keys/shados@sn-u1-malkieri.id_ecdsa.pub"
    ];
    passwordFile = "/etc/nixos/modules/passwords/shados";
    linger = true;
  };
  security.initialRootPassword = "$6$t6l9e3mAk$rohvE4HsBPPbsy1pQmtZSVvYUX0Gjl.seA/h6xYiKHc5ZSug0HAe/4F1EDq8XO.7aRrnfv2f9eDMf4kGKIDQ6/";
  services.openssh.allowed_users = [ "shados" ];
  programs.fish = {
    enable = true;
    #shellInit = ''
      #source $HOME/.config/fish/config.fish
    #'';
  };
  environment.systemPackages = with pkgs; [
    which # Fish doesn't have `which` by default
    bashInteractive # issue #4260
  ];
}
