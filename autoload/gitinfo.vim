let s:save_cpo = &cpo
set cpo&vim


function! gitinfo#branch()
  return ''
endfunction


function! s:system(...)
  return s:has_vimproc() ? call('vimproc#system', a:000) : call('system', a:000)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
