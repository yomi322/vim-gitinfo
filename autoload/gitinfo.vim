let s:save_cpo = &cpo
set cpo&vim


function! gitinfo#branch()
  return ''
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
