{ stdenv, lua, buildLuaPackage
, fetchFromGitHub
, luarocks, shim-getpw
}:
buildLuaPackage rec {
  name = "${pname}-${version}";
  pname = "etlua";
  version = "unstable-2017-11-11";

  src = fetchFromGitHub {
    owner = "leafo"; repo = pname;
    rev = "3d81e1f05c2628541dc52af9a68e15ca3f5fe8b9";
    sha256 = "148lh84750yya15v6qq9p0wssz4nrnq1ly2nd1kn31xpdx35jy2r";
    fetchSubmodules = false;
  };

  nativeBuildInputs = [
    luarocks
  ];

  buildPhase = let
    getpw-preload = "${shim-getpw}/lib/libshim-getpw.so";
  in ''
    # Configure shim-getpw to prevent spurious luarocks warning, and point it to
    # the right home directory
    export LD_PRELOAD="${getpw-preload}''${LD_PRELOAD:+ ''${LD_PRELOAD}}"
    export HOME=$(pwd)
    export SHIM_HOME=$HOME
    export USER=$(id -un)
    export SHIM_USER=$USER
    export SHIM_UID=$UID
  '';
  installPhase = ''
    # Tell luarocks to install to $out
    luarocks --tree $out make ${pname}-dev-1.rockspec
  '';

  meta = with stdenv.lib; {
    description = "Embedded Lua templates";
    homepage = https://github.com/leafo/etlua;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
    license = licenses.mit;
  };
}
