" Location:     autoload/phoenix.vim
" Author:       Conor Brennan<https://github.com/c-brenn>
if exists('g:autoloaded_phoenix')
  finish
endif
let g:autoloaded_phoenix = 1

function! phoenix#detect(...) abort
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

function! phoenix#setup(path) abort
  call phoenix#detect(a:path)
  if exists('b:phoenix_root')
    doautocmd User Phoenix
  endif
endfunction

function! phoenix#setup_projections() abort
  if exists('b:phoenix_root')
    call projectionist#append(b:phoenix_root, phoenix#projections())
  endif
endfunction

function! phoenix#projections() abort
  return  {
        \   "web/controllers/*_controller.ex": { "type": "controller" },
        \   "web/channels/*_channel.ex": { "type": "channel" },
        \   "web/templates/**.html.eex": { "type": "template" },
        \   "web/static/css/*.css": { "type": "stylesheet" },
        \   "web/static/js/*.js": { "type": "javascript" },
        \   "web/models/*.ex": { "type": "model" },
        \   "web/router.ex": { "type": "router" },
        \   "config/*.exs": { "type": "config" },
        \   "*": { "start": "mix phoenix.server",
        \          "console": "iex -S mix",
        \          "path": "web/**"
        \        },
        \ }
endfunction


function! phoenix#setup_buffer() abort
  if !exists('b:phoenix_root')
    return ''
  endif

  call s:BufferMappings()
  call s:BufferCommands()
endfunction

function! s:BufferMappings() abort
  nmap <buffer><silent> <Plug>PhoenixFind       :exe 'find ' . phoenix#cfile('delegate')<CR>
  nmap <buffer><silent> <Plug>PhoenixSplitFind  :exe 'sfind ' . phoenix#cfile('delegate')<CR>
  nmap <buffer><silent> <Plug>PhoenixTabFind    :exe 'tabfind ' . phoenix#cfile('delegate')<CR>

  nmap <buffer> gf         <Plug>PhoenixFind
endfunction

function! s:BufferCommands() abort
  command! -buffer -bar -nargs=? -bang -range PPreview :call s:Preview(<bang>0,<line1>,<q-args>)
endfunction

function! phoenix#cfile(...) abort
  let cfile = s:cfile()
  return cfile
endfunction

function! s:cfile(...) abort
  if filereadable(expand("<cfile>"))
    return expand("<cfile>")
  endif

  let res = s:findamethod('belongs_to\|has_one','\1.ex')
  if res != ""|return res|endif

  let res = phoenix#singularize(s:findamethod('has_many','\1'))
  if res != ""|return res.".ex"|endif

  let res = phoenix#singularize(s:findamethod('\%(create table\)\|references','\1'))
  if res != ""|return res.".ex"|endif

  let res = phoenix#underscore(s:findamodule('\%(get\|resources\|post\|put\|patch\) ".*", ', '\1'))
  if res != ""|return res.".ex"|endif

  let res = phoenix#underscore(s:findamodule('\%(\a\+\.\)\+', '\1'))
  if res != ""|return res.".ex"|endif
endfunction

function! s:matchcursor(pat)
  let line = getline(".")
  let lastend = 0
  while lastend >= 0
    let beg = match(line,'\C'.a:pat,lastend)
    let end = matchend(line,'\C'.a:pat,lastend)
    if beg < col(".") && end >= col(".")
      return matchstr(line,'\C'.a:pat,lastend)
    endif
    let lastend = end
  endwhile
  return ""
endfunction

function! s:findit(pat,repl)
  let res = s:matchcursor(a:pat)
  if res != ""
    return substitute(res,'\C'.a:pat,a:repl,'')
  else
    return ""
  endif
endfunction


function! s:findamethod(func,repl)
  return s:findit('\s*\<\%('.a:func.'\)\s*(\=\s*[@:'."'".'"]\(\f\+\)\>.\=',a:repl)
endfunction

function! s:findamodule(func,repl)
  return s:findit('\s*\<\%('.a:func.'\)\s*(\=\s*\(\u\f\+\)\>.\=',a:repl)
endfunction

function! phoenix#singularize(word)
  let word = a:word
  if word =~? '\.js$' || word == ''
    return word
  endif
  let word = s:sub(word,'eople$','ersons')
  let word = s:sub(word,'%([Mm]ov|[aeio])@<!ies$','ys')
  let word = s:sub(word,'xe[ns]$','xs')
  let word = s:sub(word,'ves$','fs')
  let word = s:sub(word,'ss%(es)=$','sss')
  let word = s:sub(word,'s$','')
  let word = s:sub(word,'%([nrt]ch|tatus|lias)\zse$','')
  let word = s:sub(word,'%(nd|rt)\zsice$','ex')
  return word
endfunction

function! s:sub(str,pat,rep)
  return substitute(a:str,'\v\C'.a:pat,a:rep,'')
endfunction

function! s:sub(str,pat,rep)
    return substitute(a:str,'\v\C'.a:pat,a:rep,'')
endfunction

function! phoenix#underscore(str)
  let str = s:gsub(a:str,'::','/')
  let str = s:gsub(str,'(\u+)(\u\l)','\1_\2')
  let str = s:gsub(str,'(\l|\d)(\u)','\1_\2')
  let str = tolower(str)
  return str
endfunction

function! s:gsub(str,pat,rep)
  return substitute(a:str,'\v\C'.a:pat,a:rep,'g')
endfunction

function! s:Preview(bang, lnum, uri)
  let binding = '0.0.0.0:4000'
  let binding = s:sub(binding, '^0\.0\.0\.0>|^127\.0\.0\.1>', 'localhost')
  let binding = s:sub(binding, '^\[::\]', '[::1]')
  let uri = a:uri
  if uri =~ '://'
    "
  elseif uri =~# '^[[:alnum:]-]\+\.'
    let uri = 'http://'.s:sub(uri, '^[^/]*\zs', matchstr(root, ':\d\+$'))
  elseif uri =~# '^[[:alnum:]-]\+\%(/\|$\)'
    let domain = s:sub(binding, '^localhost>', 'lvh.me')
    let uri = 'http://'.s:sub(uri, '^[^/]*\zs', '.'.domain)
  else
    let uri = 'http://'.binding.'/'.s:sub(uri,'^/','')
  endif
  call s:initOpenURL()
  if (exists(':OpenURL') == 2) && !a:bang
    exe 'OpenURL '.uri
  else
    echohl Error
    echom 'OpenUrl is not defined'
  endif
endfunction

function! s:initOpenURL() abort
  if exists(":OpenURL") != 2
    if exists(":Browse") == 2
      command -bar -nargs=1 OpenURL Browse <args>
    elseif has("gui_mac") || has("gui_macvim") || exists("$SECURITYSESSIONID")
      command -bar -nargs=1 OpenURL exe '!open' shellescape(<q-args>, 1)
    elseif has("gui_win32")
      command -bar -nargs=1 OpenURL exe '!start cmd /cstart /b' shellescape(<q-args>, 1)
    elseif executable("xdg-open")
      command -bar -nargs=1 OpenURL exe '!xdg-open' shellescape(<q-args>, 1) '&'
    elseif executable("sensible-browser")
      command -bar -nargs=1 OpenURL exe '!sensible-browser' shellescape(<q-args>, 1)
    elseif executable('launchy')
      command -bar -nargs=1 OpenURL exe '!launchy' shellescape(<q-args>, 1)
    elseif executable('git')
      command -bar -nargs=1 OpenURL exe '!git web--browse' shellescape(<q-args>, 1)
    endif
  endif
endfunction
