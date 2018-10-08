{ config, pkgs, lib, ... }:

{
  imports = [
  ];

  # Contains temporary fixes or updates for various bugs/packages, each should
  # be removed once nixos-unstable has them
  config = lib.mkMerge [
    # 2018-03-21: recent versions of deoplete need python-neovim >= 0.2.4
    # TODO remove after commmit 366c79e17f212e581d16a17ca67eb186fd005c61 is in channel
    {
      nixpkgs.config.packageOverrides = let
        python_override = localpython: localpython.override {
          packageOverrides = self: super: {
            neovim = super.neovim.overrideAttrs (oldAttrs: rec {
              pname = "neovim";
              version = "0.2.4";
              src = super.fetchPypi {
                inherit pname version;
                sha256 = "0accfgyvihs08bwapgakx6w93p4vbrq2448n2z6gw88m2hja9jm3";
              };
            });
          };
        };
        fixedWrapNeovim = pkgs.wrapNeovim.override {
          pythonPackages = (python_override pkgs.python2).pkgs;
          python3Packages = (python_override pkgs.python3).pkgs;
        };
      in pkgs: with pkgs.lib; {
        neovim = if (versionOlder (getVersion pkgs.pythonPackages.neovim) "0.2.4") then
          fixedWrapNeovim pkgs.neovim-unwrapped { }
        else
          pkgs.neovim;
      };
    }
    # Workaround for https://github.com/NixOS/nixpkgs/issues/44426 python
    # overrides not being composable...
    {
      nixpkgs.overlays = lib.mkBefore [
        (self: super: let
          pyNames = [
            "python27" "python34" "python35" "python36" "python37"
            "pypy"
          ];
          overriddenPython = name: [
            { inherit name; value = super.${name}.override { packageOverrides = self.pythonOverrides; }; }
            { name = "${name}Packages"; value = super.recurseIntoAttrs self.${name}.pkgs; }
          ];
          overriddenPythons = builtins.concatLists (map overriddenPython pyNames);
        in {
          pythonOverrides = pyself: pysuper: {};
          # The below is a straight wrapper for clarity of intent, use like:
          # pythonOverrides = buildPythonOverrides (pyself: pysuper: { ... # overrides }) super.pythonOverrides;
          buildPythonOverrides = newOverrides: currentOverrides: super.lib.composeExtensions newOverrides currentOverrides;
        } // builtins.listToAttrs overriddenPythons)
      ];
    }
  ];
}
