{ stdenv, lib, pkgconfig, go, fetchhg, fetchgit }:

let
  goDeps = [
    {
      root = "bitbucket.org/pkg/inflect";
      src = fetchhg {
        url = "https://bitbucket.org/pkg/inflect";
        rev = "8961c3750a47";
        sha256 = "11qdyr5gdszy24ai1bh7sf0cgrb4q7g7fsd11kbpgj5hjiigxb9a";
      };
    }
    {
      root = "code.google.com/p/go-html-transform";
      src = fetchhg {
        url = "https://code.google.com/p/go-html-transform/";
        rev = "744851c9d579";
        sha256 = "024g0wjg55iqidavyv06nfjpiihr7rgc0mqnfgp80p4qyxpw8v3i";
      };
    }
    {
      root = "code.google.com/p/go.net";
      src = fetchhg {
        url = "https://code.google.com/p/go.net";
        rev = "ad01a6fcc8a1";
        sha256 = "0s0aa8hxrpggn6wwx4x591k6abvawrmhsk8ji327pgj08fdy3ahq";
      };
    }
    {
      root = "github.com/BurntSushi/toml";
      src = fetchgit {
        url = "https://github.com/BurntSushi/toml";
        rev = "2ceedfee35ad3848e49308ab0c9a4f640cfb5fb2";
        sha256 = "7caffacbcdef8ca1bd9e428e225f7733263f0cae4c1d61c5cc63b9590de45f8c";
      };
    }
    {
      root = "github.com/PuerkitoBio/purell";
      src = fetchgit {
        url = "https://github.com/PuerkitoBio/purell";
        rev = "1909519b19f44750062c3e8209d65c0921f18060";
        sha256 = "1d49f99690a0f3bec968c80a68e6f8d33d62b3e15f1f0f553c9da808d802b5d4";
      };
    }
    {
      root = "github.com/eknkc/amber";
      src = fetchgit {
        url = "https://github.com/eknkc/amber";
        rev = "b187d12d7712af498216fa03316d8c55d34a16a1";
        sha256 = "a3548b1fd3cd66161128dd221360df00402618a5f8aea9e63ca7297a45f6abcf";
      };
    }
    {
      root = "github.com/gorilla/websocket";
      src = fetchgit {
        url = "https://github.com/gorilla/websocket";
        rev = "4292df70df546334d4174bcd77271253c9b7835c";
        sha256 = "349f9aa38225d28d01784d18e87c7ac5fae9d1cdcf20b272458525b163599d35";
      };
    }
    {
      root = "github.com/howeyc/fsnotify";
      src = fetchgit {
        url = "https://github.com/howeyc/fsnotify";
        rev = "6b1ef893dc11e0447abda6da20a5203481878dda";
        sha256 = "69836ddf58022dbd529bf8e52d9419b61f2e103f9e0195211f67145b6a36e8bb";
      };
    }
    {
      root = "github.com/kr/pretty";
      src = fetchgit {
        url = "https://github.com/kr/pretty";
        rev = "f31442d60e51465c69811e2107ae978868dbea5c";
        sha256 = "7eadcede886d18792e5ea84e69dff1efba31c56e48b5772b44eb9ae9abf27f68";
      };
    }
    {
      root = "github.com/kr/text";
      src = fetchgit {
        url = "https://github.com/kr/text";
        rev = "6807e777504f54ad073ecef66747de158294b639";
        sha256 = "2819a24a975a00b880279a8f5771e3f159dd16623ad1ab1f1f597d049efe7af2";
      };
    }
    {
      root = "github.com/mitchellh/mapstructure";
      src = fetchgit {
        url = "https://github.com/mitchellh/mapstructure";
        rev = "740c764bc6149d3f1806231418adb9f52c11bcbf";
        sha256 = "8b1d057abc49ca24eb3719b2b00f6f18308f8a0d78ffca41b6c5905ff3489f66";
      };
    }
    {
      root = "github.com/mostafah/fsync";
      src = fetchgit {
        url = "https://github.com/mostafah/fsync";
        rev = "5812dc64b09a3653a10606bbfc65d18d38541480";
        sha256 = "c487dbaccf78eba213608b579e10d66584541b73de5728021dc2b289c7c97bc9";
      };
    }
    {
      root = "github.com/russross/blackfriday";
      src = fetchgit {
        url = "https://github.com/russross/blackfriday";
        rev = "52f7a2a7b02d11db19411c28e6c67fc351f20aaf";
        sha256 = "eee0b00129c474b9051cd0ed6d9bd7c46a8cf8a5db252e95e444664d40cffc00";
      };
    }
    {
      root = "github.com/spf13/cast";
      src = fetchgit {
        url = "https://github.com/spf13/cast";
        rev = "99f1223ff64ed0c6a1dd9c850474f5fecba6e0a4";
        sha256 = "28744bda8b9f2b1c7591ca00097c8d19ede5296bb45c60fd68d205554bc61053";
      };
    }
    {
      root = "github.com/spf13/cobra";
      src = fetchgit {
        url = "https://github.com/spf13/cobra";
        rev = "8d72c1e167c7ed194f28b625cbe835495aaa55fa";
        sha256 = "427aa15c5dbf60ce120bb552e23823954dd8fc99578da1c94d8f7d6329e54c21";
      };
    }
    {
      root = "jww";
      src = fetchgit {
        url = "https://github.com/spf13/jwalterweatherman";
        rev = "e3682f3b5526cf86abc2d415aa312cd5531e3d0a";
        sha256 = "0edbdb5974f5a2fc1d604a7d5e5a91392da6af74547a2e8cf530b9030e3fcfc3";
      };
    }
    {
      root = "github.com/spf13/jwalterweatherman";
      src = fetchgit {
        url = "https://github.com/spf13/jwalterweatherman";
        rev = "e3682f3b5526cf86abc2d415aa312cd5531e3d0a";
        sha256 = "0edbdb5974f5a2fc1d604a7d5e5a91392da6af74547a2e8cf530b9030e3fcfc3";
      };
    }
    {
      root = "github.com/spf13/nitro";
      src = fetchgit {
        url = "https://github.com/spf13/nitro";
        rev = "24d7ef30a12da0bdc5e2eb370a79c659ddccf0e8";
        sha256 = "2b56a3416a9b74d83130d6e86bcdb6cc3c49a8e9a16caf9043ee3509fa5d7a90";
      };
    }
    {
      root = "github.com/spf13/viper";
      src = fetchgit {
        url = "https://github.com/spf13/viper";
        rev = "2b24bea958e2d411fc25a82e44fbbcc3b6ed0441";
        sha256 = "92c1480622da1b8c586b13a4df08398364b68fbbf17bfd23a5f39eb975ea601a";
      };
    }
    {
      root = "github.com/spf13/pflag";
      src = fetchgit {
        url = "https://github.com/spf13/pflag";
        rev = "463bdc838f2b35e9307e91d480878bda5fff7232";
        sha256 = "2bf86a42486c8f9614a8250447899be606cdd0043201e3cf3b9234cf7ad4cfac";
      };
    }
    {
      root = "gopkg.in/yaml.v1";
      src = fetchgit {
        url = "https://gopkg.in/yaml.v1";
        rev = "feb4ca79644e8e7e39c06095246ee54b1282c118";
        sha256 = "f8b084a9faba09c71dd0a9a47ba1e1b47b903429c32cc514ddc3c614675f864a";
      };
    }
  ];
