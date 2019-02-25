{ stdenv, lua, buildLuaPackage
, fetchFromGitHub, makeWrapper
}:
buildLuaPackage rec {
  name = "lua-inspect-${version}";
  version = "v3.1.1";

  src = fetchFromGitHub {
    owner = "kikito"; repo = "inspect.lua";
    rev = version;
    sha256 = "1407vlc5kwz6s3002nxn03kpbji20whfflbc5v5njf0p4sz9avw2";
  };

  buildPhase = ":";
  installPhase = let
    luaPath = "$out/share/lua/${lua.luaversion}";
  in ''
    install -d ${luaPath}
    install -m 0444 inspect.lua ${luaPath}/
  '';

  meta = with stdenv.lib; {
    description = "Human-readable representation of Lua tables";
    homepage = https://github.com/kikito/inspect.lua;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
  };
}

