{ lib, stdenv, fetchurl, fetchFromGitHub
, which, help2man
, zlib, xz
}:
let
  inherit (lib) attrNames filterAttrs;

  patches = map (name: patchDir + "/${name}") patchFileNames;

  patchFileNames = attrNames (filterAttrs (_path: pathType: pathType == "regular") (builtins.readDir patchDir));
  patchDir = freetz-ng.outPath + "/make/host-tools/squashfs4-be-host/patches";
  freetz-ng = fetchFromGitHub {
    owner = "Freetz-NG"; repo = "freetz-ng";
    rev = "6eb5d1892dc72dd35d50d4de273d15bc72a570d8";
    sha256 = "1x2nd7ymyi3nysgxp8yf18aixqys1nq7nrd6ri4wxsm95r5h17j5";
  };
in
stdenv.mkDerivation rec {
  pname = "squashfs4-avm-be";
  version = "4.3";

  src = fetchurl {
    url = "https://downloads.sourceforge.net/squashfs/squashfs${version}.tar.gz";
    sha256 = "1xpklm0y43nd9i6jw43y2xh5zvlmj9ar2rvknh0bh7kv8c95aq0d";
  };

  inherit patches;
  patchFlags = [
    "-p0"
  ];

  strictDeps = true;
  nativeBuildInputs = [ which ]
    # when cross-compiling help2man cannot run the cross-compiled binary
    ++ lib.optionals (stdenv.hostPlatform == stdenv.buildPlatform) [ help2man ];
  buildInputs = [ zlib xz ];

  preBuild = ''
    cd squashfs-tools
    # TODO figure out how to pass this in makeFlags without shit breaking?
    makeFlagsArray+=("EXTRA_CFLAGS=-fcommon -DTARGET_FORMAT=AVM_BE")
  '' ;

  installFlags = [
    "INSTALL_DIR=${placeholder "out"}/bin"
    "INSTALL_MANPAGES_DIR=${placeholder "out"}/share/man/man1"
  ];

  makeFlags = [
    "LEGACY_FORMATS_SUPPORT=1"
    "GZIP_SUPPORT=1"
    "LZMA_XZ_SUPPORT=1"
    "XZ_SUPPORT=1"
    "COMP_DEFAULT=xz"
    "XATTR_SUPPORT=0"
    "XATTR_DEFAULT=0"
  ];


  meta = with lib; {
    homepage = "https://github.com/plougher/squashfs-tools";
    description = "Tool for creating and unpacking squashfs filesystems - with freetz-ng avm-be patches";
    platforms = platforms.unix;
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ ruuda ];
    mainProgram = "mksquashfs";
  };
}
