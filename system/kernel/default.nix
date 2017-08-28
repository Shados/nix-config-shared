# This shit is all hugely old, I should probably remove it. Although muqss/bfs is rather nice.
{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.fragments.kernel;
in

{
  imports = [
    ./ck.nix 
  ];

  options = {
    fragments.kernel = {
      ck = mkOption {
        description = ''
          Whether or not to enable the ck and the bfq patchesets.
        '';
        default = false;
        type = types.bool;
      };
    };
  };

  # If ck or any other patches are enabled, we need to be working against a fixed kernel version
  config = lib.mkIf (cfg.ck) {
    boot.kernelPackages = pkgs.linuxPackages_4_3;
  };
}
