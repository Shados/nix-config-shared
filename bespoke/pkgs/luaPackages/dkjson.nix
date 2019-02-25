{ stdenv, lua, buildLuaPackage
, fetchurl
}:
buildLuaPackage rec {
  name = "${pname}-${version}";
  pname = "dkjson";
  version = "2.5";

  src = fetchurl {
    url = "http://dkolf.de/src/${pname}-lua.fsl/raw/${name}.lua?name=16cbc26080996d9da827df42cb0844a25518eeb3";
    sha256 = "1lnjzwyb9gmvi362j3ad4s8yw2zicdhw1z9srqg05qzw3ybscmhz";
  };

  unpackPhase = ":";
  buildPhase = ":";
  installPhase = let
    luaPath = "$out/share/lua/${lua.luaversion}";
  in ''
    install -d ${luaPath}
    cp $src ${luaPath}/dkjson.lua
  '';

  meta = with stdenv.lib; {
    description = "A JSON module written in Lua.";
    homepage = http://dkolf.de/src/dkjson-lua.fsl/home;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
    license = licenses.mit;
  };
}
