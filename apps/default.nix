{ config, pkgs, ... }:

{
  imports = [
    ./dmenu
    ./flake8.nix
    ./slim
    ./vim.nix
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
    nox
    iftop
    iotop
    atop
    nethogs
    tcpdump
    nmap
    openssl
    pciutils
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
