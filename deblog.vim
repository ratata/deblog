" ===========================================================================
"           01000100 01100101 01100010 01101100 01101111 01100111
"                                                                   
"            _|_|_|              _|        _|                      
"            _|    _|    _|_|    _|_|_|    _|    _|_|      _|_|_|  
"            _|    _|  _|_|_|_|  _|    _|  _|  _|    _|  _|    _|  
"            _|    _|  _|        _|    _|  _|  _|    _|  _|    _|  
"            _|_|_|      _|_|_|  _|_|_|    _|    _|_|      _|_|_|  
"                                                              _|  
"                                                          _|_|    
"
"
"    Copyright: Copyright (C) ????-2011 Rune Heggtveit
"               Permission is hereby granted to use and distribute this code,
"               with or without modifications, provided that this copyright
"               notice is copied with it. 
"               Provided *as is* without warranty of any kind, what so ever, 
"               express or implied. In no event, imagined or realized, will
"               the copyright holder be liable or in other ways hold any
"               responsibility for any damages, negative outcome, resulting 
"               from the use of this software. This implies, but is not 
"               limited to, users who, whom, which or what or by other 
"               definitions define themselves as entities, or not, occupies 
"               this realm, any other, or not, in sickness and in health.
"        Files: deblog.vim, deblog.txt
"  Description: Log to file and or Vim
"   Maintainer: Rune Heggtveit (ratata_vim a7 yahoo d077 com)
" Last Changed: Sat, 29 January 2011
"      Version: 1.1.3
"      For Vim: >= 7 (afaik)
"        Usage: This file should be sourced from script or auto loaded. See
"               :help deblog.
"
"               No key mappings.
"
"               For more help see supplied documentation.
"
" ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
"
"
"   FOLDS:
"       _H_     Headings
"       _x_     Code executed locally
"       _f_     Function extending s:Deblog Dictionary
"       _fs_    Functions local to script
"       _fg_    Global functions
"
"
"
"
" Global variables:
" g:Deblog_public_name  - Name to deblog resource. Defaul g:Deblog
" g:Deblog_force_cmd    - Replace existing user commands. Default 1
" ( See  deblog.txt  :h deblog-config )
"
" Global functions:
" g:Deblog_new()        - Create new Deblog instance. Require unique
"                         g:Deblog_public_name else old one is replaced.
" ( See  deblog.txt  :h deblog-config )
"
" ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,|
"   D E B L O G     _x_     b a s e                                      {{{1
" ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''|
if exists('s:DEBLOG_LOADED')
    call g:Deblog_new()
    finish
endif

" These are the local variables
" s:sys                 - System information
" s:Deblog_ins          - List of instances, used by user commands
" s:Deblog              - From which all other instances are created

" System
if !exists('s:sys')
    let s:sys = {
        \'is_win'       : has("win16") || has("win32") ||
                        \ has("win64") || has("win95"),
        \'has_reltime'  : has('reltime')
        \}
endif

" Force cmd     - replace existing user commands
if !exists('g:Deblog_force_cmd')
    let g:Deblog_force_cmd = 1
endif

" Dictionary holding instructions on whether to create user commands
" If command does not exist, create it
" If command exists and iff g:Deblog_force_cmd == 1, create it
" @see  s:Deblog_update_usercmd()
if !exists('s:Deblog_force_cmd')
    let s:Deblog_force_cmd = {
                \ 'Erase': exists(':DeblogErase') ? g:Deblog_force_cmd : 1,
                \ 'DT'   : exists(':DT')          ? g:Deblog_force_cmd : 1,
                \ 'Head' : exists(':DeblogHead')  ? g:Deblog_force_cmd : 1,
                \ 'Level': exists(':DeblogLevel') ? g:Deblog_force_cmd : 1,
                \ 'Shell': exists(':DeblogShell') ? g:Deblog_force_cmd : 1,
                \ 'Lopen': exists(':DeblogLopen') ? g:Deblog_force_cmd : 1,
                \ 'Sopen': exists(':DeblogSopen') ? g:Deblog_force_cmd : 1,
                \ 'About': exists(':DeblogAbout') ? g:Deblog_force_cmd : 1
                \ }
endif

" Instances     - Holds all global instances of Deblog
if !exists('s:Deblog_ins')
    let s:Deblog_ins = []
endif

"            \ 'cmd_shell'  : 'gnome-terminal --geometry=70x70-0+0' .
"                           \ ' -t "VDL #FILE#" -e "tail -f #FILE#"',

