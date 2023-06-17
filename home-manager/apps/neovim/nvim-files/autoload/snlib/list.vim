function! snlib#list#within(list, item) abort
  return index(a:list, a:item) >= 0
endfunction
