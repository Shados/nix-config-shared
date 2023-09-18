{ config, inputs, lib, pkgs, ... }:
{
  nixpkgs.overlays = [
    # TODO: Remove once 0.7.1 is in nixpkgs
    (self: super:  let
      inherit (super.lib) getVersion versionAtLeast;
      pkgSrc = super.fetchurl {
        url = "https://raw.githubusercontent.com/NixOS/nixpkgs/408edc6bd89c07b549c93e939232e0ebfba8aabe/pkgs/tools/misc/vial/default.nix";
        sha256 = "0ragkiv6y5x4pm84l52pidi7816f0slx0jvz125cm1fbfsblk9ah";
      };
    in {
      vial = if versionAtLeast (getVersion super.vial) "0.7.1"
        then super.vial
        else super.callPackage pkgSrc { };
    })
  ];
}
