{ stdenv, lua, buildLuaPackage
, say
, fetchFromGitHub
}:
buildLuaPackage rec {
  name = "${pname}-${version}";
  pname = "luassert";
  version = "unstable-2018-12-14";

  src = fetchFromGitHub {
    owner = "Olivine-Labs"; repo = "luassert";
    rev = "3b2351c384cf982b953ab6d7964f835acb8cb7db";
    sha256 = "1920d0ywzcm5n1db37xh3b5hvcnyq12hfiaj220d0zzvj0x9l40w";
  };

  propagatedBuildInputs = [
    say
  ];

  buildPhase = ":";
  installPhase = let
    luaPath = "$out/share/lua/${lua.luaversion}";
  in ''
    install -d ${luaPath}/luassert
    cp -r src/* ${luaPath}/luassert/
  '';

  meta = with stdenv.lib; {
    description = "Assertion library for Lua";
    homepage = https://github.com/Olivine-Labs/luassert;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
    license = licenses.mit;
  };
}
