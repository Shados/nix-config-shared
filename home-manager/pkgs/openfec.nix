{
  stdenv,
  fetchFromGitHub,
  cmake,
}:
stdenv.mkDerivation rec {
  pname = "openfec";
  version = "v1.4.2.12";
  src = fetchFromGitHub {
    owner = "roc-streaming";
    repo = pname;
    rev = version;
    sha256 = "sha256-KOP3LqCZHdEgm+XhzBdNxnJipGC4gpvA57T7mIeSyaE=";
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
