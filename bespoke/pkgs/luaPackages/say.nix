{ stdenv, lua, buildLuaPackage
, fetchFromGitHub
}:
buildLuaPackage rec {
  name = "${pname}-${version}";
  pname = "say";
  version = "v1.3-1";

  src = fetchFromGitHub {
    owner = "Olivine-Labs"; repo = "say";
    rev = version;
    sha256 = "0psx0pk826s44wrx2fi5rx4rbr4f0d2mndasyc4qrdlwss5n02dq";
  };

  buildPhase = ":";
  installPhase = let
    luaPath = "$out/share/lua/${lua.luaversion}";
  in ''
    install -d ${luaPath}/say
    cp src/init.lua ${luaPath}/say/
  '';

  meta = with stdenv.lib; {
    description = "Lua string hashing library, useful for internationalization";
    homepage = https://github.com/Olivine-Labs/say;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
    license = licenses.mit;
  };
}
