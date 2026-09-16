{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types literalExpression;
in
{
  options.boot.loader.uboot = {
    package = mkOption {
      type = with types; package;
      default = pkgs.callPackage ./uboot-package.nix { };
      example = literalExpression "pkgs.ubootRaspberryPiAarch64";
      description = ''
        Package containing the u-boot build to deploy.
      '';
    };
    fileToFlash = mkOption {
      type = with types; str;
      default = "u-boot-rockchip.bin";
      description = ''
        The file to flash from the u-boot package.
      '';
    };
  };
}
