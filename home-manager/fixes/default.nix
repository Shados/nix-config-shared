{ config, inputs, lib, pkgs, ... }:
with lib;
{
  nixpkgs.overlays = [
    (self: super: {
      geeqie = super.geeqie.overrideAttrs(oa: rec {
        configureFlags = oa.configureFlags or [] ++ [
          "--disable-gpu-accel" # GPU acceleration has been varyingly buggy and slow since ~1.6.0, disable it for now
        ];
      });
    })
    (self: super: super.lib.defineLuaPackageOverrides super [(luaself: luasuper: {
      luasystem = luasuper.luaLib.overrideLuarocks luasuper.luasystem (drv: {
        buildInputs = super.lib.optionals super.stdenv.isLinux [
          super.glibc.out
        ];
      });
    })])
    (self: super: with super.lib; {
      puddletag = super.puddletag.overridePythonAttrs(oa: {
        makeWrapperArgs = [
          "\${qtWrapperArgs[@]}"
        ];
      });
      youtube-dl = super.youtube-dl.overrideAttrs(oa: {
        patches = oa.patches or [] ++ [
          ../fixes/youtube-dl-uploader-id.patch
        ];
      });
    })
    # (self: super: {
    #   obs-studio-caffeine = super.obs-studio.overrideAttrs(oa: rec {
    #     pname = "obs-studio";
    #     version = "27.1.2-caffeine";

    #     src = super.fetchFromGitHub {
    #       owner = "caffeinetv"; repo = "obs-studio";
    #       rev = "e962e18dec1afe13704f80d5f4e5fa9fefff239f";
    #       sha256 = "sha256-I8pCoZgx2lUzi5MZZqI5hd//WHhvgJFgbyvEvo81LoU=";
    #     };

    #     patches = [
    #       "${inputs.nixpkgs.outPath}/pkgs/applications/video/obs-studio/fix-nix-plugin-path.patch"
    #     ];

    #     cmakeFlags = oa.cmakeFlags ++ [
    #       # "-DENABLE_QSV11=OFF"
    #       "-DOBS_VERSION_OVERRIDE=${version}"
    #     ];

    #     buildInputs = oa.buildInputs ++ [
    #       self.libcaffeine
    #     ];
    #   });

    #   libcaffeine = super.lib.flip super.callPackage {
    #     inherit (self) webrtc-libcaffeine;
    #   } (
    #     { lib, stdenv
    #     , fetchFromGitHub
    #     , cmake
    #     , webrtc-libcaffeine
    #     }:
    #     stdenv.mkDerivation rec {
    #       pname = "libcaffeine";
    #       version = "0.6.6";

    #       src = fetchFromGitHub {
    #         owner = "caffeinetv"; repo = "libcaffeine";
    #         rev = "v${version}";
    #         sha256 = "sha256-Wh7ckGLGRNRbxuL4Sba/k+fmE33Gtd4a2Lac+2no2kk=";
    #       };

    #       nativeBuildInputs = [
    #         cmake
    #       ];

    #       buildInputs = [
    #         webrtc-libcaffeine
    #       ];
    #     }
    #   );

    #   webrtc-libcaffeine = super.lib.flip super.callPackage { } (
    #     { lib, stdenv
    #     , fetchFromGitHub, fetchgit
    #     , gn, ninja, python3
    #     }:
    #     let
    #       # This data is from the DEPS file in the root of the webrtc-libcaffeine checkout.
    #       chromium_git = "https://chromium.googlesource.com";
    #       deps = {
    #         "build" = fetchgit {
    #           url    = "${chromium_git}/chromium/src/build.git";
    #           rev    = "c9333f9faf6ad7856f6aa04b2c78a115c2f0b9ee";
    #           sha256 = "sha256-6AYRsznjLK1OjfOvxW9LZghYPpvZD8+zSRLfcDQTkT4=";
    #         };
    #         "testing" = fetchgit {
    #           url    = "${chromium_git}/chromium/src/testing.git";
    #           rev    = "b47e929d27fe950ce868b28ad5b6c208278734e4";
    #           sha256 = "sha256-Ii/vojNdKr3OJAjCM5pyLYCpJoj1Je1h0rRNXSx5gVo=";
    #         };
    #         # NOTE: the DEPS file doesn't actually specify a rev for this, because fuck me I guess
    #         "third_party/protobuf" = fetchgit {
    #           url    = "${chromium_git}/chromium/src/third_party/protobuf.git";
    #           rev    = "6c3ba5db8e555adbbe72a57a745bdccccb4761a2";
    #           sha256 = "sha256-96wLOQiz5xA10URYat+fJPrftnVU84CU2F+jX+d65dM=";
    #           # sha256 = lib.fakeHash;
    #         };
    #         # "base/trace_event/common" = fetchgit {
    #         #   url    = "${chromium_git}/chromium/src/base/trace_event/common.git";
    #         #   rev    = "7f36dbc19d31e2aad895c60261ca8f726442bfbb";
    #         #   sha256 = "01b2fhbxznqbakxv42ivrzg6w8l7i9yrd9nf72d6p5xx9dm993j4";
    #         # };
    #         # "third_party/googletest/src" = fetchgit {
    #         #   url    = "${chromium_git}/external/github.com/google/googletest.git";
    #         #   rev    = "16f637fbf4ffc3f7a01fa4eceb7906634565242f";
    #         #   sha256 = "11012k3c3mxzdwcw2iparr9lrckafpyhqzclsj26hmfbgbdi0rrh";
    #         # };
    #         # "third_party/icu" = fetchgit {
    #         #   url    = "${chromium_git}/chromium/deps/icu.git";
    #         #   rev    = "eedbaf76e49d28465d9119b10c30b82906e606ff";
    #         #   sha256 = "0mppvx7wf9zlqjsfaa1cf06brh1fjb6nmiib0lhbb9hd55mqjdjj";
    #         # };
    #         # "third_party/zlib" = fetchgit {
    #         #   url    = "${chromium_git}/chromium/src/third_party/zlib.git";
    #         #   rev    = "6da1d53b97c89b07e47714d88cab61f1ce003c68";
    #         #   sha256 = "0v7ylmbwfwv6w6wp29qdf77kjjnfr2xzin08n0v1yvbhs01h5ppy";
    #         # };
    #         # "third_party/jinja2" = fetchgit {
    #         #   url    = "${chromium_git}/chromium/src/third_party/jinja2.git";
    #         #   rev    = "ee69aa00ee8536f61db6a451f3858745cf587de6";
    #         #   sha256 = "1fsnd5h0gisfp8bdsfd81kk5v4mkqf8z368c7qlm1qcwc4ri4x7a";
    #         # };
    #         # "third_party/markupsafe" = fetchgit {
    #         #   url    = "${chromium_git}/chromium/src/third_party/markupsafe.git";
    #         #   rev    = "1b882ef6372b58bfd55a3285f37ed801be9137cd";
    #         #   sha256 = "1jnjidbh03lhfaawimkjxbprmsgz4snr0jl06630dyd41zkdw5kr";
    #         # };
    #       };
    #     in
    #     stdenv.mkDerivation rec {
    #       pname = "webrtc";
    #       version = "v70.x-libcaffeine";

    #       src = fetchFromGitHub {
    #         owner = "caffeinetv"; repo = "webrtc";
    #         rev = "024e28caf6e7e3dd722ae4ce57bf4d096290cc51";
    #         sha256 = "sha256-B6BywuXCIp1kK9UnsZFJdB3lBxa9ltgJpE9cnwdrxyM=";
    #       };

    #       nativeBuildInputs = [
    #         gn ninja python3
    #       ];

    #       postUnpack = ''
    #         ${lib.concatStringsSep "\n" (
    #           lib.mapAttrsToList (n: v: ''
    #             mkdir -p $sourceRoot/${n}
    #             cp -r ${v}/* $sourceRoot/${n}
    #           '') deps)}
    #         chmod u+w -R .
    #       '';

    #       gnFlags = [
    #         "is_debug=false"
    #         "use_sysroot=false"
    #       ];
    #     }
    #   );
    # })
    # # OBS + WebRTC experimentation
    # (self: super: let
    #   inherit (super.lib) getVersion versionAtLeast;
    # in {
    #   obs-studio = if versionAtLeast (getVersion super.obs-studio) "30.0.0"
    #     then super.obs-studio
    #     else super.obs-studio.overrideAttrs(oa: rec {
    #       version = "30.0.0-beta2";

    #       src = super.fetchFromGitHub {
    #         owner = "obsproject"; repo = "obs-studio";
    #         rev = version;
    #         sha256 = "sha256-OhsPKLNzA88PecIduB8GsxvyzRwIrdxYQbJVJIspfuQ=";
    #         fetchSubmodules = true;
    #       };

    #       # patches = oa.patches ++ [
    #       #   # "${inputs.nixpkgs.outPath}/pkgs/applications/video/obs-studio/Enable-file-access-and-universal-access-for-file-URL.patch"
    #       #   # "${inputs.nixpkgs.outPath}/pkgs/applications/video/obs-studio/fix-nix-plugin-path.patch"
    #       #   (super.fetchpatch {
    #       #     name = "webrtc-av1.patch";
    #       #     sha256 = "sha256-TbzRddx9e9Kc4zBR69CRN/lpr4sy7rSxX8qxMG4RxHk=";
    #       #     url = "https://github.com/obsproject/obs-studio/pull/9331.patch";
    #       #   })
    #       #   # (super.fetchpatch {
    #       #   #   name = "libdatachannel-cpp.patch";
    #       #   #   sha256 = "sha256-froBZRUA/LwKM/XoDOzXl0BW6nic4UP4LRad0Gyj9xQ=";
    #       #   #   url = "https://github.com/obsproject/obs-studio/pull/9286.patch";
    #       #   # })
    #       # #   # NOTE: conflicts with av1 patch in ways that aren't entirely trivial to fix
    #       # #   # (super.fetchpatch {
    #       # #   #   name = "webrtc-aac.patch";
    #       # #   #   sha256 = "sha256-X+4qlg0RcuhYDCtm+xMrNWGIB90RGVGljXqFMpZ72L8=";
    #       # #   #   url = "https://github.com/obsproject/obs-studio/pull/9567.patch";
    #       # #   # })
    #       # ];

    #       cmakeFlags = oa.cmakeFlags ++ [
    #         "-DENABLE_QSV11=OFF"
    #         "-DOBS_VERSION_OVERRIDE=${version}"
    #       ];

    #       buildInputs = oa.buildInputs ++ [
    #         self.qrcodegencpp
    #         self.libdatachannel-obs
    #       ];
    #     });
    #   libdatachannel-obs = super.libdatachannel.overrideAttrs(oa: rec {
    #     version = "0.19.0-alpha.4";
    #     src = super.fetchFromGitHub {
    #       owner = "paullouisageneau"; repo = "libdatachannel";
    #       rev = "v${version}";
    #       sha256 = "sha256-PRH0XfO+nr6KQfWmeV5S7VsWF6HxFB44DSrO1I9CI6g=";
    #     };

    #     buildInputs = oa.buildInputs or [] ++ [
    #       self.mbedtls
    #       super.plog
    #       super.usrsctp
    #     ];

    #     cmakeFlags = oa.cmakeFlags ++ [
    #       "-DUSE_SYSTEM_PLOG=ON"
    #       "-DUSE_MBEDTLS=1"
    #     ];

    #     postPatch = let
    #       customUsrsctp = super.usrsctp.overrideAttrs (finalAttrs: previousAttrs: {
    #         version = "unstable-2023-08-14";
    #         src = super.fetchFromGitHub {
    #           owner = "sctplab";
    #           repo = "usrsctp";
    #           rev = "5ca29ac7d8055802c7657191325c06386640ac24";
    #           hash = "sha256-QjRis6c3WfTIfhkRmysQtJEuC599cGluAbb9i4p1cK0=";
    #         };
    #       });
    #     in ''
    #       mkdir -p deps/usrsctp
    #       cp -r --no-preserve=mode ${pkgs.srcOnly customUsrsctp}/. deps/usrsctp
    #     '';
    #   });
    #   mbedtls = super.mbedtls.overrideAttrs(oa: rec {
    #     postConfigure = oa.postConfigure + ''
    #       perl scripts/config.pl set MBEDTLS_SSL_DTLS_SRTP
    #     '';
    #   });
    #   obs-studio-plugins = super.obs-studio-plugins // {
    #     obs-pipewire-audio-capture = if versionAtLeast (getVersion super.obs-studio-plugins.obs-pipewire-audio-capture) "1.1.1"
    #       then super.obs-studio-plugins.obs-pipewire-audio-capture
    #       else super.obs-studio-plugins.obs-pipewire-audio-capture.overrideAttrs(oa: rec {
    #         version = "1.1.1";
    #         src = super.fetchFromGitHub {
    #           owner = "dimtpap";
    #           repo = "obs-pipewire-audio-capture";
    #           rev = version;
    #           sha256 = "sha256-D4ONz/4S5Kt23Tmfa6jvw0X7680R9YDqG8/N6HhIQLE=";
    #         };
    #         preConfigure = ":";
    #       });
    #   };
    #   qrcodegencpp = super.qrcodegen.overrideAttrs(oa: {
    #     pname = "qrcodegencpp";
    #     sourceRoot = "${oa.src.name}/cpp";
    #     doCheck = false;
    #     installPhase = ''
    #       runHook preInstall

    #       install -Dt $out/lib/ libqrcodegencpp.a
    #       install -Dt $out/include/qrcodegencpp/ qrcodegen.hpp

    #       runHook postInstall
    #     '';
    #   });
    # })
  ];
  # Fix for home-manager issues #730 and #909 is using the non-"legacy" systemd
  # script, which for some reason isn't enabled by default
  systemd.user.startServices = true;
}
