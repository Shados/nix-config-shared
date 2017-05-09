{ stdenv, lib, makeWrapper,
  bash, iproute, curl, jshon, systemd, coreutils, gnused
}:

stdenv.mkDerivation {
  name = "digitalocean-init-2017-06-09";

  src = ./digitalocean-init;

  dontStrip = true;
  dontPatchELF = true;

  buildInputs = [ makeWrapper ];

  unpackPhase = ''
    cp $src digitalocean-init
  '';
  buildPhase = ''
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp -pvd digitalocean-init $out/bin/
    wrapProgram $out/bin/digitalocean-init --prefix PATH ":" "${lib.makeBinPath [ bash iproute curl jshon systemd coreutils gnused ]}"
  '';

  meta = with stdenv.lib; {
    description = "Initialization script for DigitalOcean droplets";
    platforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
  };
}
