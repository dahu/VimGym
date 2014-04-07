" Vim global plugin for deliberate practice of Vim skills
" Maintainer:   Barry Arthur <barry.arthur@gmail.com>
" Version:      0.1
" Description:  Deliberate Practice for Vim
" Last Change:  2014-04-06
" License:      Vim License (see :help license)
" Location:     plugin/vimgym.vim
" Website:      https://github.com/dahu/vimgym
"
" See vimgym.txt for help.  This can be accessed by doing:
"
" :helptags ~/.vim/doc
" :help vimgym

" Vimscript Setup: {{{1
" Allow use of line continuation.
let s:save_cpo = &cpo
set cpo&vim

" load guard
" uncomment after plugin development.
" XXX The conditions are only as examples of how to use them. Change them as
" needed. XXX
"if exists("g:loaded_vimgym")
"      \ || v:version < 700
"      \ || v:version == 703 && !has('patch338')
"      \ || &compatible
"  let &cpo = s:save_cpo
"  finish
"endif
"let g:loaded_vimgym = 1

" Options: {{{1
if !exists('g:vimgym_tasks_dir')
  let g:vimgym_tasks_dir = expand('<sfile>:p:h:h') . '/tasks/'
endif

if !exists('g:vimgym_stats_file')
  let g:vimgym_stats_file = expand('<sfile>:p:h:h') . '/stats.vimgym'
endif

" Private Functions: {{{1

function! s:command_complete(ArgLead, CmdLine, CursorPos) " {{{1
  if a:CmdLine[: a:CursorPos ] =~? '\m\(^\s*\||\s*\)\S\+[ ]\+\S*$'
    " Complete actions:
    return join(['do ', 'add', 'delete', 'stats'], "\n")
  elseif a:CmdLine[: a:CursorPos ] =~?
        \'\m\(^\s*\||\s*\)\S\+ d\%[o]\([ ]\+\S\+\)*[ ]\+\S*$'
    " Complete do action, list tasks
    return join(s:task_list(), "\n")
  elseif a:CmdLine[: a:CursorPos ] =~?
        \'\m\(^\s*\||\s*\)\S\+ a\%[dd]\([ ]\+\%(start\|end\)\@!\S\+\)*[ ]\+\S*$'
    " Complete add action
    return join(['start ', 'end'], "\n")
  elseif a:CmdLine[: a:CursorPos ] =~?
        \'\m\(^\s*\||\s*\)\S\+ de\%[lete][ ]\+\S*$'
    " Complete delete action, list tasks:
    return join(s:task_list(), "\n")
  elseif a:CmdLine[: a:CursorPos ] =~?
        \'\m\(^\s*\||\s*\)\S\+ s\%[tats][ ]\+\S*$'
    return join(s:task_list(), "\n")
  else
    return ''
  endif
endfunction

function! s:find_vimgym_tab()
  for i in range(tabpagenr('$'))
    if len(filter(tabpagebuflist(i + 1), 'getbufvar(v:val, "vimgym_task") != ""')) > 0
      return i+1
    endif
  endfor
  return 0
endfunction

function! s:new_vimgym_tab()
  tabnew
  new
  return tabpagenr()
endfunction

function! s:vimgym_init_commands()
  command! -bar -buffer -nargs=0 VGS call <SID>vimgym_start()
  silent! delcommand VGE
endfunction

function! s:vimgym_start()
  1 wincmd w
  setlocal modifiable
  command! -bar -buffer -nargs=0 VGE       call <SID>vimgym_end()
  let s:start_time = localtime()
endfunction

function! s:load_task_stats()
  let s:task_times = {}
  if filereadable(g:vimgym_stats_file)
    call map(map(readfile(g:vimgym_stats_file), 'split(v:val, "\t")'),
          \ 'extend(s:task_times, {v:val[0] : v:val[1]})')
  endif
endfunction

function! s:save_task_best(task, time)
  let task = a:task
  let time = a:time
  if has_key(s:task_times, task)
    if time <= s:task_times[task]
      if time < s:task_times[task]
        let s:task_times[task] = time
        call writefile(map(items(s:task_times), 'join(v:val, "\t")'), g:vimgym_stats_file)
      endif
      return 1
    endif
  else
    let s:task_times[task] = time
    call writefile(map(items(s:task_times), 'join(v:val, "\t")'), g:vimgym_stats_file)
    return 1
  endif
  return 0
endfunction

function! s:message(msg)
  echohl Warning
  echom a:msg
  echohl None
endfunction

function! s:task_complete()
  let curwin = winnr()
  let curpos = getpos('.')

  1 wincmd w
  let b1 = getline(1, '$')
  2 wincmd w
  let b2 = getline(1, '$')
  exe curwin . ' wincmd w'

  call setpos('.', curpos)

  return b1 ==# b2
endfunction

