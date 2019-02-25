{ stdenv, lua, buildLuaPackage
, fetchFromGitHub
, linenoise
}:
buildLuaPackage rec {
  name = "lua-linenoise-${version}";
  version = "0.9";

  src = fetchFromGitHub {
    owner = "hoelzro"; repo = "lua-linenoise";
    rev = version;
    sha256 = "02w1dr72rq9cl08i016f0nwmn8gd2gy31nmk3rmzmlysa5rp1l1y";
  };

  # makeFlags = [
  #   "LIBLINENOISE=-llinenoise"
  # ];
  propagatedBuildInputs = [
    linenoise
  ];
  installPhase = let
    cluaPath = "$out/lib/lua/${lua.luaversion}";
  in ''
    install -d ${cluaPath}
    install -m 0555 linenoise.so ${cluaPath}/
  '';

  meta = with stdenv.lib; {
    description = "Lua bindings for linenoise with UTF-8 support";
    homepage = https://github.com/hoelzro/lua-linenoise;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
  };
}
