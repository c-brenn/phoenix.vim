" Location:     plugin/projectionist.vim
" Author:       Conor Brennan<https://github.com/c-brenn>
" Version:      0.1.0

if exists("g:loaded_phoenix_vim")
  finish
endif
let g:loaded_phoenix_vim = 1


augroup phoenixPluginDetect
  autocmd!

  autocmd BufNewFile,BufReadPost *
        \ if phoenix#detect(expand("<afile>:p")) && empty(&filetype) |
        \   call phoenix#setup_buffer() |
        \ endif
  autocmd VimEnter *
        \ if empty(expand("<amatch>")) && phoenix#detect(getcwd()) |
        \   call phoenix#setup_buffer() |
        \ endif
  autocmd FileType * if phoenix#detect() | call phoenix#setup_buffer() | endif
augroup END

augroup phoenix_projections
  autocmd!
  autocmd User ProjectionistDetect call phoenix#setup_projections()
augroup END

augroup phoenix_path
  autocmd!
  autocmd User Phoenix call phoenix#setup_buffer()
  autocmd User Phoenix
        \ let &l:path = 'lib/**,web/**,test/**,config/**' . &path |
        \ let &l:suffixesadd = '.ex,.exs,.html.eex' . &suffixesadd
augroup END
