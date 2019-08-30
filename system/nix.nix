{ config, lib, pkgs, ... }:
with lib;
let
  nix-fetchers = builtins.fetchGit {
    url = https://github.com/Shados/nix-fetchers;
    ref = "fetch-pypi-hash-xdg-cache-fix";
    rev = "55f1edea80ecb81c9f139d1b0e02ae647a23953c";
  };
  makeExtraBuiltins = pkgs.callPackage "${nix-fetchers}/make-extra-builtins.nix" { };
  extraBuiltins = makeExtraBuiltins {
    fetchers = {
      fetch-pypi-hash = "${nix-fetchers}/fetch-pypi-hash";
    };
  };
in
{
  nix = {
    # 0 will auto-detect the number of physical cores and use that
    buildCores = mkDefault 0;
    useSandbox = true;
    gc = {
      automatic = true;
      dates = "*-*-1 05:15"; # 5:15 AM on the first of each month
      options = "--delete-older-than 90d"; # Delete all generations older than 90 days
    };
    autoOptimiseStore = true;

    # Have the builders run at low CPU and IO priority
    daemonIONiceLevel = mkDefault 7;
    daemonNiceLevel = mkDefault 19;
    trustedUsers = [
      "root"
      "shados"
    ];

    binaryCaches = mkOrder 999 [
      "https://cache.nixos.org/"
    ];

    extraOptions = ''
      plugin-files = ${pkgs.nix-plugins}/lib/nix/plugins/libnix-extra-builtins.so
      extra-builtins-file = ${extraBuiltins}/extra-builtins.nix
    '';
  };

  environment.systemPackages = [
    # Install fetch-pypi-hash as a shell command also
    (pkgs.callPackage "${nix-fetchers}/fetch-pypi-hash/build.nix" { })
  ];
}
