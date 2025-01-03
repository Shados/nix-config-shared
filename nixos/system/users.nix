{ config, lib, pkgs, ... }:
let
  inherit (lib) optional;
in
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
      "audio"
      "plugdev"
      ]
      ++ optional config.networking.networkmanager.enable "networkmanager"
      ++ optional config.virtualisation.libvirtd.enable "libvirtd"
      ++ optional config.programs.adb.enable "adbusers"
      ++ optional config.programs.gamemode.enable "gamemode"
      ++ optional config.hardware.uinput.enable "uinput"
      ++ optional config.virtualisation.docker.enable "docker"
    ;
    uid = 1000;
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIINIKAv4lnPlhX68cMsoAxpD1bnkU2i6owlQ6Xx6Cx9E shados@dreamlogic"
    ];
    hashedPassword = "$6$WccM6haN$4ogyI4b1MPv1bSEpuOhh1kVsyyMXiT9a1P3fUNfT1/noyS7OY4V676c.v9GVSotJdxr3gnts8mxAIx.d1xNhE/";
    linger = true;
  };
  users.users.root = {
    linger = true;
    hashedPassword = "$6$t6l9e3mAk$rohvE4HsBPPbsy1pQmtZSVvYUX0Gjl.seA/h6xYiKHc5ZSug0HAe/4F1EDq8XO.7aRrnfv2f9eDMf4kGKIDQ6/";
  };

  services.openssh.settings.AllowUsers = [ "shados" ];
  environment.systemPackages = with pkgs; [
    bashInteractive # issue #4260
  ];
}
