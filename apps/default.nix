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

    # System information/troubleshooting tools
    nix-repl
    atop

    # Generally-useful file utilities
    wgetpaste
    wget
    tree
    file
    unzip
  ];
}
