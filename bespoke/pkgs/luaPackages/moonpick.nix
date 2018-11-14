{ stdenv, moonscript, buildLuaPackage, fetchFromGitHub
, makeWrapper
}:
buildLuaPackage rec {
  name = "moonpick-${version}";
  version = "v0.8";
  src = fetchFromGitHub {
    owner = "nilnor"; repo = "moonpick";
    rev = version;
    sha256 = "11narvcx5zn5nvy73pmp3kna8axndlzzfgw9jcv4mjnwxwb40ws7";
  };

  buildInputs = [
    makeWrapper
  ];
  propagatedBuildInputs = [
    moonscript
  ];

  buildPhase = ":";
  installPhase = let
    luaPath = "$out/share/lua/${moonscript.luaversion}";
  in ''
    install -d $out/bin
    install -m 0555 bin/moonpick $out/bin/

    install -d ${luaPath}/moonpick
    for ft in lua moon; do
      install -m 0444 src/moonpick/init.$ft ${luaPath}/moonpick.$ft
      install -m 0444 src/moonpick/config.$ft ${luaPath}/moonpick/
    done

    for prog in $out/bin/*; do
      wrapProgram $prog               \
        --prefix LUA_PATH  ';' "${luaPath}/?.lua;$LUA_PATH"   \
        --prefix LUA_CPATH ';' "$LUA_CPATH"
    done
  '';

  meta = with stdenv.lib; {
    homepage = https://github.com/mpeterv/argparse;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
  };
}

