{ stdenv, fetchgit
, pkgconfig, gmp, lua
}:

stdenv.mkDerivation {
  pname = "gcc-lua";
  version = "unstable-2019-01-20";

  src = fetchgit {
    url = https://git.colberg.org/peter/gcc-lua;
    rev = "1bf91da1a431b226e2c4bf0f60bae993ccdd2ded";
    sha256 = "16xcwj3ncsdhx5igfs43aiq3g3mw2z2ibnkkshq8yanq2cjr6h7f";
  };

  buildInputs = [
    pkgconfig gmp lua
  ];

  installFlags = [
    "DESTDIR=$(out)"
  ];

  preInstall = ''
    sed Makefile \
      -i -Ee "s|(INSTALL_GCC_PLUGIN = ).*$|\1/gcc-plugins|g"
  '';

  meta = with stdenv.lib; {
    description = "Lua plugin for the GNU Compiler Collection";
    homepage    = "https://git.colberg.org/peter/gcc-lua";
    maintainers = [ maintainers.arobyn ];
    license     = licenses.mit;
  };
}
