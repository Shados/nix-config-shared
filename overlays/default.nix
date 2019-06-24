# Overlays; this can safely be imported for usage in standalone (non-NixOS)
# nixpkgs-in-module usages (e.g. in home-manager, or direct evalModules)
{ config, lib, ... }:
{
  imports = [
    # Temporary fixes that have yet to hit nixos-unstable channel
    ./fixes
    # Re-usable library functions that don't necessarily fit anywhere else
    ./lib
  ];
}
