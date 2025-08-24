{ config, lib, pkgs, ... }:
with lib;

let
  pins = import ../../pins;
  inherit (pins) envy;
  # envy = /home/shados/technotheca/artifacts/media/software/nix/envy;
in
{
  imports = [
    (import "${envy}/nixos.nix" { })
    ./neovim
    ./sddm
    # ./slim # RIP SLIM
    ./tmux.nix
  ];

  environment.sessionVariables.MANPAGER = "${pkgs.nvimpager}/bin/nvimpager -p";
  environment.sessionVariables.PAGER = "${pkgs.nvimpager}/bin/nvimpager -p";

  # Base set of system-wide packages
  environment.systemPackages = with pkgs; [
    # Terminal enhancements
    tmux
    fish
    rxvt-unicode-unwrapped.terminfo # Only need terminfo by default, as hardly need an X terminal on a server

    # VCS
    git gitAndTools.git-octopus

    # Debugging/sysadmin/System information
    man-pages # Linux kernel dev ones, e.g. man 5 proc
    dash # To have a lightweight POSIX shell around for scripts
    iftop
    iotop
    smem
    nethogs
    tcpdump
    nmap
    openssl # For SSL tunnels, password generation, simple file encryption, etc.
    pciutils # For `lspci`
    sysstat
    mtr
    gptfdisk
    parted
    inetutils
    libressl.nc # The one true netcat
    rsync
    lsof
    psmisc
    bind.dnsutils # We only care about the client-side DNS utilities, not the server
    jq.bin jq.man
    usbutils

    # Generally-useful file utilities
    wget
    axel
    tree
    file
    zip unzip unrar lzop p7zip lrzip pixz
    rename # perl-rename
    ripgrep
    fd
    (moreutils.overrideAttrs (oa: { meta = oa.meta // { priority = 10; }; })) # sponge, but don't override ts or parallel
    ts # taskspooler
    parallel
    ncdu
    unixtools.xxd
    pv

    # TODO niv via .envrc that adds nix-shell wrapp for it to path; the GHC dep is way too large to want it in by default
  ];

  # Config for various standard services & programs
  programs = {
    atop = {
      enable = true;
      atopService.enable = false;
      atopRotateTimer.enable = false; # FIXME: shouldn't be enabled if atopService is disabled, upstream
      settings = {
        interval = 5;
        flags = "aF";
      };
    };
    bash = {
      completion.enable = true;
    };
  };

  programs.steam = mkIf config.programs.steam.enable {
    package = mkDefault (pkgs.steam.override {
      extraBwrapArgs = [ "--tmpfs" "/dev/shm" ];
      extraEnv = {
        MANGOHUD = true;
      };
    });
    extraPackages = with pkgs; [
      gsettings-desktop-schemas glib
      xorg.libxcb dbus nss # Needed for electron-based shit I think

      # Needed for gamescope to work right
      libkrb5 keyutils

      gamemode

      cups # Needed for bitburner
    ];
    protontricks.enable = mkDefault true;
    localNetworkGameTransfers.openFirewall = mkDefault true;
    remotePlay.openFirewall = mkDefault true;
  };
}