" Core class with default settings
" This is used as base for all instances
let s:Deblog = {
            \ 'version'    : '1.1.3',
            \ 'public_name': 'g:Deblog',
            \ 'deblog'      : 'fiwh',
            \ 'file'       : $HOME.(s:sys.is_win ? '/' : '/.vim/').
                           \ 'my_deblog.log',
            \ 'htime'      : s:sys.has_reltime ? 0.5 : 1,
            \ 'timestamp'  : 1,
            \ 'prev_time'  : s:sys.has_reltime ? 0.0 : 0,
            \ 'separator'  : ';;' . repeat(' -', 30),
            \ 'cmd_shell'  : 'uxterm -fa "Liberation Mono" -fs 7 -fg black' .
                           \ ' -bg ivory -geometry 50x70-0+0 +sb -sl 500' .
                           \ ' -T "VDL #FILE#" -e "tail -f #FILE#" &',
            \ 'aushell_1'  : 0,
            \ 'cmd_split'  : 'bo 40vs | call self.lopen() | wincmd p',
            \ 'bufnr'      : -1,
            \ 'vimlog'     : 0
            \}
" ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,|
"   D E B L O G     _H_     M E S S A G I N G                            {{{1
" ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''|
" __________________________________________________________________________|
"   D E B L O G     _f_     spew(msg [, force])                          {{{1
" ==========================================================================|
" Append message to out-file
" @param msg    Message
" @param force  Iff force = 1, execute even if deblog flag is missing
" ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|
function! s:Deblog.spew(msg, ...) dict
    if self.deblog =~ 'f' || (a:0 == 1 && a:1 == 1)
        let cur_t = s:sys.has_reltime ? str2float(reltimestr(reltime())) 
                                \ : localtime()
        
        if self.file != '' && filewritable(self.file) == 1
            " Reset cursor position
            echon "\r"
            exe 'redir >> ' . self.file
                if self.htime >= 0 && (cur_t - self.prev_time >= self.htime)
                    if self.timestamp
                        silent echon ';;' . strftime('%Y-%m-%d %H:%M:%S')
                        if s:sys.has_reltime
                            silent echon '[' . 
                                   \ split(printf("%f", cur_t), '\.')[1] . "]"
                        endif
                        silent echon "\n"
                    else
                        silent echon self.separator . "\n"
                    endif
                endif
                silent echon a:msg . "\n"
            redir END
            
            " If log is viewed in Vim, reload it
            if self.vimlog
                call self.freshlog()
            endif
            
            let self.prev_time = cur_t
        endif
    endif
endfunction
"   D E B L O G     _f_     spewq(msg [, force])                         {{{1
" ==========================================================================|
" Append double quoted message to out-file
" @param msg    Message
" @param force  Iff force = 1, execute even if deblog flag is missing
" ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|
function! s:Deblog.spewq(msg, ...) dict
    let force = a:0 == 1 ? a:1 : 0
    call self.spew('"' . a:msg . '"', force)
endfunction
" __________________________________________________________________________|
"   D E B L O G     _f_     warning(msg [, force])                       {{{1
" ==========================================================================|
" Display waring - status line
" @param msg    Message
" @param force  Iff force = 1, execute even if deblog flag is missing
" ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|
function! s:Deblog.warning(msg, ...) dict
    if self.deblog =~ 'w' || (a:0 == 1 && a:1 == 1)
        echohl WarningMsg
        echomsg a:msg
        echohl None
    endif
endfunction
" __________________________________________________________________________|
"   D E B L O G     _f_     info(msg [, force])                          {{{1
" ==========================================================================|
" Display info - status line
" @param msg    Message
" @param force  Iff force = 1, execute even if deblog flag is missing
" ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|
function! s:Deblog.info(msg, ...) dict
    if self.deblog =~ 'i' || (a:0 == 1 && a:1 == 1)
        echohl Comment
        echomsg a:msg
        echohl None
    endif
endfunction
" __________________________________________________________________________|
"   D E B L O G     _f_     hmsg(msg, hl [, force])                      {{{1
" ==========================================================================|
" Display custom highlighted message - status line
" @param msg    Message
" @param hl     Highlight to use
" @param force  Iff force = 1, execute even if deblog flag is missing
" ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|
function! s:Deblog.hmsg(msg, hl, ...) dict
    if self.deblog =~ 'h' || (a:0 == 1 && a:1 == 1)
        exe 'echohl ' . a:hl
        echomsg a:msg
        echohl None
    endif
