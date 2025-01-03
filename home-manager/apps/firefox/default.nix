# TODO lock *all* prefs, but still pref() them first?
{ config, lib, pkgs, ... }:
with lib;
let
  pins = import ../../../pins;
  ff-hardened-userjs = pkgs.runCommandNoCC "ff-hardened-user.js" {
    src = pins.ff-hardened-userjs;
    nativeBuildInputs = with pkgs; [ gnused ];
    preferLocalBuild = true;
  } ''
    # Convert all the arkenfox user.js prefs into prefs
    sed -e 's|user_pref|pref|g' "$src/user.js" > "$out"
  '';
  legacyFox = pkgs.stdenv.mkDerivation {
    name = "legacyfox";
    src = pkgs.fetchFromGitHub {
      owner = "girst"; repo = "LegacyFox-mirror-of-git.gir.st";
      rev = "312a791ae03bddd725dee063344801f959cfe44d";
      sha256 = "05ppc2053lacvrlab4fspxmmjmkryvvc6ndrzhyk06ivmm2nlyyx";
    };
    preferLocalBuild = true;
    DESTDIR="$(out)";
  };
  # TODO
  # - Certificates :O?
  # - inject keyworded search engines via bookmarks?
  # - Cookie config?
  # - Extensions and their settings :o?
  #     - Cookie whitelists
  #     - DOM storage whitelists
  #     - IndexDB storage whitelists
  # - Home page?
  # - InstallAddonsPermission to some alternative addon archive?
  # - PopupBlocking whitelist?
  # - Proxy + PAC setup?
  # - change the ghacks-user.js stuff to source the source, then override
  #   -- easier maintenance
  # - explicitly whitelisted list of system fonts (apple-based?), to resist
  #   fingerprintg? probably pointless tbh
  # - find an extension that automatically pre-loads github issue "hidden item"
  #   comments?
  customizeFox = { base, libName, binName, legacyShim ? false }: let
    version = lib.getVersion base;
  in flip pkgs.wrapFirefox {
    applicationName = binName;
    # TODO figure out a build-time sanity check for this, to prevent potentially bad fuckups (e.g. accidental history wiping)
    extraPrefs = ''
        // ghacks-user.js & overrides {{{
        ${builtins.readFile ff-hardened-userjs}

        // Personal overrides of ghacks-user.js defaults below here
        lockPref("_user.js.parrot", "overrides section syntax error");

        /* 0102: set startup page [SETUP-CHROME]
         * 0=blank, 1=home, 2=last visited page, 3=resume previous session
         * [NOTE] Session Restore is cleared with history (2803, 2804), and not used in Private Browsing mode
         * [SETTING] General>Startup>Restore previous session ***/
        unlockPref("browser.startup.page"); pref("browser.startup.page", 3);

        // We do this because having it as `false` prevents us from enabling
        // the bookmark toolbar only on new tab pages. The settings in section
        // 105 still prevent all of the bullcrap that the modern 'new tab page'
        // actually shows, and turns off all the fucking telemetry, so this
        // isn't actually problematic to enable.
        /* 0104: set NEWTAB page
         * true=Activity Stream (default, see 0105), false=blank page
         * [SETTING] Home>New Windows and Tabs>New tabs ***/
        unlockPref("browser.newtabpage.enabled"); pref("browser.newtabpage.enabled", true);

        // TODO: Implement my own page. See: https://git.sp-codes.de/samuel-p/connectivity-check
        /* 0360: disable Captive Portal detection
         * [1] https://www.eff.org/deeplinks/2017/08/how-captive-portals-interfere-wireless-security-and-privacy ***/
        // unlockPref("captivedetect.canonicalURL"); pref("captivedetect.canonicalURL", "http://detectportal.firefox.com/success.txt");
        // unlockPref("network.captive-portal-service.enabled"); pref("network.captive-portal-service.enabled", true);

        /* 0361: disable Network Connectivity checks [FF65+]
         * [1] https://bugzilla.mozilla.org/1460537 ***/
        // unlockPref("network.connectivity-service.enabled"); pref("network.connectivity-service.enabled", true);
        // TODO: Implement my own pages, defaults are:
        // unlockPref("network.connectivity-service.IPv4.url"); pref("network.connectivity-service.IPv4.url", "http://detectportal.firefox.com/success.txt?ipv4");
        // unlockPref("network.connectivity-service.IPv6.url"); pref("network.connectivity-service.IPv6.url", "http://detectportal.firefox.com/success.txt?ipv6");

        /* 0710: enable DNS-over-HTTPS (DoH) [FF60+]
         * 0=default, 2=increased (TRR (Trusted Recursive Resolver) first), 3=max (TRR only), 5=off (no rollout)
         * see "doh-rollout.home-region": USA 2019, Canada 2021, Russia/Ukraine 2022 [3]
         * [SETTING] Privacy & Security>DNS over HTTPS
         * [1] https://hacks.mozilla.org/2018/05/a-cartoon-intro-to-dns-over-https/
         * [2] https://wiki.mozilla.org/Security/DOH-resolver-policy
         * [3] https://support.mozilla.org/kb/firefox-dns-over-https
         * [4] https://www.eff.org/deeplinks/2020/12/dns-doh-and-odoh-oh-my-year-review-2020 ***/
        unlockPref("network.trr.mode"); pref("network.trr.mode", 5); // I use my own DNS, kthx

        // These should now be fine with per-domain state partitioning in ~87+
        /* 1001: disable disk cache
         * [SETUP-CHROME] If you think disk cache helps perf, then feel free to override this
           * [NOTE] We also clear cache on exit (2803) ***/
        unlockPref("browser.cache.disk.enable"); pref("browser.cache.disk.enable", true);
        /* 1003: disable storing extra session data [SETUP-CHROME]
         * define on which sites to save extra session data such as form content, cookies and POST data
         * 0=everywhere, 1=unencrypted sites, 2=nowhere ***/
        unlockPref("browser.sessionstore.privacy_level"); pref("browser.sessionstore.privacy_level", 0);
        /* 1006: disable favicons in shortcuts
         * URL shortcuts use a cached randomly named .ico file which is stored in your
         * profile/shortcutCache directory. The .ico remains after the shortcut is deleted
         * If set to false then the shortcuts use a generic Firefox icon ***/
        unlockPref("browser.shell.shortcutFavicons"); pref("browser.shell.shortcutFavicons", true);

        /* 1246: disable HTTP background requests [FF82+]
         * When attempting to upgrade, if the server doesn't respond within 3 seconds,
         * Firefox sends HTTP requests in order to check if the server supports HTTPS or not
         * This is done to avoid waiting for a timeout which takes 90 seconds
         * [1] https://bugzilla.mozilla.org/buglist.cgi?bug_id=1642387,1660945 ***/
        unlockPref("dom.security.https_only_mode_send_http_background_request"); pref("dom.security.https_only_mode_send_http_background_request", true);

        // TODO Run my own self-hosted push server? See: https://mozilla-push-service.readthedocs.io/en/latest/#mozilla-push-service
        // unlockPref("dom.push.serverURL"); pref("dom.push.serverURL", "wss://push.services.mozilla.com/");

        // I do actually ship an extension in the application dir, and am sure as shit that no one else is in my case :^)
        /* 2660: lock down allowed extension directories
         * [SETUP-CHROME] This will break extensions, language packs, themes and any other
         * XPI files which are installed outside of profile and application directories
         * [1] https://mike.kaply.com/2012/02/21/understanding-add-on-scopes/
         * [1] https://archive.is/DYjAM (archived) ***/
        unlockPref("extensions.enabledScopes"); pref("extensions.enabledScopes", 6); // [HIDDEN PREF]
        unlockPref("extensions.autoDisableScopes"); pref("extensions.autoDisableScopes", 11); // [DEFAULT: 15]

        /* 2810: enable Firefox to clear items on shutdown
         * [NOTE] In FF129+ clearing "siteSettings" on shutdown (2811), or manually via site data (2820) and
         * via history (2830), will no longer remove sanitize on shutdown "cookie and site data" site exceptions (2815)
         * [SETTING] Privacy & Security>History>Custom Settings>Clear history when Firefox closes | Settings ***/
        unlockPref("privacy.sanitize.sanitizeOnShutdown"); pref("privacy.sanitize.sanitizeOnShutdown", false);

        /* 2840: set "Time range to clear" for "Clear Data" (2820) and "Clear History" (2830)
         * Firefox remembers your last choice. This will reset the value when you start Firefox
         * 0=everything, 1=last hour, 2=last two hours, 3=last four hours, 4=today
         * [NOTE] Values 5 (last 5 minutes) and 6 (last 24 hours) are not listed in the dropdown,
         * which will display a blank value, and are not guaranteed to work ***/
        unlockPref("privacy.sanitize.timeSpan"); pref("privacy.sanitize.timeSpan", 1);

        // TODO enable RFP once I can *separately* disable the "force 1600x900 window size on start" thing

        // TODO re-enable once I figure out a way to 'snap' window resizing to the letterboxed sizes?
        /* 4504: enable RFP letterboxing [FF67+]
         * Dynamically resizes the inner window by applying margins in stepped ranges [2]
         * If you use the dimension pref, then it will only apply those resolutions.
         * The format is "width1xheight1, width2xheight2, ..." (e.g. "800x600, 1000x1000")
         * [SETUP-WEB] This is independent of RFP (4501). If you're not using RFP, or you are but
         * dislike the margins, then flip this pref, keeping in mind that it is effectively fingerprintable
         * [WARNING] DO NOT USE: the dimension pref is only meant for testing
         * [1] https://bugzilla.mozilla.org/1407366
         * [2] https://hg.mozilla.org/mozilla-central/rev/6d2d7856e468#l2.32 ***/
        unlockPref("privacy.resistFingerprinting.letterboxing"); pref("privacy.resistFingerprinting.letterboxing", false); // [HIDDEN PREF]

        /* 4513: set all open window methods to abide by "browser.link.open_newwindow" (4512)
         * [1] https://searchfox.org/mozilla-central/source/dom/tests/browser/browser_test_new_window_from_content.js ***/
        // Instead, only abide by it in non-script windows
        unlockPref("browser.link.open_newwindow.restriction"); pref("browser.link.open_newwindow.restriction", 2);

        // Open *external* links in new tab in the last active window
        unlockPref("browser.link.open_newwindow.override.external"); pref("browser.link.open_newwindow.override.external", 3);
        /* 5003: disable saving passwords
         * [NOTE] This does not clear any passwords already saved
         * [SETTING] Privacy & Security>Logins and Passwords>Ask to save logins and passwords for websites ***/
        unlockPref("signon.rememberSignons"); lockPref("signon.rememberSignons", false);

        /* 5016: discourage downloading to desktop
         * 0=desktop, 1=downloads (default), 2=last used
         * [SETTING] To set your default "downloads": General>Downloads>Save files to ***/
        unlockPref("browser.download.folderList"); pref("browser.download.folderList", 2);

        // While having a delay is sensible, 1s is too long
        /* 6004: enforce a security delay on some confirmation dialogs such as install, open/save
         * [1] https://www.squarefree.com/2004/07/01/race-conditions-in-security-dialogs/ ***/
        unlockPref("security.dialog_enable_delay"); pref("security.dialog_enable_delay", 250); // [DEFAULT: 1000]

        lockPref("_user.js.parrot", "overrides section successful");
        // }}}

        /* Sadly crucial for not having absolutely terrible performance that
         * somehow *also* kills the performance of any GL-using stuff on the same
         * system, especially during scrolling. Does affect fingerprinting, but
         * oh well.
         */
        pref("layers.acceleration.force-enabled",   true);
        pref("webgl.force-enabled",                 true);

        /* Video acceleration
        */
        pref("media.ffmpeg.vaapi.enabled",  true);

        ${optionalString legacyShim ''
        pref("xpinstall.signatures.required", false);
        ${builtins.readFile "${legacyFox.outPath}/config.js"}
        ''}

        // Sane, personal about:config defaults {{{
        pref("general.warnOnAboutConfig", false);

        // Retain history forever
        pref("places.history.expiration.max_pages", 2147483647);


        // UI/UX
        // Dark-themed chrome (RFP prevents sites from picking up the 'dark' pref.)
        pref("ui.systemUsesDarkTheme", 1);

        // "Compact" density option for the UI
        pref("browser.uidensity", 1);

        // Disable pointless UI animations (RFP prevents sites from picking up on this pref.)
        pref("ui.prefersReducedMotion", 1);

        // Get rid of pointless URL bar element space-waster
        pref("browser.urlbar.hideGoButton", true);

        // Let tabs compress their width down further. 50 is the effective minimum AFAICT as of 2021-10-29
        pref("browser.tabs.tabMinWidth", 50);

        // Show bookmark toolbar, but only on the new/blank tab page
        pref("browser.toolbars.bookmarks.visibility", "newtab");


        // Annoyances

        // New tabs show up at the end of the bar, not next to the current tab
        // pref("browser.tabs.insertRelatedAfterCurrent", false);

        // When double-clicking to select a word, don't include the following space
        pref("layout.word_select.eat_space_to_next_word", false);

        // Allow extensions to work on AMO
        pref("extensions.webextensions.restrictedDomains", "");

        // Never show the EULA
        pref("browser.EULA.override",               true);

        // Skip showing the "select your addons" UI for bundled addons
        pref("extensions.shownSelectionUI",         true);

        // Allow desktop notifications to remain until clicked/manually acknowledged, if the source site requests it
        pref("dom.webnotifications.requireinteraction.enabled", true);

        // *Always* present the Reader Mode button in the toolbar, even if the automated parsing thinks it won't work
        pref("reader.parse-on-load.force-enable", true);
        // }}}
    '';
  } (pkgs.runCommand "${base.name}-custom" {
    paths = [
      (pkgs.writeTextDir "distribution/policies.json"
        (builtins.toJSON {
          policies = {
            DisableAppUpdate = true;
            DisableFirefoxStudies = true;
            DisablePocket = true;
            DisableTelemetry = true;
            DontCheckDefaultBrowser = true;
            # NOTE: Better handled by addons, because per-site whitelisting.
            # EnableTrackingProtection = {
            #   Value = true;
            #   Locked = false;
            # };
            FirefoxHome = {
              Search = false;
              TopSites = false;
              Highlights = false;
              Pocket = false;
              Snippets = false;
            };
            NoDefaultBookmarks = true;
            # IIRC DNS prefetching is bad opsec
            NetworkPrediction = false;
            # NewTabPage = false;
            OverrideFirstRunPage = "";
            PromptForDownloadLocation = true;
            ExtensionSettings = let
              amoUrl = addon: "https://addons.mozilla.org/firefox/downloads/latest/${addon}/latest.xpi";
            in {
              "uBlock0@raymondhill.net" = {
                installation_mode = "normal_installed";
                install_url = amoUrl "ublock-origin";
              };
              "uMatrix@raymondhill.net" = {
                installation_mode = "normal_installed";
                install_url = amoUrl "umatrix";
              };
              # "VimFx-unlisted@akhodakivskiy.github.com" = {
              #   installation_mode = "normal_installed";
              #   install_url = "https://github.com/akhodakivskiy/VimFx/releases/latest/download/VimFx.xpi";
              # };
              # Install = [
              # ];
            };
          };
        })
      )
    ] ++ lib.optional legacyShim legacyFox;
    nativeBuildInputs = with pkgs; [
      rsync gnused
    ];
    preferLocalBuild = true;
    inherit (base) meta;
    inherit base;
    inherit (base) passthru;
  } ''
    mkdir -p $out/usr
    ln -s $out/lib $out/usr/lib

    # Copy base FF files, consolidating usr/lib/ to lib/ in the output as we go
    for subpath in "$base"/*; do
      subdir="$(basename "$subpath")"
      if [[ $subdir == "usr" ]]; then
        rsync --chmod=ugo=rwX -E -avhP "$subpath"/lib/ $out/lib/
      else
        rsync --chmod=ugo=rwX -E -avhP "$subpath"/ "$out/$subdir/"
      fi
    done

    # Merge the path list in on top of the firefox lib dir
    libPath=$(echo $out/lib/*)
    for dir in $paths; do
      rsync --chmod=ugo=rwX -E -avhP "$dir"/ "$libPath"/
    done

    # Setup config.js loading, unsandboxed
    configPrefLoader="$libPath/defaults/pref/config-prefs.js"
    if [[ -e $configPrefLoader ]]; then rm -f "$configPrefLoader"; fi
    cat << EOF > "$configPrefLoader"
    pref("general.config.obscure_value", 0);
    pref("general.config.filename", "config.js");
    pref("general.config.sandbox_enabled", false);
    EOF

    # Merge all the config.js files
    confPath="$libPath/config.js"
    if [[ -e $confPath ]]; then rm -f "$confPath"; fi
    echo "// This line intentionally left blank" > "$confPath"
    for dir in $paths; do
      confSource="$dir/config.js"
      if [[ -e $confSource ]]; then
        echo "Merging in config.js from $dir"
        echo "" >> "$confPath"
        cat "$confSource" >> "$confPath"
      fi
    done

    # Binary move shenanigans
    chmod +w $out $out/bin
    rm -f $out/bin/.${binName}-wrapped
    ln -s $libPath/${binName} $out/bin/.${binName}-wrapped
    chmod +w $out/bin/${binName}
    sed -i -e "s|${base}|$out|g" $out/bin/${binName}
  '');
in
{
  nixpkgs.overlays = singleton (self: super: {
    firefox-customised = (customizeFox rec {
      # base = firefox-esr-68-unwrapped;
      base = super.firefox-unwrapped;
      libName = "firefox";
      binName = "firefox";
      legacyShim = true;
    });
    firefox-uncustomised = (super.wrapFirefox super.firefox-bin-unwrapped {
      applicationName = "firefox";
      nameSuffix = "-noprefs";
      pname = "firefox-noprefs-bin";
      desktopName = "Firefox No Upstream Prefs";
    }).overrideAttrs(oa: {
      meta = oa.meta or {} // {
        priority = 1000;
      };
    });
  });
  home.packages = with pkgs; [
    firefox-customised
    firefox-uncustomised
  ];
  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
  };
}
