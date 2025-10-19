{
  stdenv,
  fetchFromGitHub,
  pkg-config,
  scons,
  ragel,
  gengetopt,
  doxygen,
  libuv,
  libunwind,
  libsndfile,
  openfec,
  pulseaudio,
  sox,
  cpputest,
  openssl,
  speexdsp,
}:
stdenv.mkDerivation rec {
  pname = "roc-toolkit";
  version = "unstable-2025-06-11";
  src = fetchFromGitHub {
    owner = "roc-streaming";
    repo = pname;
    rev = "7d7d73cd1cf4a7cc019b6491d45b9eb772dbf4e6";
    sha256 = "sha256-YlG1oDMl+yo7RL9aNUGK8YHnp9/4eahNOSeWiXLE7og=";
  };
  sconsFlags = [
    "--with-openfec-includes=${openfec}/include"
  ];
  preConfigure = ''
    sconsFlags+=" --prefix=$out"
  '';
  nativeBuildInputs = [
    pkg-config
    scons
    ragel
    gengetopt
    doxygen
  ];
  buildInputs = [
    libuv
    libunwind
    libsndfile
    openfec
    pulseaudio
    sox
    cpputest
    openssl
    speexdsp
  ];
}
