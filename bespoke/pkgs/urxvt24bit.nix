{ stdenv, fetchgit, perlSupport, libX11, libXt, libXft, ncurses, perl,
  fontconfig, freetype, pkgconfig, libXrender, gdkPixbufSupport, gdk_pixbuf,
  unicode3Support }:

let
  pname = "rxvt-unicode";
  version = "9.22";
in

stdenv.mkDerivation (rec {

  name = "${pname}${if perlSupport then "-with-perl" else ""}${if unicode3Support then "-with-unicode3" else ""}-${version}";

  src = fetchgit {
    url    = "https://github.com/spudowiar/rxvt-unicode.git";
    rev    = "d6732943f1e79f09fa1bd86dbeb4e02a06bdfc18";
    sha256 = "0vhg9jmfx8c66h1p6mxa0nd7bpddphrhil0kdlm3asd6kf30zwwl";
    fetchSubmodules = true;
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
  ];
  # ++ stdenv.lib.optional stdenv.isDarwin ./rxvt-unicode-makefile-phony.patch;

  preConfigure =
    ''
      mkdir -p $terminfo/share/terminfo
      configureFlags="--with-terminfo=$terminfo/share/terminfo \
      --enable-256-color \
      --enable-24-bit-color \
      --enable-combining \
      --enable-fading \
      --enable-font-styles \
      --enable-iso14755 \
      --enable-keepscrolling \
      --enable-lastlog \
      --enable-mousewheel \
      --enable-next-scroll \
      --enable-pointer-blank \
      --enable-rxvt-scroll \
      --enable-selectionscrolling \
      --enable-slipwheeling \
      --disable-smart-resize \
      --enable-startup-notification \
      --enable-transparency \
      --enable-utmp \
      --enable-wtmp \
      --enable-xft \
      --enable-xim \
      --enable-xterm-scroll \
      --disable-pixbuf \
      --disable-frills \
      ${if perlSupport then "--enable-perl" else "--disable-perl"} \
      ${if unicode3Support then "--enable-unicode3" else "--disable-unicode3"}";
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
