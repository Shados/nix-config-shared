{ config, pkgs, ... }:

{
  imports = [
    ./dmenu
    ./slim
    ./vim.nix
  ];

  # Base set of system-wide packages
  environment.systemPackages = with pkgs; [
    # Terminal enhancements
    tmux
    fish
    rxvt_unicode.terminfo

    # Critical userspace tools
    vim_configurable

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
    netcat-openbsd
    rsync
    lsof
    psmisc

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

  # Includes kernel modules + userspace tools
  boot.supportedFilesystems = [
    "btrfs"
  ];
}
