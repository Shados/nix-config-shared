{ stdenv, fetchgit, pkgconfig, zlib, openssl, boost, libdb, gmp }:

stdenv.mkDerivation rec {
  name = "datacoin-hp-git";
  version = "2014-08-15";

  src = fetchgit {
    url = git://github.com/foo1inge/datacoin-hp;
    rev = "791125b901767b9dec40e04f6865181a3276395b";
    sha256 = "652f0e47a24862a9fdc113a76c1944d4d81cb790e79688d55c4d9971d518ca19";
  };

  buildInputs = [ zlib gmp openssl boost libdb ];

  prePatch = ''
    cd src
  '';
  configurePhase = ''
    cp makefile.unix makefile.nix
    substituteInPlace makefile.nix --replace "$(OPENSSL_INCLUDE_PATH)" "${openssl}/include"
    substituteInPlace makefile.nix --replace "$(OPENSSL_LIB_PATH)" "${openssl}/lib"
    substituteInPlace makefile.nix --replace "$(BOOST_INCLUDE_PATH)" "${boost}/include"
    substituteInPlace makefile.nix --replace "$(BOOST_LIB_PATH)" "${boost}/lib"
    substituteInPlace makefile.nix --replace "$(BDB_INCLUDE_PATH)" "${libdb}/include"
    substituteInPlace makefile.nix --replace "$(BDB_LIB_PATH)" "${libdb}/lib"
  '';
  # TODO: Figure out why parallel building with -j fails
  buildPhase = ''
    make -f makefile.nix USE_UPNP=
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp datacoind $out/bin
  '';

  meta = with stdenv.lib; {
    homepage = https://datacoin.info;
    repositories.git = git://github.com/foo1inge/datacoin-hp;
    description = "Datacoin High Performance miner";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
