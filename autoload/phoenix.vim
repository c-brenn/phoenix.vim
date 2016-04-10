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
    let b:phoenix_project_name = phoenix#camelize(fnamemodify(b:phoenix_root, ':t'))
    return 1
  endif
endfunction

function! phoenix#setup(path) abort
  call phoenix#detect(a:path)
  if exists('b:phoenix_root')
    doautocmd User Phoenix
  endif
endfunction

" {{{ Buffer Setup

function! phoenix#setup_buffer() abort
  if !exists('b:phoenix_root')
    return ''
  endif

  call s:BufferMappings()
  call s:BufferCommands()
endfunction

function! s:BufferMappings() abort
  nmap <buffer><silent> <Plug>PhoenixFind       :exe 'find '    . phoenix#cfile('delegate')<CR>
  nmap <buffer><silent> <Plug>PhoenixSplitFind  :exe 'sfind '   . phoenix#cfile('delegate')<CR>
  nmap <buffer><silent> <Plug>PhoenixTabFind    :exe 'tabfind ' . phoenix#cfile('delegate')<CR>

  let pattern = '^$\|_gf(v:count\|[Pp]hoenix\|[Ee]lixir'
  " gf ==> :find <file>
  if mapcheck('gf', 'n') =~# pattern
    nmap <buffer> gf         <Plug>PhoenixFind
  endif
  " <C-W>f ==> :sfind <file>
  if mapcheck('<C-W>f', 'n') =~# pattern
    nmap <buffer> <C-W>f     <Plug>PhoenixSplitFind
  endif
  " <C-W><C-F> ==> :sfind <file>
  if mapcheck('<C-W><C-F>', 'n') =~# pattern
    nmap <buffer> <C-W><C-F> <Plug>PhoenixSplitFind
  endif
  " <C-W>gf ==> :tabfind file
  if mapcheck('<C-W>gf', 'n') =~# pattern
    nmap <buffer> <C-W>gf    <Plug>PhoenixTabFind
  endif
endfunction

function! s:BufferCommands() abort
  " Pserver
  command! -nargs=0 Pserver call phoenix#open_server()
  command! -nargs=0 PserverHide call phoenix#hide_server()
  " Pgenerate
  command! -nargs=+ -complete=custom,s:generator_complete Pgenerate
        \ call phoenix#generator(<f-args>)
  " Ppreview
  command! -bar -nargs=? -bang -range Ppreview :call s:Preview(<bang>0,<line1>,<q-args>)
endfunction

" }}}

" {{{ gf

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

" }}}

" {{{ Projections

function! phoenix#setup_projections() abort
  if exists('b:phoenix_root')
    call projectionist#append(b:phoenix_root, phoenix#projections())
    for split_type in ['E', 'S', 'V', 'T']
      exe "command! -buffer -nargs=1 -complete=customlist,phoenix#migrationList " . split_type ."migration execute s:migrationEdit('".split_type."',<q-args>)"
    endfor
    call phoenix#setup_custom_transformations()
  endif
endfunction

function! phoenix#migrationList(A, L, P)
  let migrations = s:relglob("priv/repo/migrations/",'\d\+_*',".exs")
  let migrations_without_timestamps = map(migrations,'substitute(v:val,"\\d\\+_","", "")')
  return migrations_without_timestamps
endfunction

function! s:relglob(path,glob,...)
  if exists("+shellslash") && ! &shellslash
    let old_ss = &shellslash
    let &shellslash = 1
  endif
  let path = a:path
  let suffix = a:0 ? a:1 : ''
  let full_paths = split(glob(path.a:glob.suffix),"\n")
  let relative_paths = []
  for entry in full_paths
    if suffix == '' && isdirectory(entry) && entry !~ '/$'
      let entry .= '/'
    endif
    let relative_paths += [entry[strlen(path) : -strlen(suffix)-1]]
  endfor
  if exists("old_ss")
    let &shellslash = old_ss
  endif
  return relative_paths
endfunction

function! s:migrationEdit(split_type, file)
  let possibilities = split(glob('priv/repo/migrations/\d\+_*'.a:file.'.exs'), "\n")
  if len(possibilities) > 0
    execute s:split_cmd(a:split_type) . ' ' . possibilities[0]
  endif
endfunction

function! s:split_cmd(split_type)
  if a:split_type == 'E'| return 'e'|endif
  if a:split_type == 'S'| return 'sp'|endif
  if a:split_type == 'V'| return 'vsp'|endif
  if a:split_type == 'T'| return 'tabe'|endif
endfunction

function! s:template_for(lowercase, camelcase)
  return [s:module_def(a:lowercase, a:camelcase)]  + s:module_content(a:lowercase, a:camelcase) + ['', 'end']
endfunction

function! s:module_def(lowercase, camelcase)
  if a:lowercase =~ '\(view\|controller\|channel\)'
    return 'defmodule '.b:phoenix_project_name.'.{camelcase}'.a:camelcase.' do'
  elseif a:lowercase == 'model'
    return 'defmodule '.b:phoenix_project_name.'.{camelcase} do'
  elseif a:lowercase == 'test'
    return 'defmodule '.b:phoenix_project_name.'.{basename|camelcase}'.a:camelcase.' do'
  end
endfunction

