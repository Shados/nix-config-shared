{ config, pkgs, ... }:

{
  # Base set of system-wide packages
  environment.systemPackages = with pkgs; [
    # Terminal enhancements
    tmux
    fish

    # Critical userspace tools
    vim_configurable
    neovim
    git

    # Debugging/sysadmin/System information
    nix-repl
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
    gdisk
    fdisk

    # Generally-useful file utilities
    wgetpaste
    wget
    axel
    tree
    file
    unzip
    unrar
    lzop
    p7zip
  ];
}
