# Security-focused modules and defaults
{ config, pkgs, ... }:

{
  imports = [
    ./firewall.nix
    ./nft-firewall-module.nix
  ];

  security.pam.loginLimits = [
    { domain = "*"; type = "-"; item = "rtprio"; value = "0"; }
    { domain = "*"; type = "-"; item = "nice"; value = "0"; }
    { domain = "*"; type = "-"; item = "nproc"; value = "10240"; }
    { domain = "*"; type = "-"; item = "nofile"; value = "524288"; }
    { domain = "@audio"; item = "nofile"; type = "soft"; value = "524288"; }
    { domain = "@audio"; item = "nofile"; type = "hard"; value = "524288"; }
    { domain = "@audio"; type = "-"; item = "memlock"; value = "unlimited"; }
    { domain = "@audio"; type = "-"; item = "rtprio"; value = "99"; }
    { domain = "@audio"; type = "-"; item = "nice"; value = "-20"; }
  ];
}
