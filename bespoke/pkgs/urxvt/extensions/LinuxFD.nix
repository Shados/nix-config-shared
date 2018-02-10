{ stdenv, fetchurl, buildPerlModule, ModuleBuild, TestException, SubExporter }:
buildPerlModule rec {
  name = "Linux-FD-0.011";
  src = fetchurl {
    url = "mirror://cpan/authors/id/L/LE/LEONT/${name}.tar.gz";
    sha256 = "6bb579d47644cb0ed35626ff77e909ae69063073c6ac09aa0614fef00fa37356";
  };
  buildInputs = [ ModuleBuild TestException ];
  propagatedBuildInputs = [ SubExporter ];
  meta = {
    description = "Linux specific special filehandles";
    license = with stdenv.lib.licenses; [ artistic1 gpl1Plus ];
  };
}
