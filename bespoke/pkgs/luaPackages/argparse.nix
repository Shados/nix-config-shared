{ stdenv, lua, buildLuaPackage, fetchFromGitHub
}:
buildLuaPackage rec {
  name = "argparse-${version}";
  version = "0.6.0";
  src = fetchFromGitHub {
    owner = "mpeterv"; repo = "argparse";
    rev = version;
    sha256 = "0b4v0n1g0qh7jdkpq1ai8yq1di3l4kdpdb38hmkqhlgp8ip8j5p5";
  };

  buildPhase = ":";
  installPhase = let
    luaPath = "$out/share/lua/${lua.luaversion}";
  in ''
    install -d ${luaPath}
    cp -v src/argparse.lua ${luaPath}/
  '';

  meta = with stdenv.lib; {
    homepage = https://github.com/mpeterv/argparse;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
  };
}
