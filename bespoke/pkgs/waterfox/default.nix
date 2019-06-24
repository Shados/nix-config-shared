{ lib, stdenv, makeDesktopItem
, pkgconfig, autoconf213, bzip2, cairo
, dbus, dbus-glib, file, fontconfig, freetype
, hunspell, icu, libevent, libjpeg, libnotify
, libstartup_notification, libvpx, makeWrapper, libGLU_combined
, nspr, nss, pango, perl, python, sqlite
, unzip, xorg, which, yasm, zip, zlib, libIDL, libpng
, rustc, cargo, jemalloc, gnused, ensureNewerSourcesHook, llvmPackages
, fetchFromGitHub


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
  flag = tf: x: [(if tf then "--enable-${x}" else "--disable-${x}")];
  gcc = if stdenv.cc.isGNU then stdenv.cc.cc else stdenv.cc.cc.gcc;
in

stdenv.mkDerivation rec {
  name = "waterfox-${version}";
  version = "56.2.9";

  src = fetchFromGitHub {
    owner  = "MrAlex94";
    repo   = "Waterfox";
    rev    = version;
    sha256 = "0l8nwgrl7kkf4mvmwmcxhpwiks6njfdj6qlrsf51gcnpkmlm5bm8";
  };
  src_vendorjs = ./vendor.js;

  patches = [
    <nixpkgs/pkgs/applications/networking/browsers/firefox/env_var_for_system_dir.patch>
    <nixpkgs/pkgs/applications/networking/browsers/firefox/fix-pa-context-connect-retval.patch>
    ./better-env-exception.patch
    ./clang-fixes.patch
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
    libXt pixman
  ])
  ++ lib.optional alsaSupport alsaLib
  ++ lib.optional pulseaudioSupport libpulseaudio
  ++ lib.optionals ffmpegSupport [ gstreamer gst-plugins-base gst_all_1.gst-plugins-base ]
  ++ lib.optional gtk3Support gtk3;

  nativeBuildInputs = [
    autoconf213 which gnused pkgconfig perl python cargo rustc
    (ensureNewerSourcesHook { year = "1980"; })
  ]
  ++ lib.optional gtk3Support wrapGAppsHook;

  NIX_CFLAGS_COMPILE = "-I${nspr.dev}/include/nspr -I${nss.dev}/include/nss";

  preConfigure = ''
    # remove distributed configuration files
    rm -f configure
    rm -f js/src/configure
    rm -f .mozconfig*
    make -f client.mk configure-files
    configureScript="$(realpath ./configure)"
    cxxLib=$( echo -n ${gcc}/include/c++/* )
    archLib=$cxxLib/$( ${gcc}/bin/gcc -dumpmachine )

    # Optimization
    export LDFLAGS="-Wl,-z,norelro,-O3,--sort-common,--as-needed,--relax,-z,combreloc,-z,global,--no-omagic"
    configureFlagsArray+=(--enable-optimize="-O3 -msse2 -mfpmath=sse -march=native -mtune=native -fcolor-diagnostics -w")

    export MOZ_MAKE_FLAGS=-j$NIX_BUILD_CORES
  '' + lib.optionalString googleAPISupport ''
    # Google API key used by Chromium and Firefox.
    # Note: These are for NixOS/nixpkgs use ONLY. For your own distribution,
    # please get your own set of keys.
    echo "AIzaSyDGi15Zwl11UNe6Y-5XW_upsfyw31qwZPI" > $TMPDIR/ga
    configureFlagsArray+=("--with-google-api-keyfile=$TMPDIR/ga")
  '' + ''
    cd obj-*
  '';

  configureFlags = [
    "--enable-application=browser"
    # System libraries
    "--with-system-jpeg"
    "--with-system-zlib"
    "--with-system-bz2"
    "--with-system-libevent"
    "--with-system-libvpx"
    "--with-system-png"
    "--with-system-icu"
    "--with-system-nspr"
    "--with-system-nss"
    "--enable-system-ffi"
    "--enable-system-hunspell"
    "--enable-system-pixman"
    "--enable-system-sqlite"
    # system cairo without layers acceleration may result in choppy video playback
    "--enable-system-cairo"

    "--enable-default-toolkit=cairo-gtk${if gtk3Support then "3" else "2"}"
    "--enable-startup-notification"
    "--enable-content-sandbox"

    "--disable-tests"
    "--disable-necko-wifi"
    "--disable-updater"
    "--enable-jemalloc"
    "--disable-maintenance-service"
    "--disable-gconf"

    "--target=x86_64-pc-linux-gnu"
    "--enable-rust-simd"

    "--enable-release"
    "--enable-strip"
    "--with-pthreads"

    "--with-app-name=waterfox"
    "--with-app-basename=Waterfox"
    "--with-branding=browser/branding/unofficial"
    "--with-distribution-id=org.waterfoxproject"

    "--enable-chrome-format=omni"

    # Features
    "--disable-libproxy"
    "--disable-js-shell"
    "--disable-verify-mar"
    "--disable-webspeech"
    "--disable-gamepad"
    "--disable-elf-hack"
    "--disable-mobile-optimize"
    "--disable-debug"
    "--disable-debug-symbols"
    "--disable-profiling"
    "--disable-signmar"
    # Stylo some issues in FF56 and forks based on it. TODO look into enabling
    # this as Waterfox updates
    # "--disable-stylo"
    "--enable-stylo=build"

  ]
  ++ [ "${if drmSupport then "--enable-eme=widevine" else "--disable-eme"}" ]
  ++ flag geolocationSupport "mozril-geoloc"
  ++ flag safeBrowsingSupport "safe-browsing"
  ++ flag alsaSupport "alsa"
  ++ flag pulseaudioSupport "pulseaudio"
  ++ flag ffmpegSupport "ffmpeg"
  ++ lib.optional (!ffmpegSupport) "--disable-gstreamer"
  ++ flag webrtcSupport "webrtc"
  ++ flag crashreporterSupport "crashreporter"
  ++ lib.optionals (lib.versionAtLeast version "56" && !stdenv.hostPlatform.isi686) [
    # on i686-linux: --with-libclang-path is not available in this configuration
    "--with-libclang-path=${llvmPackages.libclang}/lib"
    "--with-clang-path=${llvmPackages.clang}/bin/clang"
  ];

  enableParallelBuilding = true;

  preInstall = ''
    # The following is needed for startup cache creation on grsecurity kernels.
    # paxmark m dist/bin/xpcshell
  '';
  postInstall = ''
    # For grsecurity kernels
    # paxmark m $out/lib/waterfox*/{waterfox,waterfox-bin,plugin-container}

    # Remove SDK cruft. FIXME: move to a separate output?
    rm -rf $out/share/idl $out/include $out/lib/waterfox-devel-*

    # Needed to find Mozilla runtime
    gappsWrapperArgs+=(--argv0 "$out/bin/.waterfox-wrapped")

    mkdir -p $out/share/applications
    cp ${desktopItem}/share/applications/* $out/share/applications

    mkdir -p $out/lib/${name}/browser/defaults/preferences
    cp ''${src_vendorjs} $out/lib/${name}/browser/defaults/preferences/vendor.js

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
    patchelf --set-rpath "${lib.getLib libnotify
      }/lib:$(patchelf --print-rpath "$out"/lib/waterfox*/libxul.so)" \
        "$out"/lib/waterfox*/libxul.so
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    # Some basic testing
    "$out/bin/waterfox" --version
  '';

  passthru = {
    browserName = "firefox";
    # inherit version updateScript;
    isFirefox3Like = true;
    isTorBrowserLike = false;
    gtk = gtk2;
    inherit nspr;
    inherit ffmpegSupport;
    gssSupport = false;
  } // lib.optionalAttrs gtk3Support { inherit gtk3; };

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
    platforms   =  [ "x86_64-linux" ];
  };
}

