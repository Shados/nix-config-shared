{ stdenv, fetchFromGitHub, python3Packages
, makeWrapper, imagemagick, python2 }:

python3Packages.buildPythonApplication rec {
  name = "pywal-${version}";
  version = "1.3.2";

  src = fetchFromGitHub {
    owner    = "dylanaraps";
    repo    = "pywal";
    rev     = "tags/${version}";
    sha256  = "0i3qcn0r6kn88g8wrkla8xs2l5a71pydciywf297ag3fmjksv6cd";
  };

  doCheck = false;
  buildInputs = [
    makeWrapper imagemagick
  ];

  postInstall = ''
    wrapProgram $out/bin/wal --prefix PATH ':' "${stdenv.lib.makeBinPath [ imagemagick python2 ]}"
  '';

  meta = with stdenv.lib; {
    description = "Generate and change colorschemes on the fly";
    homepage = "https://github.com/dylanaraps/pywal";
    maintainers = [ maintainers.arobyn ];
    platforms = platforms.all;
    license = licenses.mit;
  };
}
