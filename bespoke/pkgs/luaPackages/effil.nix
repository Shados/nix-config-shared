{ stdenv, buildLuaPackage, fetchgit
, cmake
, lua
}:

buildLuaPackage rec {
  name = "effil-${version}";
  version = "unstable-2018-11-14";

  src = fetchgit {
    # owner = "effil"; repo = "effil";
    url = "https://github.com/effil/effil";
    rev = "73be7561235f5f472fce6ed3173dff08bbd14423";
    sha256 = "1zxvhv5zv68r5sr3imxv0pshss4lwxy54syg6cq6cklvkliaknvh";
    # Need the below for the 'sol' submodule especially; might want to look
    # into using system version?
    fetchSubmodules = true;
  };

  cmakeFlags = [
    "-DLUA_INCLUDE_DIR=${lua}/include"
  ];

  preConfigure = ''
    cmakeFlags+=" -DCMAKE_INSTALL_PREFIX=$out/lib/lua/${lua.luaversion}"
  '';

  nativeBuildInputs = [
    cmake
  ];
  buildInputs = [
    lua
  ];

  meta = with stdenv.lib; {
    description = "Effil is a lua module for multithreading support, it allows you to spawn native threads and perform safe data exchange between them";
    homepage = https://github.com/effil/effil;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
    license = with licenses; mit;
  };
}
