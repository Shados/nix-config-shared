{ stdenv, moonscript, buildLuarocksPackage, fetchFromGitHub
, moonpick
}:

buildLuarocksPackage rec {
  pname = "moonpick-vim";
  version = "scm-1";

  src = fetchFromGitHub {
    owner = "Shados"; repo = "moonpick-vim";
    rev = "3c6493f20a4c88dd14ad351de2a877eadef26f9b";
    sha256 = "1wx18bfz8kasvqx3czw4zbm7i2a5gq6xjsxascyrfv2bq0jrgad1";
  };
  # src = ~/technotheca/artifacts/media/software/lua/moonpick-vim;

  propagatedBuildInputs = [
    moonscript
    moonpick
  ];

  knownRockspec = "${pname}-${version}.rockspec";

  meta = with stdenv.lib; {
    description = "ALE-based vim integration for moonpick";
    homepage = https://github.com/Shados/moonpick-vim;
    hydraPlatforms = platforms.linux;
    maintainers = with maintainers; [ arobyn ];
    license = licenses.mit;
  };
}
