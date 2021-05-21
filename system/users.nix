{ config, pkgs, ... }:

{
  users.mutableUsers = false;
  users.users.shados = {
    isNormalUser = true;
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
    shell = pkgs.fish;
    openssh.authorizedKeys.keyFiles = [
      "/etc/nixos/modules/keys/shados@nhnt.shados.net.id_ecdsa.pub"
      "/etc/nixos/modules/keys/shados@sn-u1-malkieri.id_ecdsa.pub"
    ];
    passwordFile = "/etc/nixos/modules/passwords/shados";
    linger = true;
  };
  users.users.root = {
    linger = true;
    initialHashedPassword = "$6$t6l9e3mAk$rohvE4HsBPPbsy1pQmtZSVvYUX0Gjl.seA/h6xYiKHc5ZSug0HAe/4F1EDq8XO.7aRrnfv2f9eDMf4kGKIDQ6/";
  };

  services.openssh.allowed_users = [ "shados" ];
  environment.systemPackages = with pkgs; [
    bashInteractive # issue #4260
  ];
}