endfunction
" ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,|
"   D E B L O G     _H_     V I E W P O R T S                            {{{1
" ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''|
" __________________________________________________________________________|
"   D E B L O G     _f_     tail([n])                                    {{{1
" ==========================================================================|
" Display tail of log file in Vim status line
" @param n  number of lines to show, default last 10
" ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|
function! s:Deblog.tail(...) dict
    let n = -10
    if a:0 == 1 
        let n = str2nr(a:1) * -1
    endif
    let lines = readfile(self.file, "", n)
    if len(lines) == 0
        call self.info('Empty log file', 1)
    endif
    for line in lines
        call self.hmsg(line, 'ModeMsg', 1)
    endfor
endfunction
" __________________________________________________________________________|
"   D E B L O G     _f_     head([n])                                    {{{1
" ==========================================================================|
" Display head of log file in Vim status line
" @param n  number of lines to show, default first 10
" ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|
function! s:Deblog.head(...) dict
    let n = 10
    if a:0 == 1
        let n = str2nr(a:1)
    endif
    let lines = readfile(self.file, "", n)
    if len(lines) == 0
        call self.info('Empty log file', 1)
    endif
    for line in lines
        call self.hmsg(line, 'ModeMsg', 1)
    endfor
endfunction
" __________________________________________________________________________|
"   D E B L O G     _f_     shell()                                      {{{1
" ==========================================================================|
" Open shell
" Substitutes #FILE# with log file
" ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|
function! s:Deblog.shell() dict
    if self.cmd_shell != ''
        redraw
        let sm=&shortmess
        set shortmess=mt
        exe 'silent !' . substitute(self.cmd_shell, '#FILE#', self.file, 'g')
        let &shortmess=sm
    endif
endfunction
" ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,|
"   D E B L O G     _H_     V I E W P O R T  -  V I M W I N D O W        {{{1
" ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''|
" __________________________________________________________________________|
"   D E B L O G     _f_     haslogwin(focus)                             {{{1
" ==========================================================================|
" Check if log file is open in any window
" ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|
function! s:Deblog.haslogwin(focus) dict
    if self.file == ''
        return 0
    endif
    if self.bufnr != -1
        let lwin = bufwinnr(self.bufnr)
    else
        let bnr = bufnr(bufname(self.file))
        if bnr == -1 || (
                \ getbufvar(bnr, '&autoread')   != 1 &&
                \ getbufvar(bnr, '&bufhidden')  != 'delete' &&
                \ getbufvar(bnr, '&buflisted')  != 0 &&
                \ getbufvar(bnr, '&swapfile')   != 0)
            return 0
        endif
        let self.bufnr  = bnr
        let self.vimlog = 1
        let lwin = bufwinnr(bnr)
    endif
    if lwin == -1
        return 0
    endif
    let cwin = winnr()
    if a:focus
        exe lwin . 'wincmd w'
    endif
    return cwin
endfunction
" __________________________________________________________________________|
"   D E B L O G     _f_     lopen()                                      {{{1
" ==========================================================================|
" Open log file in current window
" Buffer is set with no listing and delete on hide
" Auto updated and cursor set to last line on spew() to log file
" Note: If log file is edited and saved within Vim, shell tail stops updating
" ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|
function! s:Deblog.lopen() dict
    if self.file == ''
        call self.warning('No logfile defined', 1)
        return
    endif
    
    if self.haslogwin(1) == 0
        if self.vimlog
            exe self.bufnr . 'b! | e'
        else
            exe 'e ' . self.file
        endif
    endif

    setlocal noreadonly
    setlocal autoread
    setlocal bufhidden=delete
    setlocal nobuflisted
    "setlocal nomodifiable
    setlocal noswapfile
    "setlocal buftype=nofile
    setlocal filetype=vimdebloglog
    setlocal statusline=%t

    normal G
endfunction
" __________________________________________________________________________|
"   D E B L O G     _f_     sopen()                                      {{{1
" ==========================================================================|
" Execute self.cmd_split iff log window does not exist
" A bit redundant to call haslogwin() twice, but hopefully one does not
" exec either in a loop ...
" ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|
function! s:Deblog.sopen() dict
    if self.haslogwin(0) == 0
        exe self.cmd_split
    endif
