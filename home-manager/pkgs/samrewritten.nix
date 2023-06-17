{ stdenv, lib, fetchFromGitHub
, pkg-config
, curl, gtkmm3, yajl
}:
stdenv.mkDerivation rec {
  pname = "SamRewritten";
  version = "unstable-2022-03-26";
  src = fetchFromGitHub {
    owner = "PaulCombal"; repo = pname;
    rev = "6bf70021d21dc9f52a8061682b69c346e0d8f1f2";
    sha256 = "sha256-BEXhEfhizHMP3h6YJwPx60oOHwnnhuKwL9gmnpxawl0=";
  };
  nativeBuildInputs = [
    pkg-config
  ];
  buildInputs = [
    curl gtkmm3 yajl
  ];
  makeFlags = [
    "DESTDIR=$(out)"
  ];
  postInstall = ''
    rm -f $out/usr/bin/samrewritten
    mv $out/usr/* $out/
    rmdir $out/usr
    ln -s $out/lib/SamRewritten/bin/launch.sh $out/bin/samrewritten
  '';
  meta = with lib; {
    description = "Steam Achievement Manager For Linux. Rewritten in C++.";
    homepage = https://github.com/PaulCombal/SamRewritten;
    license = licenses.gpl3;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ arobyn ];
  };
}
