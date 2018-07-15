{ stdenv, fetchFromGitHub, makeDesktopItem
, pkgconfig, autoconf213, bzip2, cairo, libIDL, libpng
, dbus, dbus-glib, file, fontconfig, freetype
, hunspell, icu, libevent, libjpeg, libnotify
, libstartup_notification, libvpx, makeWrapper, libGLU_combined
, nspr, nss, pango, perl, python, sqlite
, unzip, xorg, which, yasm, zip, zlib
, rustc, cargo, jemalloc, gnused, ensureNewerSourcesHook, writeText, clang


## Optionals

### Optional Libraries
, alsaSupport ? true, alsaLib
, pulseaudioSupport ? true, libpulseaudio
, ffmpegSupport ? true, gstreamer, gst-plugins-base, gst_all_1
, gtk3Support ? true, gtk2, gtk3, wrapGAppsHook

### privacy-related options

, privacySupport ? true
, webrtcSupport ? !privacySupport
, geolocationSupport ? !privacySupport
, googleAPISupport ? !privacySupport
, crashreporterSupport ? false

, safeBrowsingSupport ? false
, drmSupport ? false

}:

let
  flag = tf: x: if tf then "ac_add_options --enable-${x}" else "ac_add_options --disable-${x}";
  gcc = if stdenv.cc.isGNU then stdenv.cc.cc else stdenv.cc.cc.gcc;

  mozconfig = writeText "mozconfig" ''
    export CC=clang
    export CXX=clang++
    export LDFLAGS="-Wl,-z,norelro,-O3,--sort-common,--as-needed,--relax,-z,combreloc,-z,global,--no-omagic"

    ac_add_options --enable-optimize="-O3 -msse2 -mfpmath=sse -march=native -mtune=native -fcolor-diagnostics -w"
    ac_add_options --enable-rust-simd # on x86 requires SSE2
    mk_add_options AUTOCLOBBER=1
    mk_add_options MOZ_OBJDIR=objdir

    ac_add_options --target=x86_64-pc-linux-gnu

    ac_add_options --enable-application=browser

    # System libraries
    ac_add_options --with-system-jpeg
    ac_add_options --with-system-zlib
    ac_add_options --with-system-bz2
    ac_add_options --with-system-libevent
    ac_add_options --with-system-libvpx
    ac_add_options --with-system-png
    ac_add_options --with-system-icu
    ac_add_options --with-system-nspr
    ac_add_options --with-system-nss
    ac_add_options --enable-system-ffi
    ac_add_options --enable-system-hunspell
    ac_add_options --enable-system-sqlite

    # system cairo without layers acceleration may result in choppy video playback
    ac_add_options --enable-system-cairo
    ac_add_options --enable-system-pixman
    ac_add_options --enable-default-toolkit=cairo-gtk${if gtk3Support then "3" else "2"}

    ac_add_options --enable-startup-notification
    ac_add_options --enable-content-sandbox

    ac_add_options --disable-tests
    ac_add_options --disable-necko-wifi
    ac_add_options --disable-updater
    ac_add_options --enable-jemalloc
    ac_add_options --disable-maintenance-service
    ac_add_options --disable-gconf

    ac_add_options --target=x86_64-pc-linux-gnu

    ac_add_options --enable-release
    ac_add_options --enable-strip
    ac_add_options --with-pthreads

    ac_add_options --with-app-name=waterfox
    ac_add_options --with-app-basename=Waterfox
    ac_add_options --with-branding=browser/branding/unofficial
    ac_add_options --with-distribution-id=org.waterfoxproject

    # library and chrome format
    ac_add_options --enable-chrome-format=omni


    # Features
    ${if drmSupport then "ac_add_options --enable-eme=widevine" else "ac_add_options --disable-eme"}
    ${flag geolocationSupport "mozril-geoloc"}
    ${flag safeBrowsingSupport "safe-browsing"}
    ${flag alsaSupport "alsa"}
    ${flag pulseaudioSupport "pulseaudio"}
    ${flag ffmpegSupport "ffmpeg"}
    ${stdenv.lib.optionalString (!ffmpegSupport) "ac_add_options --disable-gstreamer"}
    ${flag webrtcSupport "webrtc"}
    ${flag crashreporterSupport "crashreporter"}
    ${stdenv.lib.optionalString googleAPISupport
    # Google API key used by Chromium and Firefox.
    # Note: These are for NixOS/nixpkgs use ONLY. For your own distribution,
    # please get your own set of keys.
    ''
      echo "AIzaSyDGi15Zwl11UNe6Y-5XW_upsfyw31qwZPI" > $TMPDIR/ga
      ac_add_options "--with-google-api-keyfile=$TMPDIR/ga"
    ''}
    ac_add_options --disable-libproxy
    ac_add_options --disable-js-shell
    ac_add_options --disable-verify-mar
    ac_add_options --disable-webspeech
    ac_add_options --disable-gamepad
    ac_add_options --disable-elf-hack
    ac_add_options --disable-mobile-optimize
    ac_add_options --disable-debug
    ac_add_options --disable-debug-symbols
    ac_add_options --disable-profiling
    ac_add_options --disable-signmar
    # Stylo some issues in FF56 and forks based on it. TODO look into enabling
    # this as Waterfox updates
    ac_add_options --disable-stylo
  '';
