{ stdenv, lua, buildLuaPackage
, fetchFromGitHub
}:
buildLuaPackage rec {
  name = "lua-cliargs-${version}";
  version = "3.0.2";

  src = fetchFromGitHub {
    owner = "amireh"; repo = "lua_cliargs";
    rev = "820e2d2e3bbc9e8cce3449b7d74330213995052e";
    sha256 = "17fk8am2g40kmnb60x3gm3x7bljmz3a2xmxvm01ppc8znmqh5sw5";
  };

  buildPhase = ":";
  installPhase = let
    luaPath = "$out/share/lua/${lua.luaversion}";
  in ''
    mkdir -p ${luaPath}
    install -m 0444 src/cliargs.lua ${luaPath}/cliargs.lua

    cp -r src/cliargs ${luaPath}/
  '';

  meta = with stdenv.lib; {
    description = "A command-line argument parsing module for Lua.";
    homepage = https://github.com/amireh/lua_cliargs;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
  };
}

