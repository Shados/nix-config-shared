# Include a tarball of the current /etc/nixos folder in the built profile,
# means you can conveniently inspect config for older profiles you reboot into
{ config, pkgs, ... }:

let
  confTarball = with pkgs; stdenv.mkDerivation {
    name = "nixos-config-snapshot.tar.xz";
    src = /etc/nixos;
    buildInput = [ gnutar ];
    installPhase = ''
      cp -r $src nixos-config-snapshot
      tar -cvJf $out nixos-config-snapshot
    '';
  };
in

{
  environment.etc."nixos-snapshot.tar.xz" = {
    source = confTarball;
    mode = "0440";
  };
}
