{ stdenv, lua, buildLuaPackage
, fetchFromGitHub, makeWrapper
, lua-linenoise
}:
buildLuaPackage rec {
  name = "lua-repl-${version}";
  version = "0.9";

  src = fetchFromGitHub {
    owner = "hoelzro"; repo = "lua-repl";
    rev = version;
    sha256 = "1n90h53ljyh2qs4hf72b620zn1cx8kwql0n9kkdxx45933hbpgwm";
  };

  buildPhase = ":";
  nativeBuildInputs = [
    makeWrapper
  ];
  propagatedBuildInputs = [
    lua-linenoise
  ];
  installPhase = let
    luaPath = "$out/share/lua/${lua.luaversion}";
  in ''
    install -d $out/bin
    install -m 0555 rep.lua $out/bin/

    install -d ${luaPath}
    cp -rv repl ${luaPath}/
    install -m 0444 repl/init.lua ${luaPath}/repl.lua

    for bin in $out/bin/*; do
      wrapProgram $bin \
        --prefix LUA_PATH  ';' "${luaPath}/?/init.lua;${luaPath}/?.lua;$LUA_PATH;" \
        --prefix LUA_CPATH ';' "$LUA_CPATH;"
    done;
  '';

  meta = with stdenv.lib; {
    description = "A Lua REPL implemented in Lua for embedding in other programs";
    homepage = https://github.com/hoelzro/lua-repl;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
  };
}
