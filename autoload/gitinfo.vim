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

function! gitinfo#revision()
  let rev = s:system('git rev-parse --quiet --verify HEAD')
  return s:shell_error() == 0 ? split(rev, '\n')[0] : ''
endfunction

function! gitinfo#unstaged(str, ...)
  call s:system('git diff --no-ext-diff --ignore-submodules --quiet --exit-code')
  let exit = s:shell_error()
  let changed = s:is_inside() ? (exit != 0) : 0
  return changed ? a:str : a:0 ? a:1 : ''
endfunction

function! gitinfo#staged(str, ...)
  call s:system('git diff-index --cached --quiet --ignore-submodules HEAD')
  let exit = s:shell_error()
  let changed = s:is_inside() ? (exit && exit != 128) : 0
  return changed ? a:str : a:0 ? a:1 : ''
endfunction


function! s:get_gitdir()
  let gitdir = s:system('git rev-parse --git-dir')
  return s:shell_error() == 0 ? split(gitdir, '\n')[0] : ''
endfunction

function! s:is_inside()
  let is_inside_git_dir = s:system('git rev-parse --is-inside-git-dir')
  call s:system('git rev-parse --quiet --verify HEAD')
  return is_inside_git_dir !~# 'true' && s:shell_error() == 0
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

function! s:get_action(gitdir)
  let dirs1 = filter(map(['/rebase-apply', '/rebase', '/../.dotest'], 'a:gitdir . v:val'), 'isdirectory(v:val)')
  let dirs2 = filter(map(['/rebase-merge', '/.dotest-merge'],         'a:gitdir . v:val'), 'isdirectory(v:val)')
  if !empty(dirs1)
    let dir = dirs1[0]
    if filereadable(dir . '/rebasing')
      let action = 'rebase'
    elseif filereadable(dir . '/applying')
      let action = 'am'
    else
      let action = 'am/rebase'
    endif
  elseif !empty(dirs2)
    let dir = dirs2[0]
    if filereadable(dir . '/interactive')
      let action = 'rebase-i'
    else
      let action = 'rebase-m'
    endif
  elseif filereadable(a:gitdir . '/MERGE_HEAD')
    let action = 'merge'
  elseif filereadable(a:gitdir . '/BISECT_LOG')
    let action = 'bisect'
  else
    let action = ''
  endif
  return action
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
