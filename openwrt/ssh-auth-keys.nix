# TODO implement sharedConfig
{ config, lib, pkgs, sharedConfig, ... }:
let
  inherit (lib) concatMapStringsSep escapeShellArg;

  fileTree = pkgs.runCommandNoCCLocal "openwrt-baseline-filetree" { } ''
    mkdir -p $out

    echo "Adding authorized SSH keys"
    mkdir -p $out/etc/dropbear/
    ${concatMapStringsSep "\n" (key: ''
      echo ${escapeShellArg key} >> $out/etc/dropbear/authorized_keys
    '') sharedConfig.authorizedKeys}
  '';
in
{
  fileTrees = [
  ];
}
