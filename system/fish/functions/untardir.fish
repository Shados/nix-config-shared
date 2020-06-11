function untardir -d "Untar things to a directory based on the name of the tar file"
  if test (count $argv) -lt 1
    echo "Please supply a tar file to extract from"
    return 1
  end

  set -l tarf $argv[1]
  set -l tarp (realpath $tarf)

  set -l tar_pat '^(.*)\.tar(?:\.(?:xz|lz4|bz2|gz))?$'
  echo $tarf | grep -P $tar_pat 2>&1 >/dev/null; if test $status -ne 0
    echo "Unrecognized extension"
    return 1
  else
    set -l outdir (echo $tarf | perl -pe "s/$tar_pat/\1/g")
    mkdir "$outdir"
    set -l origdir $PWD
    cd $outdir
    tar xvf "$tarp"
    cd $origdir
  end
end
