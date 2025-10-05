{
  config,
  lib,
  pkgs,
  ...
}:
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
    ./xsecurelock.nix
    ./zsh.nix
  ];
  options = {
    sn = {
      os = mkOption {
        type =
          with types;
          enum [
            "nixos"
            "darwin"
            "linux"
          ];
        default = "nixos";
        description = ''
          The OS platform being deployed on.
        '';
      };
    };
  };

  config = {
    xdg.enable = true; # Explicitly sets the XDG base directory paths
    xdg.portal = {
      enable = true;
      config.common.default = [ "gtk" ];
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
      xdgOpenUsePortal = true;
    };
    # Part of fix for nixpkgs #189851; they also need XDG_DATA_DIRS, but we're
    # doing that elsewhere via `systemctl --user import-environment`
    xdg.dataFile."systemd/user/xdg-desktop-portal-gtk.service.d/path.conf".text = ''
      [Service]
      Environment="PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
    '';
    xdg.dataFile."systemd/user/xdg-desktop-portal.service.d/path.conf".text = ''
      [Service]
      Environment="PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
    '';

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
          $DRY_RUN_CMD ${pkgs.systemd}/bin/systemctl --user restart "$service.service"
        done
      '';
    };
  };
}
