{ lib, stdenv, pkgconfig, pango, perl, python2, python3, zip, libIDL
, libjpeg, zlib, dbus, dbus-glib, bzip2, xorg
, freetype, fontconfig, file, nspr, nss, libnotify
, yasm, libGLU_combined, sqlite, unzip, makeWrapper
, libevent, libstartup_notification, libvpx
, icu, libpng, jemalloc, glib
, autoconf213, which, gnused, cargo, rustc, llvmPackages
, rust-cbindgen, nodejs, nasm, fetchpatch
, writeText
, fetchFromGitHub


## Optionals

### Optional Libraries
, alsaSupport ? true, alsaLib
, pulseaudioSupport ? true, libpulseaudio
, gtk3Support ? true, gtk2, gtk3, wrapGAppsHook

### privacy-related options

, privacySupport ? true
, webrtcSupport ? !privacySupport
, googleAPISupport ? !privacySupport
, crashreporterSupport ? false

, drmSupport ? false

}:

let
  flag = tf: x: [(if tf then "--enable-${x}" else "--disable-${x}")];
  default-toolkit = if stdenv.isDarwin then "cairo-cocoa"
                    else "cairo-gtk${if gtk3Support then "3" else "2"}";
in

stdenv.mkDerivation rec {
  name = "waterfox-${version}";
  version = "gecko68-unstable-2019-07-23";

  src = fetchFromGitHub {
    owner  = "MrAlex94";
    repo   = "Waterfox";
    rev    = "f8a37ef0e898f9199f050559ac6bdf931b35a93d";
    sha256 = "0ifp9xnlb81xihkwr5fhfnis9nil48rbza9waric9nq48b8gr1m8";
  };

  patches = [
    (fetchpatch { # https://bugzilla.mozilla.org/show_bug.cgi?id=1500436#c29
      name = "write_error-parallel_make.diff";
      url = "https://hg.mozilla.org/mozilla-central/raw-diff/562655fe/python/mozbuild/mozbuild/action/node.py";
      sha256 = "11d7rgzinb4mwl7yzhidjkajynmxgmffr4l9isgskfapyax9p88y";
    })
    <nixpkgs/pkgs/applications/networking/browsers/firefox/env_var_for_system_dir.patch>
  ];

  buildInputs = [
    gtk2 perl zip libIDL libjpeg zlib bzip2
    dbus dbus-glib pango freetype fontconfig
    file libnotify yasm libGLU_combined sqlite unzip makeWrapper libevent libstartup_notification

    libvpx icu libpng jemalloc glib
    nspr nss nasm
  ] ++ (with xorg; [
    libXi libXcursor libX11 libXrender libXft libXt pixman libXScrnSaver
    xorgproto libXext
  ])
  ++ lib.optional alsaSupport alsaLib
  ++ lib.optional pulseaudioSupport libpulseaudio
  ++ lib.optional gtk3Support gtk3;

  nativeBuildInputs = [
    autoconf213 which gnused pkgconfig perl python2 python3 cargo rustc
    rust-cbindgen nodejs
    llvmPackages.llvm # llvm-objdump is required
  ]
  ++ lib.optional gtk3Support wrapGAppsHook;

  NIX_CFLAGS_COMPILE = [
    "-I${glib.dev}/include/gio-unix-2.0"
    "-I${nspr.dev}/include/nspr" "-I${nss.dev}/include/nss"
  ];

  postPatch = ''
    rm -rf obj-x86_64-pc-linux-gnu
  '';

  preConfigure = let
    mozconfig = writeText "mozconfig" (''
      MOZ_REQUIRE_SIGNING=0
      MOZ_ADDON_SIGNING=0

      ac_add_options "MOZ_ALLOW_LEGACY_EXTENSIONS=1"
      # Start configureFlags
    '' + (lib.concatMapStringsSep "\n" (flag: ''
      ac_add_options ${flag}
    '') configureFlags) + ''
      # End configureFlags
    '');

  in ''
    # remove distributed configuration files
    rm -f configure
    rm -f js/src/configure
    rm -f .mozconfig*

    configureScript="$(realpath ./mach) configure"

    export MOZCONFIG=$(pwd)/mozconfig
    cat << EOF > $MOZCONFIG
    MOZ_REQUIRE_SIGNING=0
    MOZ_ADDON_SIGNING=0

    ac_add_options "MOZ_ALLOW_LEGACY_EXTENSIONS=1"
    EOF
    # cp ${mozconfig} $MOZCONFIG
    # chmod +w $MOZCONFIG

    # Set C flags for Rust's bindgen program. Unlike ordinary C
    # compilation, bindgen does not invoke $CC directly. Instead it
    # uses LLVM's libclang. To make sure all necessary flags are
    # included we need to look in a few places.
    # TODO: generalize this process for other use-cases.

    BINDGEN_CFLAGS="$(< ${stdenv.cc}/nix-support/libc-cflags) \
      $(< ${stdenv.cc}/nix-support/cc-cflags) \
      ${stdenv.cc.default_cxx_stdlib_compile} \
      ${lib.optionalString stdenv.cc.isClang "-idirafter ${stdenv.cc.cc}/lib/clang/${lib.getVersion stdenv.cc.cc}/include"} \
      ${lib.optionalString stdenv.cc.isGNU "-isystem ${stdenv.cc.cc}/include/c++/${lib.getVersion stdenv.cc.cc} -isystem ${stdenv.cc.cc}/include/c++/${lib.getVersion stdenv.cc.cc}/$(cc -dumpmachine)"} \
      $NIX_CFLAGS_COMPILE"

    echo "ac_add_options BINDGEN_CFLAGS='$BINDGEN_CFLAGS'" >> $MOZCONFIG

    # Optimization
    # export LDFLAGS="-Wl,-z,norelro,-O3,--sort-common,--as-needed,--relax,-z,combreloc,-z,global,--no-omagic"
    # configureFlagsArray+=(--enable-optimize="-O3 -msse3 -march=x86-64 -mtune=generic -w")

    # export MOZ_MAKE_FLAGS=-j$NIX_BUILD_CORES

    # AS=as in the environment causes build failure https://bugzilla.mozilla.org/show_bug.cgi?id=1497286
    unset AS
  '' + lib.optionalString googleAPISupport ''
    # Google API key used by Chromium and Firefox.
    # Note: These are for NixOS/nixpkgs use ONLY. For your own distribution,
    # please get your own set of keys.
    echo "AIzaSyDGi15Zwl11UNe6Y-5XW_upsfyw31qwZPI" > $TMPDIR/ga
    configureFlagsArray+=("--with-google-location-service-api-keyfile=$TMPDIR/ga")
    configureFlagsArray+=("--with-google-safebrowsing-api-keyfile=$TMPDIR/ga")
  '';
  postConfigure = ''
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
    "--enable-system-pixman"
    "--enable-system-sqlite"
    # system cairo without layers acceleration may result in choppy video playback
    # "--enable-system-cairo"

    "--enable-default-toolkit=${default-toolkit}"
    "--enable-startup-notification"
    "--enable-content-sandbox"
    "--enable-webrender=build"

    "--disable-ccache"
    "--disable-tests"
    "--disable-necko-wifi"
    "--disable-updater"
    "--enable-jemalloc"
    "--disable-gconf"

    "--target=x86_64-pc-linux-gnu"
    "--enable-rust-simd"

    "--enable-release"
    "--enable-lto"
    "--enable-strip"

    "--with-app-name=waterfox"
    "--with-app-basename=Waterfox"
    "--with-branding=browser/branding/unofficial"
    "--with-distribution-id=org.waterfox"

    "--enable-chrome-format=omni"

    # Features
    # "--disable-libproxy"
    # "--disable-js-shell"
    "--disable-verify-mar"
    # "--disable-elf-hack"
    # "--disable-mobile-optimize"
    "--disable-debug"
    "--disable-debug-symbols"
    # "--disable-dmd"
    "--disable-profiling"
    # "--disable-signmar"

    "--with-libclang-path=${llvmPackages.libclang}/lib"
    "--with-clang-path=${llvmPackages.clang}/bin/clang"
  ]
  ++ [ "${if drmSupport then "--enable-eme=widevine" else "--disable-eme"}" ]
  ++ flag alsaSupport "alsa"
  ++ flag pulseaudioSupport "pulseaudio"
  ++ flag webrtcSupport "webrtc"
  ++ flag crashreporterSupport "crashreporter"
  ;

  enableParallelBuilding = true;
  doCheck = false; # "--disable-tests" above

  installPhase = null;
  postInstall = let
    nixosJS = writeText "nixos.js" ''
      pref("general.useragent.vendor",            "Nixos");

      // Use LANG environment variable to choose locale
      pref("intl.locale.matchOS",                 true);

      // Disable default browser checking.
      pref("browser.shell.checkDefaultBrowser",   false);

      // Don't disable our bundled extensions in the application directory
      pref("extensions.autoDisableScopes",        11);
      pref("extensions.shownSelectionUI",         true);

      // Nick some ideas from Gentoo
      pref("browser.display.use_system_colors",   true);
      pref("browser.link.open_external",          3);
      pref("general.smoothScroll",                true);
      pref("general.autoScroll",                  false);
      pref("browser.tabs.tabMinWidth",            15);
      pref("browser.backspace_action",            0);
      pref("browser.urlbar.hideGoButton",         true);
      pref("accessibility.typeaheadfind",         true);
      pref("browser.EULA.override",               true);
      pref("layout.css.dpi",                      0);
      pref("layers.acceleration.force-enabled",   true);
      pref("webgl.force-enabled",                 true);
    '';
  in ''
    # For grsecurity kernels
    # paxmark m $out/lib/waterfox*/{waterfox,waterfox-bin,plugin-container}

    # Remove SDK cruft. FIXME: move to a separate output?
    rm -rf $out/share/idl $out/include $out/lib/waterfox-devel-*

    # Needed to find Mozilla runtime
    gappsWrapperArgs+=(--argv0 "$out/bin/.waterfox-wrapped")

    mkdir -p $out/lib/${name}/browser/defaults/preferences
    cp ${nixosJS} $out/lib/${name}/browser/defaults/preferences/nixos.js

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
    ffmpegSupport = false;
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

