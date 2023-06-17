{ stdenv, fetchFromGitHub
, pkg-config, scons, ragel, gengetopt, doxygen
, libuv, libunwind, openfec, pulseaudio, sox, cpputest, openssl, speexdsp
}:
stdenv.mkDerivation rec {
  pname = "roc-toolkit";
  version = "unstable-2023-05-30";
  src = fetchFromGitHub {
    owner = "roc-streaming"; repo = pname;
    rev = "13da01d5a82b5c61e34aaa11865134d7371810f4";
    sha256 = "1bl81x2biw939cczfvasbnxb0nsys8sxcipz1cji601fvirwysai";
  };
  sconsFlags = [
    "--with-openfec-includes=${openfec}/include"
  ];
  preConfigure = ''
    sconsFlags+=" --prefix=$out"
  '';
  nativeBuildInputs = [
    pkg-config scons ragel gengetopt doxygen
  ];
  buildInputs = [
    libuv libunwind openfec pulseaudio sox cpputest openssl speexdsp
  ];
}
