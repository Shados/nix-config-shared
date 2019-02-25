{ stdenv, lua
, luasocket
, buildLuaPackage
, fetchFromGitHub
}:
buildLuaPackage rec {
  name = "copas-${version}";
  version = "unstable-2018-12-03";

  src = fetchFromGitHub {
    owner = "keplerproject"; repo = "copas";
    rev = "b84301acb0e7b60e9428b7f626b82d301869cf74";
    sha256 = "1s0ljdc7i8sj521rjyfri2d6khg41xcgjccc9p0z9pp3iixpdy8l";
  };

  propagatedBuildInputs = [
    luasocket
  ];

  meta = with stdenv.lib; {
    description = "Copas is a dispatcher based on coroutines that can be used by TCP/IP servers.";
    homepage = http://keplerproject.github.io/copas;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
  };
}
