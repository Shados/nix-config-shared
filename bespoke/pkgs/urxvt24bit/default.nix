{ stdenv, fetchurl, fetchgit, perlSupport, libX11, libXt, libXft, ncurses, perl,
  fontconfig, freetype, pkgconfig, libXrender, gdkPixbufSupport, gdk_pixbuf,
  unicode3Support }:

let
  pname = "rxvt-unicode";
  version = "9.22";
in

stdenv.mkDerivation (rec {

  name = "${pname}${if perlSupport then "-with-perl" else ""}${if unicode3Support then "-with-unicode3" else ""}-${version}";

  src = fetchgit {
    url             = "https://github.com/exg/rxvt-unicode";
    rev             = "0767fe71f667f5be4e8967ca6ea27e2b14c19daf";
    sha256          = "0lc2s0b0p69q37cfb6maj67gcb8bwbmgl8qbmgsh27qzq44x0ks2";
    fetchSubmodules = true;
  };

  libptytty = fetchurl {
    url = "http://download.openpkg.org/components/cache/libptytty/libptytty-1.8.tar.gz";
    sha256 = "0byc9miy2fk5qzf4vnvsj0gxkfhj2izv8kipd9ywn080pj17yc6b";
  };

  libev = fetchurl {
    url = "http://download.openpkg.org/components/cache/libev/libev-4.22.tar.gz";
    sha256 = "1mhvy38g9947bbr0n0hzc34zwfvvfd99qgzpkbap8g2lmkl7jq3k";
  };


  buildInputs =
    [ libX11 libXt libXft ncurses /* required to build the terminfo file */
      fontconfig freetype pkgconfig libXrender ]
    ++ stdenv.lib.optional perlSupport perl
    ++ stdenv.lib.optional gdkPixbufSupport gdk_pixbuf;

  outputs = [ "out" "terminfo" ];


  patches = [
    # ./rxvt-unicode-9.06-font-width.patch
    # ./rxvt-unicode-256-color-resources.patch

    # display-wide-glyphs patches, to support some fontawesome icons (and other wide icons)
    # see: https://github.com/blueyed/rxvt-unicode/tree/display-wide-glyphs
    ./font-width-fix.patch
    ./line-spacing-fix.patch
    ./enable-wide-glyphs.patch
  ];
  # ++ stdenv.lib.optional stdenv.isDarwin ./rxvt-unicode-makefile-phony.patch;

  # Handle varying patch levels
  patchPhase = ''
    for i in $patches; do
      echo "Applying patch $i"
      patch -p1 < $i || patch -p0 < $i
    done
  '';

  configureFlags = [
    "--enable-wide-glyphs"
    "--with-terminfo=$terminfo/share/terminfo"
    "--enable-256-color"
    ''${if perlSupport then "--enable-perl" else "--disable-perl"}''
    ''${if unicode3Support then "--enable-unicode3" else "--disable-unicode3"}''
  ];

  preConfigure =
    ''
      tar xf ${libptytty}
      mv libptytty* libptytty
      tar xf ${libev}
      mv libev* libev
      mkdir -p $terminfo/share/terminfo
      export TERMINFO=$terminfo/share/terminfo # without this the terminfo won't be compiled by tic, see man tic
      NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -I${freetype.dev}/include/freetype2"
      NIX_LDFLAGS="$NIX_LDFLAGS -lfontconfig -lXrender "
    ''
    # make urxvt find its perl file lib/perl5/site_perl is added to PERL5LIB automatically
    + stdenv.lib.optionalString perlSupport ''
      mkdir -p $out/lib/perl5
      ln -s $out/{lib/urxvt,lib/perl5/site_perl}
    '';

  postInstall = ''
    mkdir -p $out/nix-support
    echo "$terminfo" >> $out/nix-support/propagated-user-env-packages
  '';

  meta = {
    description = "A clone of the well-known terminal emulator rxvt";
    homepage = "http://software.schmorp.de/pkg/rxvt-unicode.html";
    maintainers = [ stdenv.lib.maintainers.mornfall ];
  };
})
