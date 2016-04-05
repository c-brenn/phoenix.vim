" Location:     plugin/projectionist.vim
" Author:       Conor Brennan<https://github.com/c-brenn>
" Version:      0.1.0
if exists("g:loaded_phoenix_vim")
  finish
endif
let g:loaded_phoenix_vim = 1

function! PhoenixDetect(...) abort
  if exists('b:phoenix_root')
    return 1
  endif
  let fn = fnamemodify(a:0 ? a:1 : expand('%'), ':p')
  if fn =~# ':[\/]\{2\}'
    return 0
  endif
  if !isdirectory(fn)
    let fn = fnamemodify(fn, ':h')
  endif
  let file = findfile('mix.exs', escape(fn, ', ').';')
  if !empty(file) && isdirectory(fnamemodify(file, ':p:h') . '/web')
    let b:phoenix_root = fnamemodify(file, ':p:h')
    return 1
  endif
endfunction

function!  s:setup() abort
  if exists('b:loaded_phoenix_projections')
    return 0
  endif

  call projectionist#append(b:phoenix_root,
        \   s:phoenix_projections())
  let b:loaded_phoenix_projections = 1
endfunction

function! s:phoenix_projections() abort
  return  {
        \   "web/channels/*_channel.ex": { "type": "channel" },
        \   "web/controllers/*_controller.ex": { "type": "controller" }
        \ }
endfunction

augroup phoenix_projections
  autocmd!
  autocmd FileType elixir
        \ if PhoenixDetect() |
        \   call s:setup() |
        \ endif

  autocmd User ProjectionistDetect
        \ if PhoenixDetect(get(g:, 'projectionist_file', '')) |
        \   call s:setup() |
        \ endif
augroup END
