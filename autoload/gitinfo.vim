let s:save_cpo = &cpo
set cpo&vim


let g:gitinfo_format           = get(g:, 'gitinfo_format', '[%b]-(%i)')
let g:gitinfo_action_format    = get(g:, 'gitinfo_action_format', '[%b|%a]-(%i)')
let g:gitinfo_revision_length  = get(g:, 'gitinfo_revision_length', 7)
let g:gitinfo_staged_string    = get(g:, 'gitinfo_staged_string', 'S')
let g:gitinfo_unstaged_string  = get(g:, 'gitinfo_unstaged_string', 'U')
let g:gitinfo_untracked_string = get(g:, 'gitinfo_untracked_string', '?')
let g:gitinfo_ahead_format     = get(g:, 'gitinfo_ahead_format', '+%N')
let g:gitinfo_behind_format    = get(g:, 'gitinfo_behind_format', '-%N')
let g:gitinfo_unmerged_format  = get(g:, 'gitinfo_unmerged_format', 'm%N')


function! gitinfo#format(...)
  let gitdir = s:get_gitdir()
  if gitdir ==# ''
    return ''
  else
    let branch = s:get_branch(gitdir)
    let action = s:get_action(gitdir)
    if action ==# ''
      let ret = a:0 ? a:1 : g:gitinfo_format
    else
      let ret = a:0 ? a:2 : g:gitinfo_action_format
    endif
    let ret = substitute(ret, '%b', branch, 'g')
    let ret = substitute(ret, '%a', action, 'g')
    if match(ret, '%i') >= 0
      let ret = substitute(ret, '%i', gitinfo#revision(), 'g')
    endif
    if match(ret, '%c') >= 0
      let ret = substitute(ret, '%c', gitinfo#staged(), 'g')
    endif
    if match(ret, '%u') >= 0
      let ret = substitute(ret, '%u', gitinfo#unstaged(), 'g')
    endif
    if match(ret, '%t') >= 0
      let ret = substitute(ret, '%t', gitinfo#untracked(), 'g')
    endif
    if match(ret, '%r') >= 0
      let ret = substitute(ret, '%r', gitinfo#ahead(), 'g')
    endif
    if match(ret, '%l') >= 0
      let ret = substitute(ret, '%l', gitinfo#behind(), 'g')
    endif
  endif
  return ret
endfunction


function! gitinfo#branch()
  let gitdir = s:get_gitdir()
  return !empty(gitdir) ? s:get_branch(gitdir) : ''
endfunction

function! gitinfo#action()
  let gitdir = s:get_gitdir()
  return !empty(gitdir) ? s:get_action(gitdir) : ''
endfunction

function! gitinfo#revision(...)
  let rev = s:system('git rev-parse --quiet --verify HEAD')
  let hash = s:shell_error() == 0 ? split(rev, '\n')[0] : ''
  let length = a:0 ? a:1 : g:gitinfo_revision_length
  return hash[: length - 1]
endfunction

function! gitinfo#staged(...)
  call s:system('git diff-index --cached --quiet --ignore-submodules HEAD')
  let exit = s:shell_error()
  let changed = s:is_inside() ? (exit && exit != 128) : 0
  return changed ? (a:0 ? a:1 : g:gitinfo_staged_string) : ''
endfunction

function! gitinfo#unstaged(...)
  call s:system('git diff --no-ext-diff --ignore-submodules --quiet --exit-code')
  let exit = s:shell_error()
  let changed = s:is_inside() ? (exit != 0) : 0
  return changed ? (a:0 ? a:1 : g:gitinfo_unstaged_string) : ''
endfunction

function! gitinfo#untracked(...)
  let files = s:system('git status --porcelain')
  let changed = s:shell_error() == 0 ? !empty(filter(split(files, '\n'), 'v:val =~# "^?? "')) : 0
  return changed ? (a:0 ? a:1 : g:gitinfo_untracked_string) : ''
endfunction

function! gitinfo#ahead(...)
  let branch = gitinfo#branch()
  let rev    = s:system('git rev-list origin/' . branch . '..HEAD')
  let ahead  = s:shell_error() == 0 ? len(split(rev, '\n')) : 0
  if ahead > 0
    let fmt = a:0 ? a:1 : g:gitinfo_ahead_format
    return substitute(fmt, '%N', ahead, 'g')
  else
    return ''
  endif
endfunction

function! gitinfo#behind(...)
  let branch = gitinfo#branch()
  let rev    = s:system('git rev-list HEAD..origin/' . branch)
  let behind = s:shell_error() == 0 ? len(split(rev, '\n')) : 0
  if behind > 0
    let fmt = a:0 ? a:1 : g:gitinfo_behind_format
    return substitute(fmt, '%N', behind, 'g')
  else
    return ''
  endif
endfunction

function! gitinfo#unmerged(...)
  let branch = gitinfo#branch()
  if branch ==# 'master'
    return ''
  else
    let rev = s:system('git rev-list master..' . branch)
    let unmerged = s:shell_error() == 0 ? len(split(rev, '\n')) : 0
    if unmerged > 0
      let fmt = a:0 ? a:1 : g:gitinfo_unmerged_format
      return substitute(fmt, '%N', unmerged, 'g')
    else
      return ''
    endif
  endif
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