endfunction
" __________________________________________________________________________|
"   D E B L O G     _f_     freshlog()                                   {{{1
" ==========================================================================|
" Reload log file in Vim
" Executed by spew() if log file is opened in Vim
" ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|
function! s:Deblog.freshlog() dict
    let lwin = bufwinnr(self.bufnr)
    if lwin == -1
        return
    endif
    let cwin = winnr()
    exe lwin . 'wincmd w'
    exe 'silent! e'
    setlocal nobuflisted
    normal G
    if cwin != winnr()
        exe cwin . 'wincmd w'
    endif
endfunction
" __________________________________________________________________________|
"   D E B L O G     _f_     about()                                      {{{1
" ==========================================================================|
" echo self
" ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|
function! s:Deblog.about() dict
    redraw
    call self.info("DEBLOG:")
    for k in keys(self)
        call self.hmsg(printf("%'12s => %s", k, string(self[k])), 'ModeMsg')
    endfor 
endfunction
" ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,|
"   D E B L O G     _H_     C O N F I G U R A T I O N                    {{{1
" ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''|
" __________________________________________________________________________|
"   D E B L O G     _f_     setlevel(flag)                               {{{1
" ==========================================================================|
" Set level
" @param flag   string  =off, i=Vim info messages, w=Vim warning messages, 
"                       h=custom highlighted messages, f=spew to file
"                       Use +/- to add/remove from current
"                       If +/- are used and first char is not +/- flag is
"                       first reset to first char
"               Examples:
"                   level='fw', setlevel('+i'),   new level='fwi'
"                   level='fw', setlevel('-i'),   new level='fw'
"                   level='fw', setlevel('-w'),   new level='f'
"                   level='fw', setlevel('+f+i'), new level='fwi'
"                   level='fw', setlevel('f+i'),  new level='fi'
" ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|
function! s:Deblog.setlevel(flag) dict
    if a:flag != '' && a:flag !~#'^[iwfh+-]\+$'
        let bad = substitute(a:flag, '[iwfh+-]', '', 'g')
        call self.warning('Unknown flag: ' . bad . ' in "' . a:flag . '"', 1)
        return 0
    endif

    if a:flag !~'[+-]'
        let self.deblog = a:flag
        call self.info('New flag: "' . self.deblog . '"', 1)
        call self.filecheck()
        return 1
    endif

    let nd = self.deblog
    let l  = len(a:flag)
    let i  = 0
    let m  = ''
    while i < l
        if a:flag[i] =~ '[+-]'
            let m = a:flag[i]
        elseif m == ''
            let nd = a:flag[i]
        elseif m == '-'
            let nd = substitute(nd, a:flag[i], '', '')
        elseif nd !~ a:flag[i]
            let nd .= a:flag[i]
        endif
        let i += 1
    endwhile
    
    let self.deblog = nd
    call self.filecheck()
    call self.info('New flag: "' . self.deblog . '"', 1)
endfunction
" __________________________________________________________________________|
"   D E B L O G     _f_     filecheck()                                  {{{1
" ==========================================================================|
" Check out file, create if it does not exist
" @return int   1 on success, 0 on failure, -1 if missing f flag
" ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|
function! s:Deblog.filecheck() dict
    if self.deblog !~ 'f'
        return -1
    endif

    if self.file == ''
        call self.warning(
                    \ 'Deblog :: outfile is "" - nothing will be written.')
        let self.deblog = substitute(self.deblog, 'f', '', '')
        return 0
    endif

    " Iff file presumably does not exist - fake a touch
    if !filereadable(self.file)
        echon "\r"
        exe 'redir >> ' . self.file
            silent echon ''
        redir END
    endif

    if !filewritable(self.file)
        call self.warning("Deblog :: can't write to " . self.file . 
                        \ " - nothing will be written.")
        let self.deblog = substitute(self.deblog, 'f', '', '')
        return 0
    endif
    
    return 1
endfunction
" __________________________________________________________________________|
"   D E B L O G     _f_     init()                                       {{{1
" ==========================================================================|
" check and set all globals to instance
" --------------------------------------------------------------------------|
function! s:Deblog.init() dict
    " Check for custom name, redundant after _new(), but to be sure
    if exists('g:Deblog_public_name')
        let self.public_name = g:Deblog_public_name
    endif

    " Set global configuration
    for k in keys(self)
        if exists(self.public_name . '_' . k)
            let self[k] = {self.public_name . '_' . k}
            "unlet {self.public_name . '_' . k}
        endif
    endfor
    
    " If we do not have reltime round htime up
    " 0.5 sec becomes 1.0 etc.
    if !s:sys.has_reltime
        let self.htime = ceil(self.htime)
    endif

    if self.deblog == ''
        return -1
    endif

    call self.filecheck()
    
    if self.aushell_1 
        call self.shell()
        let self.aushell_1 = 0
    endif

    return 1
