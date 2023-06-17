{ stdenv, fetchFromGitHub }:
stdenv.mkDerivation rec {
  pname = "telescope-fzy-native.nvim";
  version = "unstable-2021-04-08";
  src = fetchFromGitHub {
    owner = "nvim-telescope"; repo = pname;
    rev = "7b3d2528102f858036627a68821ccf5fc1d78ce4";
    sha256 = "1mb47ixnpgd7ygrq1cldp9anc6gxqly4amj0l1pgh8cllj63393v";
    fetchSubmodules = true;
  };
  buildPhase = ''
    ls -la
    echo -- ----------
    ls -la deps
    pushd deps/fzy-lua-native
    make
    popd
  '';
  installPhase = ''
    mkdir -p $out
    cp -r ./* $out/
  '';
}
