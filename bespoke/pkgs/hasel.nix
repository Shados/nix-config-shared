{ stdenv, fetchPypi, python3Packages
}:

python3Packages.buildPythonPackage rec {
  pname = "hasel";
  version = "1.0.1";

  src = fetchPypi {
    inherit pname version;
    sha256      = "1iy321sqip42jkjx9594sc0i1ycqqy298iknmylc7ww21zv25lz3";
  };

  propagatedBuildInputs = with python3Packages; [
    numpy
  ];

  doCheck = true;
  # checkInputs = [];

  meta = with stdenv.lib; {
    description = "python+numpy RGB to HSL (and vice versa) converter";
    homepage    = "https://github.com/sumartoyo/hasel";
    maintainers = [ maintainers.arobyn ];
    license     = license.mit;
  };
}
