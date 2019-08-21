
/* generated-packages.nix is an auto-generated file -- DO NOT EDIT!
Regenerate it with:
nixpkgs$ /home/shados/nixpkgs-local/maintainers/scripts/update-luarocks-packages generated-packages.nix

These packages are manually refined in lua-overrides.nix
*/
{ self, stdenv, fetchurl, fetchgit, pkgs, ... } @ args:
self: super:
with self;
{

alt-getopt = buildLuarocksPackage {
  pname = "alt-getopt";
  version = "0.8.0-1";

  src = fetchurl {
    url    = https://luarocks.org/alt-getopt-0.8.0-1.src.rock;
    sha256 = "1mi97dqb97sf47vb6wrk12yf1yxcaz0asr9gbgwyngr5n1adh5i3";
  };
  disabled = (luaOlder "5.1") || (luaAtLeast "5.4");
  propagatedBuildInputs = [ lua ];

  meta = with stdenv.lib; {
    homepage = "https://github.com/cheusov/lua-alt-getopt";
    description = "Process application arguments the same way as getopt_long";
    maintainers = with maintainers; [ arobyn ];
    license = {
      fullName = "MIT/X11";
    };
  };
};
cmark = buildLuarocksPackage {
  pname = "cmark";
  version = "0.29.0-1";

  src = fetchurl {
    url    = https://luarocks.org/cmark-0.29.0-1.src.rock;
    sha256 = "04a039jmyk6scl1frkqf38qwnb095c43rr0ygz3qcjaq9vb7kdg2";
  };

  meta = with stdenv.lib; {
    homepage = "https://github.com/jgm/cmark-lua";
    description = "Lua wrapper for libcmark, CommonMark Markdown parsing\
      and rendering library";
    maintainers = with maintainers; [ arobyn ];
    license = {
      fullName = "BSD2";
    };
  };
};
copas = buildLuarocksPackage {
  pname = "copas";
  version = "2.0.2-1";

  src = fetchurl {
    url    = https://luarocks.org/copas-2.0.2-1.src.rock;
    sha256 = "01viw2d3aishkkfak3mf33whwr04jcckkckm25ap3g1k8r7yvvgg";
  };
  disabled = (luaOlder "5.1") || (luaAtLeast "5.4");
  propagatedBuildInputs = [ lua luasocket coxpcall ];

  meta = with stdenv.lib; {
    homepage = "http://www.keplerproject.org/copas/";
    description = "Coroutine Oriented Portable Asynchronous Services";
    maintainers = with maintainers; [ arobyn ];
    license = {
      fullName = "MIT/X11";
    };
  };
};
etlua = buildLuarocksPackage {
  pname = "etlua";
  version = "1.3.0-1";

  src = fetchurl {
    url    = https://luarocks.org/etlua-1.3.0-1.src.rock;
    sha256 = "029710wg0viwf57f97sqwjqrllcbj8a4igj31rljkiisyf36y6ka";
  };
  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ lua ];

  meta = with stdenv.lib; {
    homepage = "https://github.com/leafo/etlua";
    description = "Embedded templates for Lua";
    maintainers = with maintainers; [ arobyn ];
    license = {
      fullName = "MIT";
    };
  };
};
inotify = buildLuarocksPackage {
  pname = "inotify";
  version = "0.5-1";

  knownRockspec = (fetchurl {
    url    = https://luarocks.org/inotify-0.5-1.rockspec;
    sha256 = "0mwzzhhlwpk7gsbvv23ln486ay27z3l849nga2mh3vli6dc1l0m2";
  }).outPath;

  src = fetchurl {
    url    = https://github.com/hoelzro/linotify/archive/0.5.tar.gz;
    sha256 = "0f73fh1gqjs6vvaii1r2y2266vbicyi18z9sj62plfa3c3qhbl11";
  };

  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ lua ];

  meta = with stdenv.lib; {
    homepage = "http://hoelz.ro/projects/linotify";
    description = "Inotify bindings for Lua";
    maintainers = with maintainers; [ arobyn ];
    license = {
      fullName = "MIT";
    };
  };
};
lcmark = buildLuarocksPackage {
  pname = "lcmark";
  version = "0.29.0-1";

  src = fetchurl {
    url    = https://luarocks.org/lcmark-0.29.0-1.src.rock;
    sha256 = "06czs84rnvhaqrw3afcjsv60lgn06rg0ckgmz9brxbcpv76wig4n";
  };
  disabled = (luaOlder "5.2");
  propagatedBuildInputs = [ lua cmark yaml lpeg optparse ];

  meta = with stdenv.lib; {
    homepage = "https://github.com/jgm/lcmark";
    description = "A command-line CommonMark converter with flexible\
      features, and a lua module that exposes these features.";
    maintainers = with maintainers; [ arobyn ];
    license = {
      fullName = "BSD2";
    };
  };
};
ldbus = buildLuarocksPackage {
  pname = "ldbus";
  version = "scm-0";

  knownRockspec = (fetchurl {
    url    = https://luarocks.org/manifests/daurnimator/ldbus-scm-0.rockspec;
    sha256 = "1yhkw5y8h1qf44vx31934k042cmnc7zcv2k0pv0g27wsmlxrlznx";
  }).outPath;

  src = fetchgit ( removeAttrs (builtins.fromJSON ''{
  "url": "git://github.com/daurnimator/ldbus.git",
  "rev": "9e176fe851006037a643610e6d8f3a8e597d4073",
  "date": "2019-08-16T14:26:05+10:00",
  "sha256": "06wcz4i5b7kphqbry274q3ivnsh331rxiyf7n4qk3zx2kvarq08s",
  "fetchSubmodules": true
}
 '') ["date"]) ;

  disabled = (luaOlder "5.1") || (luaAtLeast "5.4");
  propagatedBuildInputs = [ lua ];

  meta = with stdenv.lib; {
    homepage = "https://github.com/daurnimator/ldbus";
    description = "A Lua library to access dbus.";
    maintainers = with maintainers; [ arobyn ];
    license = {
      fullName = "MIT/X11";
    };
  };
};
linenoise = buildLuarocksPackage {
  pname = "linenoise";
  version = "0.9-1";

  knownRockspec = (fetchurl {
    url    = https://luarocks.org/linenoise-0.9-1.rockspec;
    sha256 = "0wic8g0d066pj9k51farsvcdbnhry2hphvng68w9k4lh0zh45yg4";
  }).outPath;

  src = fetchurl {
    url    = https://github.com/hoelzro/lua-linenoise/archive/0.9.tar.gz;
    sha256 = "177h6gbq89arwiwxah9943i8hl5gvd9wivnd1nhmdl7d8x0dn76c";
  };

  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ lua ];

  meta = with stdenv.lib; {
    homepage = "https://github.com/hoelzro/lua-linenoise";
    description = "A binding for the linenoise command line library";
    maintainers = with maintainers; [ arobyn ];
    license = {
      fullName = "MIT/X11";
    };
  };
};
loadkit = buildLuarocksPackage {
  pname = "loadkit";
  version = "1.1.0-1";

  src = fetchurl {
    url    = https://luarocks.org/loadkit-1.1.0-1.src.rock;
    sha256 = "1jxwzsjdhiahv6qdkl076h8xf0lmypibh71bz6slqckqiaq1qqva";
  };
  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ lua ];

  meta = with stdenv.lib; {
    homepage = "https://github.com/leafo/loadkit";
    description = "Loadkit allows you to load arbitrary files within the Lua package path";
    maintainers = with maintainers; [ arobyn ];
    license = {
      fullName = "MIT";
    };
  };
};
lua-ev = buildLuarocksPackage {
  pname = "lua-ev";
  version = "v1.4-1";

  knownRockspec = (fetchurl {
    url    = https://luarocks.org/lua-ev-v1.4-1.rockspec;
    sha256 = "0kkn9vca6hy6605gyps5iwxvrybvpzabzp505jk0j8963qzbd2w1";
  }).outPath;

  src = fetchgit ( removeAttrs (builtins.fromJSON ''{
  "url": "git://github.com/brimworks/lua-ev",
  "rev": "339426fbe528f11cb3cd1af69a88f06bba367981",
  "date": "2015-08-04T06:14:43-07:00",
  "sha256": "18p15rn0wj8dxncrc7jwivs2zw3gklzk5v1ynyzf7j6l8ggvyzml",
  "fetchSubmodules": true
}
 '') ["date"]) ;

  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ lua ];

  meta = with stdenv.lib; {
    homepage = "http://github.com/brimworks/lua-ev";
    description = "Lua integration with libev";
    maintainers = with maintainers; [ arobyn ];
    license = {
      fullName = "MIT/X11";
    };
  };
};
lua-testmore = buildLuarocksPackage {
  pname = "lua-testmore";
  version = "0.3.5-2";

  src = fetchurl {
    url    = https://luarocks.org/lua-testmore-0.3.5-2.src.rock;
    sha256 = "1ibisc86hwh2l0za0hqh97dv80p3rg05hdmws3yi6fv824v10xa8";
  };
  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ lua ];

  meta = with stdenv.lib; {
    homepage = "http://fperrad.frama.io/lua-TestMore/";
    description = "an Unit Testing Framework";
    maintainers = with maintainers; [ arobyn ];
    license = {
      fullName = "MIT/X11";
    };
  };
};
luagraph = buildLuarocksPackage {
  pname = "luagraph";
  version = "2.0.1-1";

  src = fetchurl {
    url    = https://luarocks.org/luagraph-2.0.1-1.src.rock;
    sha256 = "16az0bw2w7w019nwbj5nf6zkw7vc5idvrh63dvynx1446n6wl813";
  };
  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ lua ];

  meta = with stdenv.lib; {
    homepage = "http://github.com/hleuwer/luagraph";
    description = "A binding to the graphviz graph library";
    maintainers = with maintainers; [ arobyn ];
    license = {
      fullName = "MIT/X11";
    };
  };
};
luarepl = buildLuarocksPackage {
  pname = "luarepl";
  version = "0.9-1";

  knownRockspec = (fetchurl {
    url    = https://luarocks.org/luarepl-0.9-1.rockspec;
    sha256 = "1409lanxv4s8kq5rrh46dvld77ip33qzfn3vac3i9zpzbmgb5i8z";
  }).outPath;

  src = fetchurl {
    url    = https://github.com/hoelzro/lua-repl/archive/0.9.tar.gz;
    sha256 = "04xka7b84d9mrz3gyf8ywhw08xp65v8jrnzs8ry8k9540aqs721w";
  };

  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ lua ];

  meta = with stdenv.lib; {
    homepage = "https://github.com/hoelzro/lua-repl";
    description = "A reusable REPL component for Lua, written in Lua";
    maintainers = with maintainers; [ arobyn ];
    license = {
      fullName = "MIT/X11";
    };
  };
};
lunix = buildLuarocksPackage {
  pname = "lunix";
  version = "20170920-1";

  src = fetchurl {
    url    = https://luarocks.org/lunix-20170920-1.src.rock;
    sha256 = "1mjy3sprpskykjwsb3xzsy1add78hjjrwcfhx4c4x25fjjrhfh2a";
  };

  meta = with stdenv.lib; {
    homepage = "http://25thandclement.com/~william/projects/lunix.html";
    description = "Lua Unix Module.";
    maintainers = with maintainers; [ arobyn ];
    license = {
      fullName = "MIT/X11";
    };
  };
};
lub = buildLuarocksPackage {
  pname = "lub";
  version = "1.1.0-1";

  src = fetchurl {
    url    = https://luarocks.org/lub-1.1.0-1.src.rock;
    sha256 = "01ngd6ckbvp7cn11pwp651wjdk7mqnqx99asif5lvairb08hwhpz";
  };
  disabled = (luaOlder "5.1") || (luaAtLeast "5.4");
  propagatedBuildInputs = [ lua luafilesystem ];

  meta = with stdenv.lib; {
    homepage = "http://doc.lubyk.org/lub.html";
    description = "Lubyk base module.";
    maintainers = with maintainers; [ arobyn ];
    license = {
      fullName = "MIT";
    };
  };
};
lyaml = buildLuarocksPackage {
  pname = "lyaml";
  version = "6.2.4-1";

  src = fetchurl {
    url    = https://luarocks.org/lyaml-6.2.4-1.src.rock;
    sha256 = "1zalfaidas6xbjpda8av0lvmg4iwh0nqq1js5866wfrxx9lm4vni";
  };
  disabled = (luaOlder "5.1") || (luaAtLeast "5.5");
  propagatedBuildInputs = [ lua ];

  meta = with stdenv.lib; {
    homepage = "http://github.com/gvvaughan/lyaml";
    description = "libYAML binding for Lua";
    maintainers = with maintainers; [ arobyn ];
    license = {
      fullName = "MIT/X11";
    };
  };
};
mobdebug = buildLuarocksPackage {
  pname = "mobdebug";
  version = "0.70-1";

  knownRockspec = (fetchurl {
    url    = https://luarocks.org/mobdebug-0.70-1.rockspec;
    sha256 = "1jmhvjv2j5jnwa4nhxhc97gallhdbic4f9gz04bnn6id529pv6ph";
  }).outPath;

  src = fetchgit ( removeAttrs (builtins.fromJSON ''{
  "url": "git://github.com/pkulchenko/MobDebug.git",
  "rev": "7acfc6f9af339e486ae2390e66185367bbf6a0cd",
  "date": "2018-07-19T21:05:56-07:00",
  "sha256": "0hsq9micb7ic84f8v575drz49vv7w05pc9yrq4i57gyag820p2kl",
  "fetchSubmodules": true
}
 '') ["date"]) ;

  disabled = (luaOlder "5.1") || (luaAtLeast "5.4");
  propagatedBuildInputs = [ lua luasocket ];

  meta = with stdenv.lib; {
    homepage = "https://github.com/pkulchenko/MobDebug";
    description = "MobDebug is a remote debugger for the Lua programming language";
    maintainers = with maintainers; [ arobyn ];
    license = {
      fullName = "MIT/X11";
    };
  };
};
moonpick = buildLuarocksPackage {
  pname = "moonpick";
  version = "0.8-1";

  src = fetchurl {
    url    = https://luarocks.org/moonpick-0.8-1.src.rock;
    sha256 = "1w4pdlsn5sy72n6aprf2rkqck9drf3hbhhg63wi94ycv2jlj7xzq";
  };
  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ lua moonscript ];

  meta = with stdenv.lib; {
    homepage = "https://github.com/nilnor/moonpick";
    description = "An alternative moonscript linter.";
    maintainers = with maintainers; [ arobyn ];
    license = {
      fullName = "MIT";
    };
  };
};
moonscript = buildLuarocksPackage {
  pname = "moonscript";
  version = "0.5.0-1";

  src = fetchurl {
    url    = https://luarocks.org/moonscript-0.5.0-1.src.rock;
    sha256 = "09vv3ayzg94bjnzv5fw50r683ma0x3lb7sym297145zig9aqb9q9";
  };
  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ lua lpeg alt-getopt luafilesystem ];

  meta = with stdenv.lib; {
    homepage = "http://moonscript.org";
    description = "A programmer friendly language that compiles to Lua";
    maintainers = with maintainers; [ arobyn ];
    license = {
      fullName = "MIT";
    };
  };
};
moor = buildLuarocksPackage {
  pname = "moor";
  version = "v5.0-1";

  src = fetchurl {
    url    = https://luarocks.org/moor-v5.0-1.src.rock;
    sha256 = "1g0dhl4lv6bnrsy7yxwgvy0h60lqnaicmrzi53f3hycmrgglaqh6";
  };
  propagatedBuildInputs = [ moonscript inspect linenoise ];

  meta = with stdenv.lib; {
    homepage = "https://github.com/Nymphium/moor";
    description = "MoonScript REPL";
    maintainers = with maintainers; [ arobyn ];
    license = {
      fullName = "MIT";
    };
  };
};
optparse = buildLuarocksPackage {
  pname = "optparse";
  version = "1.4-1";

  src = fetchurl {
    url    = https://luarocks.org/optparse-1.4-1.src.rock;
    sha256 = "06pad2r1a8n6g5g3ik3ikp16x68cwif57cxajydgwc6s5b6alrib";
  };
  disabled = (luaOlder "5.1") || (luaAtLeast "5.5");
  propagatedBuildInputs = [ lua ];

  meta = with stdenv.lib; {
    homepage = "http://gvvaughan.github.io/optparse";
    description = "Parse and process command-line options";
    maintainers = with maintainers; [ arobyn ];
    license = {
      fullName = "MIT/X11";
    };
  };
};
pegdebug = buildLuarocksPackage {
  pname = "pegdebug";
  version = "0.40-2";

  knownRockspec = (fetchurl {
    url    = https://luarocks.org/pegdebug-0.40-2.rockspec;
    sha256 = "0in6w0w0yzg2gkb87zkiry1jspb5n058vfips5a27mrsjx2v9rja";
  }).outPath;

  src = fetchgit ( removeAttrs (builtins.fromJSON ''{
  "url": "git://github.com/pkulchenko/PegDebug.git",
  "rev": "81c9f468683b3153200feefb4455d657f94f240f",
  "date": "2017-03-19T14:44:49-07:00",
  "sha256": "178axx3ivif10n104w3dyjg7vmdhqwyr6n8g3cmmqkrk7j7liyzv",
  "fetchSubmodules": true
}
 '') ["date"]) ;

  disabled = (luaOlder "5.1");
  propagatedBuildInputs = [ lua lpeg ];

  meta = with stdenv.lib; {
    homepage = "http://github.com/pkulchenko/PegDebug";
    description = "PegDebug is a trace debugger for LPeg rules and captures.";
    maintainers = with maintainers; [ arobyn ];
    license = {
      fullName = "MIT/X11";
    };
  };
};
spawn = buildLuarocksPackage {
  pname = "spawn";
  version = "0.1-0";

  src = fetchurl {
    url    = https://luarocks.org/spawn-0.1-0.src.rock;
    sha256 = "1wrpc4cwkg9piafjmgv5rppdq2gix6gvy5bkphig8s8946nlsy5l";
  };
  disabled = (luaOlder "5.1") || (luaAtLeast "5.4");
  propagatedBuildInputs = [ lua lunix ];

  meta = with stdenv.lib; {
    homepage = "https://github.com/daurnimator/lua-spawn";
    description = "A lua library to spawn programs";
    maintainers = with maintainers; [ arobyn ];
    license = {
      fullName = "MIT";
    };
  };
};
yaml = buildLuarocksPackage {
  pname = "yaml";
  version = "1.1.2-1";

  src = fetchurl {
    url    = https://luarocks.org/manifests/gaspard/yaml-1.1.2-1.src.rock;
    sha256 = "0zl364inmcdk3592sbyswvp71gb7wnbw2asmf91r8yc8kysfjqqg";
  };
  disabled = (luaOlder "5.1") || (luaAtLeast "5.4");
  propagatedBuildInputs = [ lua lub ];

  meta = with stdenv.lib; {
    homepage = "http://doc.lubyk.org/yaml.html";
    description = "Very fast yaml parser based on libYAML by Kirill Simonov";
    maintainers = with maintainers; [ arobyn ];
    license = {
      fullName = "MIT";
    };
  };
};

}
/* GENERATED */

