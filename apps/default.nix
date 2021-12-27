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
    jq.bin jq.man

    # Generally-useful file utilities
    wget
    axel
    tree
    file
    zip unzip unrar lzop p7zip lrzip
    rename # perl-rename
    ripgrep
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
      settings = {
        interval = 1;
        flags = "aF";
      };
    };
    bash = {
      enableCompletion = true;
      #shellAliases = {};
    };
  };
}
