{ stdenv, lua, buildLuaPackage
, fetchFromGitHub
}:
buildLuaPackage rec {
  name = "${pname}-${version}";
  pname = "mediator_lua";
  version = "v1.1.2-0";

  src = fetchFromGitHub {
    owner = "Olivine-Labs"; repo = "mediator_lua";
    rev = version;
    sha256 = "1vsm1ad55f7wfmhdag0srrw2achmkkfsy4gbqwp6s6shcira06ks";
  };

  buildPhase = ":";
  installPhase = let
    luaPath = "$out/share/lua/${lua.luaversion}";
  in ''
    install -d ${luaPath}/
    cp src/mediator.lua ${luaPath}/
  '';

  meta = with stdenv.lib; {
    description = "Mediator pattern implementation for pub-sub management.";
    homepage = https://github.com/Olivine-Labs/mediator_lua;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
    license = licenses.mit;
  };
}
