{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.sn;
in
{
  imports = [
    ./direnv
    ./fish
    ./locking.nix
    ./openbox
    ./os-dependent.nix
    ./sshfs.nix
    ./theming.nix
    ./zsh.nix
  ];
  options = {
    sn = {
      os = mkOption {
        type = with types; enum [ "nixos" "darwin" "linux" ];
        default = "nixos";
        description = ''
          The OS platform being deployed on.
        '';
      };
    };
  };

  config = {
    xdg.enable = true; # Explicitly sets the XDG base directory paths
    nixpkgs.config = {
      allowUnfree = true;
      android_sdk.accept_license = true;
    };
    home.username = "shados";
    home.homeDirectory = mkDefault "/home/${config.home.username}";
    home.activation = {
      initServiceRestartArray = lib.hm.dag.entryBefore [ "onFilesChange" ] ''
        declare -A restartServices
      '';
      # TODO: Perform all restarts in a single systemctl command
      performServiceRestarts = lib.hm.dag.entryAfter [ "onFilesChange" "reloadSystemd" ] ''
        for service in "''${!restartServices[@]}"; do
          echo Restarting "$service.service"
          $DRY_RUN_CMD systemctl --user restart "$service.service"
        done
      '';
    };
  };
}
