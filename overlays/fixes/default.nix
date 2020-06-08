{ config, lib, ... }:

{
  imports = [
  ];

  # Contains temporary fixes or updates for various bugs/packages, each should
  # be removed once nixos-unstable has them
  config = lib.mkMerge [
    # Workaround for https://github.com/NixOS/nixpkgs/issues/44426 python
    # overrides not being composable...
    {
      nixpkgs.overlays = lib.mkBefore [
        (self: super: let
            pyNames = [
              "python27" "python35" "python36" "python37"
              "pypy"
            ];
            overriddenPython = name: [
              { inherit name; value = super.${name}.override { packageOverrides = self.pythonOverrides; }; }
              { name = "${name}Packages"; value = super.recurseIntoAttrs self.${name}.pkgs; }
            ];
            overriddenPythons = builtins.concatLists (map overriddenPython pyNames);
          in {
            pythonOverrides = pyself: pysuper: {};
            sn = (super.sn or { }) // {
              # The below is a straight wrapper for clarity of intent, use like:
              # pythonOverrides = buildPythonOverrides (pyself: pysuper: { ... # overrides }) super.pythonOverrides;
              buildPythonOverrides = newOverrides: currentOverrides: super.lib.composeExtensions newOverrides currentOverrides;
            };
          } // builtins.listToAttrs overriddenPythons
        )
      ];
    }
    {
      nixpkgs.overlays = [
        (self: super: with super.lib; {
          # Get cython working with python 3.7
          pythonOverrides = super.sn.buildPythonOverrides (pyself: pysuper: let
            fixedCython = pysuper.cython.overrideAttrs(oldAttrs: rec {
              inherit (oldAttrs) pname;
              name = "${pname}-${version}";
              version = "0.28.5";

              src = pysuper.fetchPypi {
                inherit pname version;
                sha256 = "b64575241f64f6ec005a4d4137339fb0ba5e156e826db2fdb5f458060d9979e0";
              };

              patches = [
                (super.fetchpatch {
                  name = "Cython-fix-test-py3.7.patch";
                  url = https://github.com/cython/cython/commit/eae37760bfbe19e7469aa41269480b84ce12b6cd.patch;
                  sha256 = "0irk53psrs05kzzlvbfv7s3q02x5lsnk5qrv0zd1ra3mw2sfyym6";
                })
              ];
            });
          in {
            cython = if (versionOlder (getVersion pysuper.cython) "0.28.5")
              then fixedCython
              else pysuper.cython;
          }) super.pythonOverrides;
          # Patch spurious O_TMPFILE logging in older xorg
          xorg = super.xorg // {
            xorgserver = let
              fixedXorgserver = super.xorg.xorgserver.overrideAttrs(oldAttrs: {
                patches = oldAttrs.patches or [] ++ [
                  ./xorg-tmpfile.patch
                ];
              });
            in if (versionOlder (getVersion super.xorg.xorgserver) "1.20")
              then fixedXorgserver
              else super.xorg.xorgserver;
          };
          # Use mosh newer than 1.3.2 to get proper truecolor support
          mosh = if versionAtLeast (getVersion super.mosh) "1.3.3"
            then super.mosh
            else super.mosh.overrideAttrs (oldAttrs: rec {
                name = "${pname}-${version}";
                pname = "mosh";
                version = "unstable-2018-08-30";
                src = super.fetchFromGitHub {
                  owner = "mobile-shell"; repo = pname;
                  rev = "944fd6c796338235c4f3d8daf4959ff658f12760";
                  sha256 = "0fwrdqizwnn0kmf8bvlz334va526mlbm1kas9fif0jmvl1q11ayv";
                };
                patches = [
                  (<nixpkgs/pkgs/tools/networking/mosh/ssh_path.patch>)
                  (<nixpkgs/pkgs/tools/networking/mosh/utempter_path.patch>)
                  (<nixpkgs/pkgs/tools/networking/mosh/bash_completion_datadir.patch>)
                ];
              });
          monero = if versionOlder (getVersion super.monero) "0.14.0.2"
            then super.monero.overrideAttrs (oldAttrs: rec {
                name = "monero-${version}";
                version = "0.14.0.2";
                src = super.fetchgit {
                url = "https://github.com/monero-project/monero.git";
                rev = "v${version}";
                sha256 = "1471iy6c8dfdqcmcwcp0m7fp9xl74dcm5hqlfdfi217abhawfs8k";
              };
              buildInputs = oldAttrs.buildInputs or [] ++ singleton super.libsodium;
            })
            else super.monero;
          # Remove once we have upstream fix from https://github.com/pimutils/vdirsyncer/pull/788
          vdirsyncer = super.vdirsyncer.overrideAttrs (oldAttrs: rec {
            patches = oldAttrs.patches or [] ++ [
              (super.fetchpatch {
                url = https://github.com/pimutils/vdirsyncer/pull/788.patch;
                sha256 = "0vl942ii5iad47y63v0ngmhfp37n30nxyk4j7h64b95fk38vfwx9";
              })
            ];
          });
          adb-sync = super.adb-sync.overrideAttrs (oa: rec {
            name = "${pname}-${version}";
            pname = "adb-sync";
            version = "unstable-2019-01-02";
            src = super.fetchFromGitHub {
              owner = "google"; repo = "adb-sync";
              rev = "fb7c549753de7a5579ed3400dd9f8ac71f7bf1b1";
              sha256 = "1kfpdqs8lmnh144jcm1qmfnmigzrbrz5lvwvqqb7021b2jlf69cl";
            };
          });
        })
        # Fixes nixpkgs#53492; remove after nixpkgs#53505 merged
        (self: super: with super.lib; {
          pythonOverrides = super.sn.buildPythonOverrides (pyself: pysuper: {
            kaptan = if versionAtLeast (getVersion pysuper.kaptan) "0.5.11"
              then pysuper.kaptan
              else pysuper.kaptan.overridePythonAttrs (oldAttrs: rec {
                inherit (oldAttrs) pname;
                version = "0.5.11";

                src = pysuper.fetchPypi {
                  inherit pname version;
                  sha256 = "8403d6e48200c3f49cb6d6b3dcb5898aa5ab9d820831655bf9a2403e00cd4207";
                };

                doCheck = false;
              });
          }) super.pythonOverrides;

          tmuxp = if versionAtLeast (getVersion super.tmuxp) "1.5.0a1"
            then super.tmuxp
            else super.tmuxp.overrideAttrs (oldAttrs: rec {
              inherit (oldAttrs) pname;
              name = "${pname}-${version}";
              version = "1.5.0a1";

              src = super.pythonPackages.fetchPypi {
                inherit pname version;
                sha256 = "88b6ece3ff59a0882b5c5bff169cc4c1d688161fe61e5553b0a0802ff64b6da8";
              };
            });
        })
        (self: super: with super.lib; {
          # Workaround for nixpkgs#67601
          powerdns = let
            nixpkgs = import (builtins.fetchGit {
              url = https://github.com/NixOS/nixpkgs;
              ref = "master";
              rev = "084fcf09e3c1ea6633c72824bfe0c95c1056f7bd";
            }) { };
          in nixpkgs.powerdns;
          # Backport nixpkgs#86115
          arc-theme = if (getVersion super.arc-theme) != "20190917" then super.arc-theme else super.arc-theme.overrideAttrs(oa: {
            version = "20200416";
            src = super.fetchFromGitHub {
              owner = "jnsh"; repo = oa.pname;
              rev = "0779e1ca84141d8b443cf3e60b85307a145169b6";
              sha256 = "1ddyi8g4rkd4mxadjvl66wc0lxpa4qdr98nbbhm5abaqfs2yldd4";
            };
            configureFlags = oa.configureFlags ++ [
              "--disable-cinnamon"
            ];
            meta = oa.meta // {
              broken = false;
            };
          });
        })
      ];
    }
  ];
}
