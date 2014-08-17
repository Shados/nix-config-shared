{ stdenv, fetchgit, pkgconfig, libnl, openssl }:

stdenv.mkDerivation rec {
  name = "hostapd-git-2014-08-04";
  version = "2.2";

  src = fetchgit {
    url = git://w1.fi/hostap.git;
    rev = "e8c08c9a363340c45baf8e13c758c99078bc0d8b";
    sha256 = "947c0f16fe11c5d0269fc913fe068e1303f1b239054ff057075f0291d1eefe51";
  };

  buildInputs = [ libnl openssl pkgconfig ];
  patches = [ ./forced-40mhz.patch ];

  configurePhase = ''
    cd hostapd
    substituteInPlace Makefile --replace "/usr/local/bin" "$out/bin"
    mv defconfig .config
    echo CONFIG_LIBNL32=y | tee -a .config
    echo CONFIG_IEEE80211N=y | tee -a .config
    echo CONFIG_IEEE80211AC=y | tee -a .config
    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE $(pkg-config --cflags libnl-3.0)"
  '';
  preInstall = "mkdir -p $out/bin";

  meta = with stdenv.lib; {
    homepage = http://hostap.epitest.fi;
    repositories.git = git://w1.fi/hostap.git;
    description = "A user space daemon for access point and authentication servers";
    license = licenses.gpl2;
    maintainers = [ maintainers.phreedom ];
    platforms = platforms.linux;
  };
}
