" Location:     plugin/projectionist.vim
" Author:       Conor Brennan<https://github.com/c-brenn>
" Version:      0.1.0

if exists("g:loaded_phoenix_vim")
  finish
endif
let g:loaded_phoenix_vim = 1


augroup phoenixPluginDetect
  autocmd!

  " Setup when openening a file without a filetype
  autocmd BufNewFile,BufReadPost *
        \ if empty(&filetype) |
        \   call phoenix#setup(expand('<amatch>:p')) |
        \ endif

  " Setup when launching Vim for a file with any filetype
  autocmd FileType * call phoenix#setup(expand('%:p'))

  " Setup when launching Vim without a buffer
  autocmd VimEnter *
        \ if expand('<amatch>') == '' |
        \   call phoenix#setup(getcwd()) |
        \ endif
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
