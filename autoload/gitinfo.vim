let s:save_cpo = &cpo
set cpo&vim


function! gitinfo#branch()
  return ''
endfunction


function! s:get_gitdir()
  let gitdir = s:system('git rev-parse --git-dir')
  return s:shell_error() == 0 ? split(gitdir, '\n')[0] : ''
endfunction


function! s:system(...)
  return s:has_vimproc() ? call('vimproc#system', a:000) : call('system', a:000)
endfunction

function! s:shell_error()
  return s:has_vimproc() ? vimproc#get_last_status() : v:shell_error
endfunction

function! s:has_vimproc()
  if !exists('s:vimproc_loaded')
    try
      call vimproc#version()
      let s:vimproc_loaded = 1
    catch
      let s:vimproc_loaded = 0
    endtry
  endif
  return s:vimproc_loaded
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
