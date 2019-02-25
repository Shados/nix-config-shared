{ stdenv, lua, buildLuaPackage
, fetchFromGitHub
}:
buildLuaPackage rec {
  name = "${pname}-${version}";
  pname = "lua-term";
  version = "unstable-2016-11-19";

  src = fetchFromGitHub {
    owner = "hoelzro"; repo = "lua-term";
    rev = "a0f695d40c271e4fd031ac65d0ac7ee107edc4a8";
    sha256 = "1qyh18ahhidijjif840mmq6w48dsw9yp12ppv10w0w2dws6yb1dq";
  };

  makeFlags = [
    "LUA_DIR=$(out)"
  ];

  meta = with stdenv.lib; {
    description = "Terminal operations for Lua";
    homepage = https://github.com/hoelzro/lua-term;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
    license = licenses.mit;
  };
}
