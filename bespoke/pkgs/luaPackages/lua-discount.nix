{ stdenv, lua, buildLuaPackage
, fetchgit
, luarocks, shim-getpw
, discount
}:
buildLuaPackage rec {
  name = "${pname}-${version}";
  pname = "lua-discount";
  version = "unstable-2018-06-15";

  src = fetchgit {
    url = "https://gitlab.com/craigbarnes/${pname}";
    rev = "eb5afcf49118b4cabf46fd8d89047cf58d485b5a";
    sha256 = "1wipgqb4qw0vjaf10qz34id7jpj6yqcd9npgcshnbnnpmxl9rphs";
    fetchSubmodules = false;
  };

  nativeBuildInputs = [
    luarocks
  ];
  buildInputs = [
    discount
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
    luarocks --tree $out make discount-scm-1.rockspec DISCOUNT_DIR=${discount}
  '';

  meta = with stdenv.lib; {
    description = "Lua bindings for the Discount Markdown library";
    homepage = https://gitlab.com/craigbarnes/lua-discount;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
    license = licenses.isc;
  };
}
