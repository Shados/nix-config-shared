{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) singleton;
in
{
  nixpkgs.overlays = singleton (
    self: super: {
      roc-toolkit-unstable = super.callPackage ./roc-toolkit.nix {
        openfec = super.callPackage ./openfec.nix { };
      };
      samrewritten = super.callPackage ./samrewritten.nix { };
    }
  );
}
