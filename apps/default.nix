{ config, pkgs, ... }:

{
  # Base set of system-wide packages
  environment.systemPackages = with pkgs; [
    # Terminal enhancements
    tmux

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

    # Generally-useful file utilities
    wgetpaste
    wget
    tree
    file
    unzip
  ];
}
