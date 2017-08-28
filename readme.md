# ShadosNet Generic NixOS Baseline Configuration
Contains various defaults I want, and NixOS packages/modules/extensions to existing modules (that aren't suitable for upstreaming). My individual systems generally have their own (private) repo for `/etc/nixos` that has this as a submodule.

Should be mostly self-documenting. Start with `default.nix`, of course. I'm aware I have (salted and hashed) passwords in the open, but using them requires you either have my SSH keys or access to my physical hardware (and the ability to generated SHA-512 collisions), in which case you can already screw me over.

License for my content herein is, as per the `LICENSE` file, 2-clause BSD. Some files are or contain content from others, they contain information on their licensing and/or attribution.

## Example Usage
`/etc/nixos/configuration.nix`:
```
{ config, pkgs, ... }:
{
  imports = [
    ./modules
    ./hardware
  ];

  system.stateVersion = "17.03";

  networking.hostName = "example.shados.net";

  services = {
    quassel.enable = true;
    postgresql.enable = true;
    nginx.enable = true;
    postgresqlBackup = {
      enable = true;
      databases = [ "postgres" "quassel" ];
      location = "/srv/backup/postgresql";
      period = "00 04 * * *";
    };
  };

  sn.backup = {
    enable = true;
    folders = [
      "/etc/nixos"
      "/srv/backup"
      "/srv/http"
      "/srv/quassel"
    ];
  };
}
```
