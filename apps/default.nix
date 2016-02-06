{ config, pkgs, ... }:

{
  # Base set of system-wide packages
  environment.systemPackages = with pkgs; [
    # Terminal enhancements
    tmux
    fish
    rxvt_unicode # Needed for terminfo

    # Critical userspace tools
    vim_configurable
    #neovim

    # VCS
    git
    mercurial
    subversion

    # Debugging/sysadmin/System information
    nix-repl
    nox
    iftop
    iotop
    atop
    nethogs
    tcpdump
    nmap
    openssl
    pciutils
    nix-repl
    sysstat
    mtr
    gptfdisk
    parted
    telnet

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
  ];
}
