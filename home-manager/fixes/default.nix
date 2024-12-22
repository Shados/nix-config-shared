{ config, inputs, lib, pkgs, ... }:
let
  inherit (lib) getVersion versionAtLeast;
in
{
  nixpkgs.overlays = [
    (self: super: {
      # Backport sd-switch for RefuseManualStart/Stop fix
      sd-switch = let
        version = "0.5.3";
        src = super.fetchFromSourcehut {
          owner = "~rycee";
          repo = "sd-switch";
          rev = version;
          hash = "sha256-9aIu37mmf4ZnmZZrU0GA6z+bHKwtfkA5KnLRLY0c2r8=";
        };
      in if versionAtLeast (getVersion super.sd-switch) version then super.sd-switch else
        (super.sd-switch.overrideAttrs(finalAttrs: prevArgs: {
          inherit src version;
        })).override(prevArgs: rec {
          rustPlatform = prevArgs.rustPlatform // {
            buildRustPackage = args: prevArgs.rustPlatform.buildRustPackage (args // {
              name = "sd-switch-${version}";
              inherit src;
              cargoHash = "sha256-3XolxgnTIySucopogAzgf13IUCguJE6W17q506tUF6U=";
            });
          };
        });
    })
  ];
}