in

stdenv.mkDerivation rec {
  name = "hugo-${version}";
  version = "0.11";

  src = fetchgit {
    url = "https://github.com/spf13/hugo";
    rev = "867683e473c9ee94c0e79339510f6ecdfa4758e5";
    sha256 = "9fde9e922047eb2badabdb05b0a3486c7887710c5685fa4e7c0f064091001963";
  };

  buildInputs = [ go ];

  preBuild = ''
    export HOME="$PWD"

    mkdir -p src/github.com/spf13/
    ln -s $PWD src/github.com/spf13/hugo
    ${lib.concatStrings
      (map (dep: ''
              mkdir -p src/`dirname ${dep.root}`
              ln -s ${dep.src} src/${dep.root}
            '') goDeps)}
  '';

  installPhase = ''
    export GOPATH=$PWD

    mkdir -p $out/bin

    #cd $src/src/github.com/spf13/hugo
    go build -o "$out/bin/hugo" main.go
  '';
    

  meta = {
    description = "Hugo is a static site generator written in Go. It is optimized for speed, easy use and configurability.";
    longDescription = ''
      Hugo is a static site generator written in Go. It is optimized for speed, easy use and configurability. Hugo takes a directory with content and templates and renders them into a full html website.
      
      Hugo makes use of markdown files with front matter for meta data.
      
      A typical website of moderate size can be rendered in a fraction of a second. A good rule of thumb is that Hugo takes around 1 millisecond for each piece of content.
      
      It is written to work well with any kind of website including blogs, tumbles and docs.
    '';
    homepage = https://github.com/spf13/hugo;
    license = "Simple Public License 2.0";
    maintainers = stdenv.lib.maintainers.arobyn;
    platforms = stdenv.lib.platforms.unix;
  };
}
