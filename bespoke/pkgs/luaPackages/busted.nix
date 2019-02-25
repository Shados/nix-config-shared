{ stdenv, lua, buildLuaPackage
, lua-ev, copas, lua-cliargs, luasystem, dkjson, say, luassert
, lua-term, penlight, mediator_lua
, fetchFromGitHub, makeWrapper
}:
buildLuaPackage rec {
  name = "busted-${version}";
  version = "unstable-2018-12-14";

  src = fetchFromGitHub {
    owner = "Olivine-Labs"; repo = "busted";
    rev = "a98e43e4b63058738e63430f87aa6be68ad02bd3";
    sha256 = "19wijrhc5gdys1vjmjx562i3ijbpsjriqwcmh5fxyjf5w1svy9ff";
  };

  nativeBuildInputs = [
    makeWrapper
  ];
  propagatedBuildInputs = [
    copas lua-ev
    lua-cliargs luasystem dkjson say luassert lua-term penlight mediator_lua
  ];

  buildPhase = ":";
  installPhase = let
    luaPath = "$out/share/lua/${lua.luaversion}";
  in ''
    install -m 0555 -Dt $out/bin/ bin/*

    mkdir -p ${luaPath}
    cp -r busted ${luaPath}/

    for bin in $out/bin/*; do
      wrapProgram $bin \
        --prefix LUA_PATH  ';' "${luaPath}/?/init.lua;${luaPath}/?.lua;$LUA_PATH;" \
        --prefix LUA_CPATH ';' "$LUA_CPATH;"
    done;
  '';

  meta = with stdenv.lib; {
    description = "Elegant Lua unit testing.";
    homepage = http://olivinelabs.com/busted/;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
  };
}
