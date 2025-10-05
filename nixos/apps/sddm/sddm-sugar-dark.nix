{
  stdenv,
  lib,
  mkDerivation,
  fetchFromGitHub,
  qtgraphicaleffects,
  crudini,
  configOverrides ? null,
}:
let
  configOverridden = configOverrides != null;
in
mkDerivation rec {
  pname = "sddm-sugar-dark";
  version = "1.2";

  preferLocalBuild = true;

  src = fetchFromGitHub {
    owner = "MarianArlt";
    repo = pname;
    rev = "v${version}";
    sha256 = "0gx0am7vq1ywaw2rm1p015x90b75ccqxnb1sz3wy8yjl27v82yhb";
  };

  nativeBuildInputs = lib.optional configOverridden crudini;
  propagatedUserEnvPkgs = [
    qtgraphicaleffects
  ];

  installPhase = ''
    mkdir -p "$out/share/sddm/themes/"
    cp -r "$src" "$out/share/sddm/themes/sugar-dark"
  ''
  + lib.optionalString configOverridden ''
    chmod -R u+w "$out/share/sddm/themes/"
    crudini --merge "$out/share/sddm/themes/"*/theme.conf < "${configOverrides}"
  '';

  meta = with lib; {
    description = "The sweetest dark theme around for SDDM, the Simple Desktop Display Manager.";
    homepage = "https://github.com/MarianArlt/sddm-sugar-dark";
    maintainers = [ maintainers.arobyn ];
    license = licenses.gpl3;
  };
}
