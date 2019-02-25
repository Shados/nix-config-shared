{ stdenv, buildLuarocksPackage
, fetchFromGitHub
}:
buildLuarocksPackage rec {
  name = "${pname}-${version}";
  pname = "loadkit";
  version = "unstable-2015-12-07";

  src = fetchFromGitHub {
    owner = "leafo"; repo = pname;
    rev = "4ef72d45f52674603dca30d6eeda5ce21e4cee48";
    sha256 = "0xg1v3093l07mskgb93ph9xfx0c4n2p3ji059ay80v433z14wk2w";
    fetchSubmodules = false;
  };

  preBuild = ''
    export HOME=$(pwd)
    export USER=$(id -un)
  '';
  knownRockspec = "loadkit-dev-1.rockspec";
  buildType = "builtin";

  meta = with stdenv.lib; {
    description = "Loadkit allows you to load arbitrary files within the Lua package path";
    homepage = https://github.com/leafo/loadkit;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
    license = licenses.mit;
  };
}
