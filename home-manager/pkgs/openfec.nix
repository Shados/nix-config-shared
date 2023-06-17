{ stdenv, fetchFromGitHub
, cmake
}:
stdenv.mkDerivation rec {
  pname = "openfec";
  version = "v1.4.2.4";
  src = fetchFromGitHub {
    owner = "roc-streaming"; repo = pname;
    rev = version;
    sha256 = "sha256-o8ar+hBB4Da4d4rziLnnDmZh0dQyiBxxz8lVj5dqQCo=";
  };
  cmakeFlags = [
    "-DBUILD_STATIC_LIBS=ON"
  ];
  nativeBuildInputs = [
    cmake
  ];
  buildInputs = [
  ];
  checkPhase = ''
    make test
  '';
  installPhase = ''
    mkdir -p $out/{include,lib}
    cp ../bin/Release/libopenfec.a $out/lib/
    cp -r ../src/* $out/include/
  '';
}
