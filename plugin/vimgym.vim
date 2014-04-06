" Vim global plugin for deliberate practice of Vim skills
" Maintainer:	Barry Arthur <barry.arthur@gmail.com>
" Version:	0.1
" Description:	Deliberate Practice for Vim
" Last Change:	2014-04-06
" License:	Vim License (see :help license)
" Location:	plugin/vimgym.vim
" Website:	https://github.com/dahu/vimgym
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
if !exists('g:vimgym_some_plugin_option')
  let g:vimgym_some_plugin_option = 0
endif

" Private Functions: {{{1
function! s:MyScriptLocalFunction()
  echom "change MyScriptLocalFunction"
endfunction

" Public Interface: {{{1
function! MyPublicFunction()
  echom "change MyPublicFunction"
endfunction

" Maps: {{{1
nnoremap <Plug>vimgym1 :call <SID>MyScriptLocalFunction()<CR>
nnoremap <Plug>vimgym2 :call MyPublicFunction()<CR>

if !hasmapto('<Plug>PublicPlugName1')
  nmap <unique><silent> <leader>p1 <Plug>vimgym1
endif

if !hasmapto('<Plug>PublicPlugName2')
  nmap <unique><silent> <leader>p2 <Plug>vimgym2
endif

" Commands: {{{1
command! -nargs=0 -bar MyCommand1 call <SID>MyScriptLocalFunction()
command! -nargs=0 -bar MyCommand2 call MyPublicFunction()

" Teardown:{{{1
"reset &cpo back to users setting
let &cpo = s:save_cpo

" Template From: https://github.com/dahu/Area-41/
" vim: set sw=2 sts=2 et fdm=marker:
