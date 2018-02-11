{ stdenv, fetchFromGitHub, python3Packages }:

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

  meta = {
    description = "Generate and change colorschemes on the fly";
    homepage = "https://github.com/dylanaraps/pywal";
    maintainers = [ stdenv.lib.maintainers.mahe ];
    platforms = stdenv.lib.platforms.all;
    license = stdenv.lib.licenses.mit;
  };
}
