{ config, inputs, lib, pkgs, ... }:
{
  nixpkgs.overlays = [
    (self: super: {
      libsForQt5 = super.libsForQt5 // {
        sddm = super.libsForQt5.sddm.overrideAttrs(oa: {
          patches = [
            (super.fetchpatch {
              url = "https://github.com/sddm/sddm/pull/1805.patch";
              sha256 = "0zqdzq9c5cd1isyh1095rn8qjsm0rwgslg120p3lnpvk4r1azhks";
            })
          ];
        });
      };
    })
  ];
}