in

stdenv.mkDerivation rec {
  name = "waterfox-${version}";
  version = "56.1.0";

  src = fetchFromGitHub {
    owner  = "MrAlex94";
    repo   = "Waterfox";
    rev    = version;
    #sha256 = "0nc6fwsxsflbmaljkjw4llnq8d9rh8538l2vqzl96xfwcffdpbzd";
    sha256 = "08kfxqw4c1ir2d782v5y40pp7nwaj5pzapkk64b10k7i9l5yyypx";
  };
  # src = /home/shados/technotheca/tmp/src/waterfox/Waterfox;

  src-vendorjs = ./vendor.js;

  patches = [
    <nixpkgs/pkgs/applications/networking/browsers/firefox/env_var_for_system_dir.patch>
    <nixpkgs/pkgs/applications/networking/browsers/firefox/fix-pa-context-connect-retval.patch>
    ./better-env-exception.patch
  ];

  desktopItem = makeDesktopItem {
    name = "waterfox";
    exec = "waterfox %U";
    icon = "waterfox";
    desktopName = "Waterfox";
    genericName = "Web Browser";
    categories = "Application;Network;WebBrowser;";
    mimeType = stdenv.lib.concatStringsSep ";" [
      "text/html"
      "text/xml"
      "application/xhtml+xml"
      "application/vnd.mozilla.xul+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "x-scheme-handler/ftp"
    ];
  };

  buildInputs = [
    bzip2 cairo dbus dbus-glib file fontconfig freetype
    hunspell icu libevent libjpeg libnotify libstartup_notification
    libvpx makeWrapper libGLU_combined nspr nss pango perl pkgconfig
    sqlite unzip yasm zip zlib libIDL libpng
    jemalloc gtk2
  ] ++ (with xorg; [
    libX11 libXext libXft libXi libXrender libXScrnSaver
    libXt pixman scrnsaverproto xextproto
  ])
  ++ stdenv.lib.optional alsaSupport alsaLib
  ++ stdenv.lib.optional pulseaudioSupport libpulseaudio
  ++ stdenv.lib.optionals ffmpegSupport [ gstreamer gst-plugins-base gst_all_1.gst-plugins-base ]
  ++ stdenv.lib.optional gtk3Support gtk3;

  nativeBuildInputs = [
    autoconf213 which gnused pkgconfig perl python cargo rustc clang
    (ensureNewerSourcesHook { year = "1980"; })
  ]
  ++ stdenv.lib.optional gtk3Support wrapGAppsHook;

  NIX_CFLAGS_COMPILE = "-I${nspr.dev}/include/nspr -I${nss.dev}/include/nss";


  configurePhase = ''
    cxxLib=$( echo -n ${gcc}/include/c++/* )
    archLib=$cxxLib/$( ${gcc}/bin/gcc -dumpmachine )
    echo "Copying pre-created mozconfig into place"
    # cp -f ${mozconfig} .mozconfig
  '' + stdenv.lib.optionalString enableParallelBuilding ''
    echo "Enabling parallel building"
    echo "mk_add_options MOZ_MAKE_FLAGS=-j$NIX_BUILD_CORES" >> .mozconfig
  '';

  enableParallelBuilding = true;

  buildPhase = ''
    make -j$NIX_BUILD_CORES -f client.mk build
  '';

  preInstall = ''
    # The following is needed for startup cache creation on grsecurity kernels.
    paxmark m dist/bin/xpcshell
  '';
  postInstall = ''
    # For grsecurity kernels
    paxmark m $out/lib/waterfox*/{waterfox,waterfox-bin,plugin-container}

    # Remove SDK cruft. FIXME: move to a separate output?
    rm -rf $out/share/idl $out/include $out/lib/waterfox-devel-*

    # Needed to find Mozilla runtime
    gappsWrapperArgs+=(--argv0 "$out/bin/.waterfox-wrapped")

    mkdir -p $out/share/applications
    cp ${desktopItem}/share/applications/* $out/share/applications

    mkdir -p $out/lib/${name}/browser/defaults/preferences
    cp $src-vendorjs $out/lib/${name}/browser/defaults/preferences/vendor.js

    # Don't include bundled dictionaries
    if [[ -d $out/lib/${name}/dictionaries ]]; then
      rm -rf $out/lib/${name}/dictionaries/
    fi
    if [[ -d $out/lib/${name}/hyphenation ]]; then
      rm -rf $out/lib/${name}/hyphenation/
    fi

    for n in 16 22 24 32 48 256; do
      size=$n"x"$n
      mkdir -p $out/share/icons/hicolor/$size/apps
      # fix missing icons
      if [[ ! -f "$src/browser/branding/unofficial/default$n.png" ]]; then
        echo "Copying missing icon for size $n"
        cp $src/browser/branding/official/default$n.png \
           $out/share/icons/hicolor/$size/apps/waterfox.png
      else
        cp $src/browser/branding/unofficial/default$n.png \
           $out/share/icons/hicolor/$size/apps/waterfox.png
      fi
    done
  '';

  postFixup = ''
    # Fix notifications. LibXUL uses dlopen for this, unfortunately; see #18712.
    patchelf --set-rpath "${stdenv.lib.getLib libnotify
      }/lib:$(patchelf --print-rpath "$out"/lib/waterfox*/libxul.so)" \
        "$out"/lib/waterfox*/libxul.so
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    # Some basic testing
    "$out/bin/waterfox" --version
  '';

  passthru = {
    browserName = "waterfox";
    # inherit version updateScript;
    isFirefox3Like = true;
    isTorBrowserLike = false;
    gtk = gtk2;
    inherit nspr;
    inherit ffmpegSupport;
    gssSupport = false;
  } // stdenv.lib.optionalAttrs gtk3Support { inherit gtk3; };

  meta = with stdenv.lib; {
    description = "A web browser designed for privacy and user choice";
    longDescription = ''
      The Waterfox browser is a specialised modification of the Mozilla
      platform, designed for privacy and user choice in mind.

      Other modifications and patches that are more upstream have been
      implemented as well to fix any compatibility/security issues that Mozilla
      may lag behind in implementing (usually due to not being high priority).
      High request features removed by Mozilla but wanted by users are retained
      (if they aren't removed due to security).
    '';
    homepage    = https://www.waterfoxproject.org;
    license     = licenses.mpl20;
    maintainers = with maintainers; [ arobyn ];
    platforms   = platforms.linux;
  };
}