endfunction
" ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,|
"   D E B L O G     _H_     I N T E R N A L S                            {{{1
" ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''|
"
" ==========================================================================|
"   D E B L O G     _fs_    ins_au(A, L, P) : customlist for command     {{{1
" ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|
function! s:Deblog_ins_au(A, L, P)
    if a:L =~ '^[^ ]\+ [^ ]\+ '
        return []
    endif
    if a:L =~ '^DT$' || a:L =~ '^Deblog\(Level\|About\|Shell\)$'
        return [' ']
    endif
    let opt = []
    for i in range(0, len(s:Deblog_ins) - 1)
        if a:A =~ '^'.(i+1).'\|^$'
            call add(opt, (i+1) . '(' . s:Deblog_ins[i] . ')' )
        endif
    endfor
    return opt
endfunction
" ==========================================================================|
"   D E B L O G     _fs_    ins_call(what , ...) : exe cmd object        {{{1
" ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|
function! s:Deblog_ins_call(what, ...)
    let lni = len(s:Deblog_ins)
    let ins = lni == 1 ? 0 : -1
    let arg = a:what == 'setlevel' ? '?' : ''

    if a:0 > 0
        let ins = substitute(a:1, '[ ''"]', '', 'g')
        let ins = str2nr(matchstr(ins, '^[0-9]\+'))
        if ins == 0
            for i in range(0, lni - 1)
                if s:Deblog_ins[i] == a:1
                    let ins = i + 1
                    break
                endif
            endfor
        endif
        if ins == 0
            call {s:Deblog_ins[0]}.warning('Deblog:: ' . a:1 . ' not found')
            return 0
        endif
    endif
    if a:0 > 1
        let arg = substitute(a:2, '[ ''"]', '', 'g')
    endif

    if ins == -1
        let opt = ['Select Deblog to ' . a:what . ':']
        for i in range(0, lni - 1)
            call add(opt, (i + 1) . ' ' . s:Deblog_ins[i])
        endfor
        let ins = inputlist(opt)
        if ins == -1
            return 1
        endif
        echo "\r"
    endif
    if ins < 0 || ins > lni
        call {s:Deblog_ins[0]}.warning('Deblog:: ' .ins. ' is out of range')
        return 0
    endif
    
    if a:what == 'tail' && arg !~ '^-\?[0-9]*$'
        call {s:Deblog_ins[0]}.warning('Deblog:: ' . arg . ' not valid')
        return 0
    endif
    if a:what == 'setlevel' && arg == '?'
        let arg = input('Flag [+/-][iwfh], enter "" to blank, current ' .
                    \ {s:Deblog_ins[ins - 1]}.deblog . ' : ')
        if arg == ''
            echo "\r"
            return 1
        endif
    endif
    if a:what == 'setlevel'
        let arg = "'" . substitute(arg, '[ ''"]', '', 'g') . "'"
    endif
    "call {s:Deblog_ins[0]}.info(
    "       \ins . s:Deblog_ins[ins-1] . ' => ' . a:what . '(' . arg . ')' )
    exe 'call ' . s:Deblog_ins[ins-1] . '.' . a:what . '(' . arg . ')'
