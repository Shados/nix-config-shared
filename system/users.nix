{ config, pkgs, ... }:

{
  users.mutableUsers = false;
  users.extraUsers.shados = {
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
    useDefaultShell = true;
    openssh.authorizedKeys.keyFiles = [ 
      "/etc/nixos/modules/keys/shados@nhnt.shados.net.id_ecdsa.pub"
      "/etc/nixos/modules/keys/shados@sn-u1-malkieri.id_ecdsa.pub"
    ];
    passwordFile = "/etc/nixos/modules/passwords/shados";
  };
  security.initialRootPassword = "$6$t6l9e3mAk$rohvE4HsBPPbsy1pQmtZSVvYUX0Gjl.seA/h6xYiKHc5ZSug0HAe/4F1EDq8XO.7aRrnfv2f9eDMf4kGKIDQ6/";
}
