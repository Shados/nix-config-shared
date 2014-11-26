{ config, pkgs, ... }:
{
  # Default to OpenDNS nameservers
  networking.nameservers = pkgs.lib.mkDefault [
    "208.67.220.220"
    "208.67.222.222"
  ];
}
