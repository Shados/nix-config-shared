{ config, pkgs, lib, ... }:

with lib;

{
  imports = [
  ];

  # Contains temporary fixes or updates for various bugs/packages, each should
  # be removed once nixos-unstable has them
  config = mkMerge [
    # 2018-03-21: recent versions of deoplete need python-neovim >= 0.2.4
    # TODO remove after commmit 366c79e17f212e581d16a17ca67eb186fd005c61 is in channel
    {
      nixpkgs.config.packageOverrides = pkgs: with pkgs; {
        neovim = let
          newer_python_neovim = packages: rec {
            pname = "neovim";
            version = "0.2.4";
            src = packages.fetchPypi {
              inherit pname version;
              sha256 = "0accfgyvihs08bwapgakx6w93p4vbrq2448n2z6gw88m2hja9jm3";
            };
          };
          fixedPython3 = pkgs.python3.override {
            packageOverrides = self: super: {
              neovim = super.neovim.overrideAttrs (oldAttrs: newer_python_neovim super);
            };
          };
          fixedPython2 = pkgs.python2.override {
            packageOverrides = self: super: {
              neovim = super.neovim.overrideAttrs (oldAttrs: newer_python_neovim super);
            };
          };
          wrapNeovim = pkgs.wrapNeovim.override {
            pythonPackages = fixedPython2.pkgs;
            python3Packages = fixedPython3.pkgs;
          };
        in wrapNeovim pkgs.neovim-unwrapped { };
      };
    }
  ];
}
