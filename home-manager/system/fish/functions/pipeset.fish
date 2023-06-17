# From: https://github.com/fish-shell/fish-shell/issues/159#issuecomment-37057175
# Used to capture command output *with linebreaks intact* into a varaible
# Usage:
#
#   ~ $ perl --version | pipeset perl_version
#   ~ $ echo $perl_version

#   This is perl 5, version 14, subversion 4 (v5.14.4) built for cygwin-thread-multi
#   (with 7 registered patches, see perl -V for ...
#   ...

function pipeset --no-scope-shadowing
  set -l _options
  set -l _variables
  for _item in $argv
    switch $_item
    case '-*'
      set _options $_options $_item
    case '*'
      set _variables $_variables  $_item
    end
  end
  for _variable in $_variables
    set $_variable ""
  end
  while read _line
    for _variable in $_variables
      set $_options $_variable $$_variable$_line\n
    end
  end
  return 0
end