function! s:module_content(lowercase, camelcase)
  if a:lowercase =~ '\(view\|controller\|channel\)'
    return ['  use '.b:phoenix_project_name.'.Web, :'.a:lowercase]
  elseif a:lowercase == 'model'
    return ['  use '.b:phoenix_project_name.'.Web, :'.a:lowercase,
          \ '',
          \ '  schema "{}s" do',
          \ '',
          \ '  end',
          \]
  elseif a:lowercase == 'test'
    return ['  use '.b:phoenix_project_name.'.{testcase}']
  endif
endfunction

function! phoenix#setup_custom_transformations()
  function! g:projectionist_transformations.testcase(input, o) abort
    if a:input =~ '\(views\|controllers\)/\a\+'
      return 'ConnCase'
    elseif a:input =~ 'models/\a\+'
      return 'ModelCase'
    elseif a:input =~ 'channels/\a\+'
      return 'ChannelCase'
    endif
  endfunction
endfunction

function! phoenix#projections() abort
  return  {
        \  "web/controllers/*_controller.ex": {
        \     "type": "controller",
        \     "alternate": "test/controllers/{}_controller_test.exs",
        \     "template": s:template_for('controller', 'Controller')
        \  },
        \  "web/models/*.ex": {
        \     "type": "model",
        \     "alternate": "test/models/{}_test.exs",
        \     "template": s:template_for('model', 'Model')
        \  },
        \  "web/channels/*_channel.ex": {
        \     "type": "channel",
        \     "alternate": "test/channels/{}_channel_test.exs",
        \     "template": s:template_for('channel', 'Channel')
        \  },
        \  "web/views/*_view.ex": {
        \     "type": "view",
        \     "alternate": "test/views/{}_view_test.exs",
        \     "template": s:template_for('view', 'View')
        \  },
        \  "test/*_test.exs": {
        \     "type": "test",
        \     "alternate": "web/{}.ex",
        \     "template": s:template_for('test', 'Test')
        \  },
        \  "web/templates/*.html.eex": {
        \     "type": "template",
        \     "alternate": "web/views/{dirname|basename}_view.ex"
        \  },
        \  "web/static/css/*.css": { "type": "stylesheet" },
        \  "web/static/js/*.js": { "type": "javascript" },
        \  "web/router.ex": { "type": "router" },
        \  "config/*.exs": { "type": "config" },
        \  "mix.exs":     { "type": "mix" },
        \  "*": { "start": "mix phoenix.server",
        \         "path": "web/**"
        \  },
        \ }
endfunction

" }}}

" {{{ Generators

function! phoenix#generator(...) abort
  if len(a:000) > 0 && a:1 !~ '\(model\|html\|channel\|json\)'
    echom 'No generator: ' . a:1 . '. Avaiable generators: model, html, json, channel'
    return ""
  endif
  if len(a:000) < 2
    echom "Insufficient arguments for generator"
    return ""
  endif
  let old_makeprg = &l:makeprg
  let old_errorformat = &l:errorformat
  try
    let &l:makeprg = "mix phoenix.gen." . a:1 . " " . join(a:000[1:-1], " ")
    let &l:errorformat = '%# creating %f'
    noautocmd make!
  finally
    let &l:errorformat = old_errorformat
    let &l:makeprg = old_makeprg
  endtry
  if empty(getqflist())
    return ''
  else
    cfirst
  endif
endfunction

function! s:generator_complete(A, L, P) abort
  if a:L =~ '^Pgenerate \(model\|html\|channel\|json\)'
    return ""
  endif
  return "model\nhtml\nchannel\njson"
endfunction

" }}}



" {{{ Helpers
"
function! phoenix#camelize(str)
  let str = s:gsub(a:str,'/(.=)','::\u\1')
  let str = s:gsub(str,'%([_-]|<)(.)','\u\1')
  return str
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

" }}}

" {{{ Preview

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

" }}}

" {{{ Server

if !exists('g:phoenix_server_size')
  let g:phoenix_server_size = 15
endif
if !exists('g:phoenix_server_split')
  let g:phoenix_server_split = "split"
endif

function! s:server_open_cmd()
  return "botright " . g:phoenix_server_size . g:phoenix_server_split
endfunction

function! s:server_buffer_exists()
  return exists('s:phoenix_server_buffer') && bufexists(s:phoenix_server_buffer)
endfunction

function! phoenix#open_server()
  if has('nvim')
    if s:server_buffer_exists()
      let winno = bufwinnr(s:phoenix_server_buffer)
      " if the Pserver buffer is the current buffer, hide it
      if s:phoenix_server_buffer == bufnr("%")
        call phoenix#hide_server()

        " if the buffer is in an open window, switch to it
      elseif winno != -1
        exec winno . "wincmd w"
        startinsert

        " otherwise the buffer is hidden, open it in a new window
      else
        exec s:server_open_cmd() . " +buffer" . s:phoenix_server_buffer
        startinsert
      endif
    else
      " no Pserver buffer exists, open a new one
      exec s:server_open_cmd()
      terminal mix phoenix.server
      let s:phoenix_server_buffer = bufnr("%")
      startinsert
    endif
  elseif exists(':Start')
    exec "Start"
  else
    echom "Pserver requires either Neovim or Dispatch"
  endif
endfunction

function! phoenix#hide_server()
  if exists('s:phoenix_server_buffer')
    " only hide the window if it is open
    if bufwinnr(s:phoenix_server_buffer) != -1
      " Neovim has :{winnr}hide whereas Vim doesn't
      exec bufwinnr(s:phoenix_server_buffer) . "hide"
    endif
  endif
endfunction

" }}}