endfunction
" ==========================================================================|
"   D E B L O G     _fs_    update_usercmd() : create uservommdns        {{{1
" ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|
function s:Deblog_update_usercmd()
    let lins = len(s:Deblog_ins)

    if s:Deblog_force_cmd.Erase
        command! -nargs=0  
               \ DeblogErase call s:Deblog_purge_all()
    endif
    if s:Deblog_force_cmd.DT
        if lins == 1
            command! -nargs=*  DT
                   \ call s:Deblog_ins_call('tail', 1, <f-args>)
        else
            command! -nargs=* -complete=customlist,s:Deblog_ins_au 
                   \ DT call s:Deblog_ins_call('tail', <f-args>)
        endif
    endif
    if s:Deblog_force_cmd.Head
        if lins == 1
            command! -nargs=*  DeblogHead
                   \ call s:Deblog_ins_call('head', 1, <f-args>)
        else
            command! -nargs=* -complete=customlist,s:Deblog_ins_au 
                   \ DeblogHead call s:Deblog_ins_call('head', <f-args>)
        endif
    endif
    if s:Deblog_force_cmd.Level
        if lins == 1
            command! -nargs=* DeblogLevel 
                   \ call s:Deblog_ins_call('setlevel', 1, <f-args>)
        else
            command! -nargs=* -complete=customlist,s:Deblog_ins_au 
                   \ DeblogLevel call s:Deblog_ins_call('setlevel', <f-args>)
        endif
    endif
    if s:Deblog_force_cmd.Shell
        if lins == 1
            command! -nargs=0 -bar 
                   \ DeblogShell call s:Deblog_ins_call('shell', 1)
        else
            command! -nargs=? -bar -complete=customlist,s:Deblog_ins_au 
                   \ DeblogShell call s:Deblog_ins_call('shell', <f-args>)
        endif
    endif
    if s:Deblog_force_cmd.Lopen
        if lins == 1
            command! -nargs=0 -bar 
                   \ DeblogLopen call s:Deblog_ins_call('lopen', 1)
        else
            command! -nargs=? -bar -complete=customlist,s:Deblog_ins_au
                   \ DeblogLopen call s:Deblog_ins_call('lopen', <f-args>)
        endif
    endif
    if s:Deblog_force_cmd.Sopen
        if lins == 1
            command! -nargs=0 -bar 
                   \ DeblogSopen call s:Deblog_ins_call('sopen', 1)
        else
            command! -nargs=? -bar -complete=customlist,s:Deblog_ins_au
                   \ DeblogSopen call s:Deblog_ins_call('sopen', <f-args>)
        endif
    endif
    if s:Deblog_force_cmd.About
        if lins == 1
            command! -nargs=0 -bar 
                   \ DeblogAbout call s:Deblog_ins_call('about', 1)
        else
            command! -nargs=? -bar -complete=customlist,s:Deblog_ins_au
                   \ DeblogAbout call s:Deblog_ins_call('about', <f-args>)
        endif
    endif
endfunction
" ==========================================================================|
"   D E B L O G     _fs_    purge_all() : erase most of it               {{{1
" ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|
" If you for some reason would like to remove all Deblog instances and other
" traces of it, call this function. Also available trough user command 
" DeblogErase.
function! s:Deblog_purge_all()
    for ins in s:Deblog_ins
        for k in keys({ins})
            if exists({ins}.public_name . '_' . k)
                unlet {ins}_{k}
            endif
        endfor
        unlet {ins}
    endfor
    unlet s:Deblog_ins
    for [k, v] in items(s:Deblog_force_cmd)
        if v == 1
            if k != 'DT'
                exe 'delcommand Deblog' . k
            else
                delcommand DT
            endif
        endif
    endfor
    delfunction s:Deblog_ins_au
    delfunction s:Deblog_ins_call
    delfunction s:Deblog_update_usercmd
    delfunction g:Deblog_new
    unlet s:sys
    unlet s:Deblog_force_cmd
    unlet g:Deblog_force_cmd
    unlet! g:Deblog_public_name
    unlet s:DEBLOG_LOADED
endfunction
" ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,|
"   D E B L O G     _H_     G L O B A L                                  {{{1
" ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''|
"
" ==========================================================================|
"   D E B L O G     _fg_    new() : build new instance                   {{{1
" ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|
function g:Deblog_new()
    let s:Deblog.public_name = exists('g:Deblog_public_name') ?
                             \ g:Deblog_public_name :
                             \ 'g:Deblog'

    let {s:Deblog.public_name} = deepcopy(s:Deblog)
    " Set configurations
    call {s:Deblog.public_name}.init()

    " If this is a re-load and vim log-window is active, re-activate logging
    call {s:Deblog.public_name}.haslogwin(0)

    " Remove old instance if it exists, - can be new configuration
    let ix = index(s:Deblog_ins, {s:Deblog.public_name}.public_name)
    if ix != -1
        call remove(s:Deblog_ins, ix)
    endif
    unlet ix
    call add(s:Deblog_ins, {s:Deblog.public_name}.public_name)

    " If number of instances are < 3 update user commands
    if len(s:Deblog_ins) < 3
        call s:Deblog_update_usercmd()
    endif
endfunction


" ==========================================================================|
"
"
" __________________________________________________________________________|
"   D E B L O G     _x_     I N I T I A L I Z E                          {{{1
" ==========================================================================|

call g:Deblog_new()

let s:DEBLOG_LOADED = 1

"unlet s:Deblog
