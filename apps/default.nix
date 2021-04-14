{ config, lib, pkgs, ... }:
with lib;

let
  pins = import ../pins;
  inherit (pins) envy;
in
{
  imports = [
    (import "${envy}/nixos.nix" { })
    ./neovim
    ./sddm
    # ./slim # RIP SLIM
    ./tmux.nix
  ];

  # Base set of system-wide packages
  environment.systemPackages = with pkgs; [
    # Terminal enhancements
    tmux
    fish
    rxvt_unicode.terminfo # Only need terminfo by default, as hardly need an X terminal on a server

    # VCS
    git gitAndTools.git-octopus

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
    wget
    axel
    tree
    file
    zip
    unar
    rename # perl-rename
    ripgrep
    moreutils # sponge
    ncdu
    unixtools.xxd
  ];

  # Config for various standard services & programs
  programs = {
    atop.settings = {
      interval = 1;
    };
    bash = {
      enableCompletion = true;
      #shellAliases = {};
    };
  };
}
