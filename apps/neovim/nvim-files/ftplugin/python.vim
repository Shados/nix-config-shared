" Function to open current-test-name-corresponding data file
" Intended for use with pytest and pytest-datadir, in my particular setup
function! EditTestData(data_filetype)
  let l:curfile = expand('%:r')
  let l:curfunc = cfi#format('%s', 'No Function Found')
  if l:curfunc ==# 'No Function Found'
    echo 'The cursor is not positioned within a function'
    return
  endif

  if match(l:curfunc, 'test_.*') == -1
    echo 'The function the cursor is positioned within is not a valid pytest function'
    return
  endif

  let l:func_noprefix = strpart(l:curfunc, 5)
  let l:datafile = l:curfile . '/' . l:func_noprefix . '.' . a:data_filetype
  execute 'edit' l:datafile
endfunction
command! -nargs=1 EditTestData call EditTestData(<args>)

function! EditYamlData()
  EditTestData('yaml')
endfunction
command! EditYamlData call EditYamlData()
