{ config, lib, pkgs, ... }:
with lib;

{
  imports = [
    ./cdda.nix
    ./dmenu
    ./flake8.nix
    ./slim
    ./vim.nix
    ./tmux.nix
  ];

  nixpkgs.config.packageOverrides = pkgs: {
    dunst = pkgs.dunst.override { dunstify = true; }; # Add the `dunstify` notifier binary to $out
  };

  # Base set of system-wide packages
  environment.systemPackages = with pkgs; [
    # Terminal enhancements
    tmux
    fish
    rxvt_unicode.terminfo # Only need terminfo by default, as hardly need an X terminal on a server

    # VCS
    git
    mercurial
    subversion

    # Debugging/sysadmin/System information
    manpages # Linux kernel dev ones, e.g. man 5 proc
    dash # To have a lightweight POSIX shell around for scripts
    iftop
    iotop
    atop
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
    telnet
    netcat-openbsd # The one true netcat
    rsync
    lsof
    psmisc
    bind.dnsutils # We only care about the client-side DNS utilities, not the server

    # Generally-useful file utilities
    wgetpaste
    wget
    axel
    tree
    file
    zip
    unzip
    unrar
    lzop
    p7zip
    rename # perl-rename

    pastebin
  ];
}