function! s:vimgym_end()
  let task = b:vimgym_task
  let tdiff = localtime() - s:start_time
  if s:task_complete()
    let stat = 'Completed task ' . task . ' in ' . tdiff . ' seconds.'
    if s:save_task_best(task, tdiff)
      let stat .= ' Personal Best Time! \o/'
    endif
    call s:message(stat)
    silent! delcommand VGE
  else
    call s:message('Task is not complete!')
  endif
endfunction

function! s:open_vimgym_tab(task)
  " 1. locate existing VimGym buffer, if one exists and switch to that tab+buf
  " 2. otherwise spawn a new tab with two wins, horiz split
  let s:vimgym_tabpage = s:find_vimgym_tab()
  if s:vimgym_tabpage == 0
    let s:vimgym_tabpage = s:new_vimgym_tab()
  endif
  exe 'tabnext ' . s:vimgym_tabpage

  call s:load_task_stats()

  " load the specified task and setup the commands
  1 wincmd w
  setlocal buftype=nofile
  setlocal modifiable
  %delete
  call setline(1, s:task_read('start', a:task))
  setlocal nomodifiable
  call s:vimgym_init_commands()
  let b:vimgym_task = a:task

  2 wincmd w
  setlocal buftype=nofile
  setlocal modifiable
  %delete
  call setline(1, s:task_read('end', a:task))
  setlocal nomodifiable
  call s:vimgym_init_commands()
  let b:vimgym_task = a:task

  1 wincmd w
  call s:message("Type :VGS   to begin and   :VGE   when you're done.")
endfunction

function! s:task_read(startend, task)
  let ext = '.vg' . (a:startend == 'start' ? 's' : 'e')
  return readfile(g:vimgym_tasks_dir . '/' . a:task . ext)
endfunction
function! TaskRead(se, t)
  return s:task_read(a:se, a:t)
endfunction

" only list tasks that have both a .vgs and vge file
function! s:task_list()
  return map(filter(split(globpath(g:vimgym_tasks_dir, '*.vgs'), "\n"),
        \ 'filereadable(fnamemodify(v:val, ":r") . ".vge")'),
        \ 'fnamemodify(v:val, ":t:r")')
endfunction

function! s:task_do(task)
  let task = a:task
  echom 'do task = ' . task
  if index(s:task_list(), task) == -1
    echom 'Task not found: ' . task
  else

    call s:open_vimgym_tab(task)
  endif
endfunction

function! s:task_add(startend, task)
  echom 'add task = ' . a:startend . ' - ' . a:task
endfunction

function! s:task_delete(task)
  echom 'delete task = ' . a:task
endfunction

function! s:task_stats(...)
  let task = ''
  if a:0
    let task = a:1
  endif
  if task != '' && has_key(s:task_times, task)
    echo 'VimGym task ' . task . ' PB Time is ' . s:task_times[task] . ' seconds.'
  else
    echo "VimGym Personal Best Times"
    echo "SECONDS	TASK"
    echo join(map(items(s:task_times), 'join(reverse(v:val), "	")'), "\n")
  endif
endfunction

function! s:vimgym(action, ...) " {{{1
  let actions = ['do', 'add', 'delete', 'stats']
  if len(filter(copy(actions), 'v:val =~? "^" . a:action')) == 0
    echom 'Action not supported.'
    return ''
  endif

  if a:action =~? '^d\%[o]$'
    if a:0 > 0
      call s:task_do(a:1)
    else
      echom 'You must provide a task name.'
    endif
  elseif a:action =~? '^a\%[dd]'
    if a:0 < 2
      echom 'usage: VimGym start|end taskname'
    else
      if index(['start', 'end'], a:1) == -1
        if index(['start', 'end'], a:2) == -1
          echom 'usage: VimGym start|end taskname'
          return
        endif
        let [startend, taskname] = [a:2, a:1]
      else
        let [startend, taskname] = [a:1, a:2]
      endif
      call s:task_add(startend, taskname)
    endif
  elseif a:action =~? '^d\%[elete]'
    if a:0 > 0
      call s:task_delete(a:1)
    else
      echom 'You must provide a task name.'
    endif
  elseif a:action =~? '^s\%[tats]'
    call call('s:task_stats', a:000)
  else
    echom 'Action not supported: ' . a:action
  endif
endfunction

" Public Interface: {{{1
call s:load_task_stats()

function! VimGym(...)
  call s:open_vimgym_tab()
endfunction

" Commands: {{{1
command! -bar -nargs=* -complete=custom,<SID>command_complete VimGym call <SID>vimgym(<f-args>)
command! -bar -nargs=* -complete=custom,<SID>command_complete VG call <SID>vimgym(<f-args>)

" Teardown:{{{1
"reset &cpo back to users setting
let &cpo = s:save_cpo

" Template From: https://github.com/dahu/Area-41/
" vim: set sw=2 sts=2 et fdm=marker:
