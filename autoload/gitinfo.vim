let s:save_cpo = &cpo
set cpo&vim


function! gitinfo#branch()
  let gitdir = s:get_gitdir()
  return !empty(gitdir) ? s:get_branch(gitdir) : ''
endfunction

function! gitinfo#action()
  let gitdir = s:get_gitdir()
  return !empty(gitdir) ? s:get_action(gitdir) : ''
endfunction


function! s:get_gitdir()
  let gitdir = s:system('git rev-parse --git-dir')
  return s:shell_error() == 0 ? split(gitdir, '\n')[0] : ''
endfunction

function! s:get_branch(gitdir)
  let symref = s:system('git symbolic-ref HEAD')
  let symref = s:shell_error() == 0 ? split(symref, '\n')[0] : ''
  if filereadable(a:gitdir . '/rebase-apply/head-name')
    let ref = !empty(symref) ? symref : s:readfirstline(a:gitdir . '/rebase-apply/head-name')
  elseif filereadable(a:gitdir . '/rebase/head-name')
    let ref = !empty(symref) ? symref : s:readfirstline(a:gitdir . '/rebase/head-name')
  elseif filereadable(a:gitdir . '/../.dotest/head-name')
    let ref = !empty(symref) ? symref : s:readfirstline(a:gitdir . '/../.dotest/head-name')
  elseif filereadable(a:gitdir . '/MERGE_HEAD')
    let ref = !empty(symref) ? symref : s:readfirstline(a:gitdir . '/MERGE_HEAD')
  elseif filereadable(a:gitdir . '/rebase-merge/head-name')
    let ref = s:readfirstline(a:gitdir . '/rebase-merge/head-name')
  elseif filereadable(a:gitdir . '/.dotest-merge/head-name')
    let ref = s:readfirstline(a:gitdir . '/.dotest-merge/head-name')
  else
    let ref = !empty(symref) ? symref : s:readfirstline(a:gitdir . '/HEAD')
  endif
  return matchstr(ref, 'refs/heads/\zs\S\+\ze')
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

function! s:readfirstline(fname)
  let firstline = readfile(a:fname, '', 1)
  return !empty(firstline) ? firstline[0] : ''
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
