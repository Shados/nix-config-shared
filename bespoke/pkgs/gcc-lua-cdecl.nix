{ buildLuaPackage, stdenv, fetchgit
, gcc-lua
}:

buildLuaPackage rec {
  name = "${pname}-${version}";
  pname = "gcc-lua-cdecl";
  version = "unstable-2019-01-20";

  src = fetchgit {
    url = https://git.colberg.org/peter/gcc-lua-cdecl;
    rev = "e34d314f0337203bce4f2747eb55525cc482692b";
    sha256 = "1kh88jvipvr51za32ayqkm5nfi82xppbimjd94brsdhz64yal58l";
  };

  buildInputs = [
    gcc-lua
  ];

  preBuild = ''
    makeFlagsArray+=("GCCLUA=${gcc-lua}/gcc-plugins/gcclua.so")
    echo ''${makeFlagsArray[*]}

    # sed Makefile \
    #   -i -Ee "s|(INSTALL_GCC_PLUGIN = ).*$|\1/gcc-plugins|g"
  '';

  meta = with stdenv.lib; {
    description = "C declaration composer for the GNU Compiler Collection";
    homepage    = "https://git.colberg.org/peter/gcc-lua-cdecl";
    maintainers = [ maintainers.arobyn ];
    license     = licenses.mit;
  };
}
