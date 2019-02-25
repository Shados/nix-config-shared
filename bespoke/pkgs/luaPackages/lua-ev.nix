{ stdenv, lua
, cmake, libev
, buildLuaPackage
, fetchFromGitHub
}:
buildLuaPackage rec {
  name = "lua-ev-${version}";
  version = "unstable-2015-08-04";

  src = fetchFromGitHub {
    owner = "brimworks"; repo = "lua-ev";
    rev = "339426fbe528f11cb3cd1af69a88f06bba367981";
    sha256 = "18p15rn0wj8dxncrc7jwivs2zw3gklzk5v1ynyzf7j6l8ggvyzml";
  };

  nativeBuildInputs = [
    cmake
  ];
  buildInputs = [
    libev
  ];

  preConfigure = ''
    cmakeFlagsArray=("-DINSTALL_CMOD=$out/lib/lua/${lua.luaversion}")
  '';

  meta = with stdenv.lib; {
    description = "Lua integration with libev. ";
    homepage = https://github.com/brimworks/lua-ev;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
  };
}
