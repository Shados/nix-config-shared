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
  # legacyFox = pkgs.stdenv.mkDerivation {
  #   name = "legacyfox";
  #   src = pkgs.fetchFromGitHub {
  #     owner = "girst"; repo = "LegacyFox";
  #     rev = "54655696e65acc67ec73f01932fa2ddb1e236a78";
  #     sha256 = "1qzyf2bv5zvf95qz9yxgcpmsgadzsvd7rdqxkhmg5x65an3gbnyg";
  #   };
  #   preferLocalBuild = true;
  #   DESTDIR="$(out)";
  # };
  # FIXME: This is mostly just a local copy of legacyFox, but I no longer
  # recall *why* I needed a local version. I *think* there's some tweaks I
  # needed for... something? Will need to diff it against current stuff and
  # find out what, if anything, is different, then probably move to just
  # maintaining a fork or a patch rather than this clusterfuck.
  legacyFox = pkgs.runCommand "legacyFox" {
    src = ./legacyFox;
    preferLocalBuild = true;
  } ''
    mkdir -p $out
    cp -r "$src"/* $out/
  '';
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

        /* 0705: disable DNS-over-HTTPS (DoH) rollout [FF60+]
         * 0=off by default, 2=TRR (Trusted Recursive Resolver) first, 3=TRR only, 5=explicitly off
         * see "doh-rollout.home-region": USA Feb 2020, Canada July 2021 [3]
         * [1] https://hacks.mozilla.org/2018/05/a-cartoon-intro-to-dns-over-https/
         * [2] https://wiki.mozilla.org/Security/DOH-resolver-policy
         * [3] https://blog.mozilla.org/mozilla/news/firefox-by-default-dns-over-https-rollout-in-canada/
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

        // Needed to allow AusPost's parcel tracking page to function
        /* 1601: control when to send a cross-origin referer
         * 0=always (default), 1=only if base domains match, 2=only if hosts match
         * [SETUP-WEB] Known to cause issues with older modems/routers and some sites e.g vimeo, icloud, instagram ***/
        unlockPref("network.http.referer.XOriginPolicy"); pref("network.http.referer.XOriginPolicy", 1);

        /* 2302: disable service workers [FF32, FF44-compat]
         * Service workers essentially act as proxy servers that sit between web apps, and the
         * browser and network, are event driven, and can control the web page/site they are associated
         * with, intercepting and modifying navigation and resource requests, and caching resources.
         * [NOTE] Service workers require HTTPS, have no DOM access, and are not supported in PB mode [1]
         * [SETUP-WEB] Disabling service workers will break some sites. This pref is required true for
         * service worker notifications (2304), push notifications (disabled, 2305) and service worker
         * cache (2740). If you enable this pref, then check those settings as well
         * [1] https://bugzilla.mozilla.org/show_bug.cgi?id=1320796#c7 ***/
        unlockPref("dom.serviceWorkers.enabled"); pref("dom.serviceWorkers.enabled", true);

        // TODO Run my own self-hosted push server? See: https://mozilla-push-service.readthedocs.io/en/latest/#mozilla-push-service
        // unlockPref("dom.push.serverURL"); pref("dom.push.serverURL", "wss://push.services.mozilla.com/");
        /* 2305: disable Push Notifications [FF44+]
         * Push is an API that allows websites to send you (subscribed) messages even when the site
         * isn't loaded, by pushing messages to your userAgentID through Mozilla's Push Server
         * [NOTE] Push requires service workers (2302) to subscribe to and display, and is behind
         * a prompt (7002). Disabling service workers alone doesn't stop Firefox polling the
         * Mozilla Push Server. To remove all subscriptions, reset your userAgentID.
         * [1] https://support.mozilla.org/kb/push-notifications-firefox
         * [2] https://developer.mozilla.org/docs/Web/API/Push_API ***/
        unlockPref("dom.push.enabled"); pref("dom.push.enabled", true);
           // unlockPref("dom.push.userAgentID"); pref("dom.push.userAgentID", "");

        // The mitigation in 2404 is sufficient
        /* 2403: block popup windows
         * [SETTING] Privacy & Security>Permissions>Block pop-up windows ***/
        unlockPref("dom.disable_open_during_load"); pref("dom.disable_open_during_load", false);

        // I do actually ship an extension in the application dir, and am sure as shit that no one else is in my case :^)
        /* 2660: lock down allowed extension directories
         * [SETUP-CHROME] This will break extensions, language packs, themes and any other
         * XPI files which are installed outside of profile and application directories
         * [1] https://mike.kaply.com/2012/02/21/understanding-add-on-scopes/
         * [1] https://archive.is/DYjAM (archived) ***/
        unlockPref("extensions.enabledScopes"); pref("extensions.enabledScopes", 6); // [HIDDEN PREF]
        unlockPref("extensions.autoDisableScopes"); pref("extensions.autoDisableScopes", 11); // [DEFAULT: 15]

        /* 2801: delete cookies and site data on exit
         * 0=keep until they expire (default), 2=keep until you close Firefox
         * [NOTE] A "cookie" block permission also controls localStorage/sessionStorage, indexedDB,
         * sharedWorkers and serviceWorkers. serviceWorkers require an "Allow" permission
         * [SETTING] Privacy & Security>Cookies and Site Data>Delete cookies and site data when Firefox is closed
         * [SETTING] to add site exceptions: Ctrl+I>Permissions>Cookies>Allow
         *   If using FPI the syntax must be https://example.com/^firstPartyDomain=example.com
         * [SETTING] to manage site exceptions: Options>Privacy & Security>Permissions>Settings ***/
        unlockPref("network.cookie.lifetimePolicy"); pref("network.cookie.lifetimePolicy", 0);

        /* 2802: enable Firefox to clear items on shutdown (2803)
         * [SETTING] Privacy & Security>History>Custom Settings>Clear history when Firefox closes ***/
        unlockPref("privacy.sanitize.sanitizeOnShutdown"); pref("privacy.sanitize.sanitizeOnShutdown", false);

        /* 2806: reset default "Time range to clear" for "Clear Recent History" (2804)
         * Firefox remembers your last choice. This will reset the value when you start Firefox
         * 0=everything, 1=last hour, 2=last two hours, 3=last four hours, 4=today
         * [NOTE] Values 5 (last 5 minutes) and 6 (last 24 hours) are not listed in the dropdown,
         * which will display a blank value, and are not guaranteed to work ***/
        unlockPref("privacy.sanitize.timeSpan"); pref("privacy.sanitize.timeSpan", 1);

        // TODO re-enable once I can *separately* disable the "force 1600x900 window size on start" thing
        /* 4501: enable privacy.resistFingerprinting [FF41+]
         * [SETUP-WEB] RFP can cause some website breakage: mainly canvas, use a site exception via the urlbar
         * RFP also has a few side effects: mainly timezone is UTC0, and websites will prefer light theme
         * [1] https://bugzilla.mozilla.org/418986 ***/
        unlockPref("privacy.resistFingerprinting"); pref("privacy.resistFingerprinting", false);

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

        /* 4512: enforce links targeting new windows to open in a new tab instead
         * 1=most recent window or tab, 2=new window, 3=new tab
         * Stops malicious window sizes and some screen resolution leaks.
         * You can still right-click a link and open in a new window
         * [SETTING] General>Tabs>Open links in tabs instead of new windows
         * [TEST] https://arkenfox.github.io/TZP/tzp.html#screen
         * [1] https://gitlab.torproject.org/tpo/applications/tor-browser/-/issues/9881 ***/
        unlockPref("browser.link.open_newwindow"); pref("browser.link.open_newwindow", 3);
        /* 4513: set all open window methods to abide by "browser.link.open_newwindow" (4512)
         * [1] https://searchfox.org/mozilla-central/source/dom/tests/browser/browser_test_new_window_from_content.js ***/
        // Instead, only abide by it in non-script windows
        unlockPref("browser.link.open_newwindow.restriction"); pref("browser.link.open_newwindow.restriction", 2);

        // Open *external* links in new tab in the last active window
        unlockPref("browser.link.open_newwindow.override.external"); pref("browser.link.open_newwindow.override.external", 3);

        // See later non-override note
        /* 4520: disable WebGL (Web Graphics Library)
         * [SETUP-WEB] If you need it then enable it. RFP still randomizes canvas for naive scripts ***/
        unlockPref("webgl.disabled"); pref("webgl.disabled", false);

        /* 5003: disable saving passwords
         * [NOTE] This does not clear any passwords already saved
         * [SETTING] Privacy & Security>Logins and Passwords>Ask to save logins and passwords for websites ***/
        unlockPref("signon.rememberSignons"); pref("signon.rememberSignons", false);

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
         * RFP mitigates WebGL stuff.
         */
        pref("layers.acceleration.force-enabled",   true);
        pref("webgl.force-enabled",                 true);

        /* Video acceleration
        */
        pref("media.ffmpeg.vaapi.enabled",  true);

        ${optionalString legacyShim ''
        pref("xpinstall.signatures.required", false);
        ${builtins.readFile ./legacyFox/config.js}
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
  home.packages = with pkgs; [
    (customizeFox rec {
      # base = firefox-esr-68-unwrapped;
      base = firefox-unwrapped;
      libName = "firefox";
      binName = "firefox";
      legacyShim = true;
    })
    ((wrapFirefox firefox-bin-unwrapped {
      applicationName = "firefox";
      nameSuffix = "-noprefs";
      pname = "firefox-noprefs-bin";
      desktopName = "Firefox No Upstream Prefs";
    }).overrideAttrs(oa: {
      meta = oa.meta or {} // {
        priority = 1000;
      };
    }))
  ];
  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
  };
}
