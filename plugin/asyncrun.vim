" asyncrun.vim - Run shell commands in background and output to quickfix
"
" Maintainer: skywind3000 (at) gmail.com, 2016-2022
" Homepage: https://github.com/skywind3000/asyncrun.vim
"
" Last Modified: 2022/03/08 14:33
"
" Run shell command in background and output to quickfix:
"     :AsyncRun[!] [options] {cmd} ...
"
"     when "!" is included, auto-scroll in quickfix will be disabled
"     parameters are splited by space, if a parameter contains space,
"     it should be quoted or escaped as backslash + space (unix only).
"
" Parameters will be expanded if they start with '%', '#' or '<' :
"     %:p     - File name of current buffer with full path
"     %:t     - File name of current buffer without path
"     %:p:h   - File path of current buffer without file name
"     %:e     - File extension of current buffer
"     %:t:r   - File name of current buffer without path and extension
"     %       - File name relativize to current directory
"     %:h:.   - File path relativize to current directory
"     <cwd>   - Current directory
"     <cword> - Current word under cursor
"     <cfile> - Current file name under cursor
"     <root>  - Project root directory
"
" Environment variables are set before executing:
"     $VIM_FILEPATH  - File name of current buffer with full path
"     $VIM_FILENAME  - File name of current buffer without path
"     $VIM_FILEDIR   - Full path of current buffer without the file name
"     $VIM_FILEEXT   - File extension of current buffer
"     $VIM_FILENOEXT - File name of current buffer without path and extension
"     $VIM_PATHNOEXT - File name with full path but without extension
"     $VIM_CWD       - Current directory
"     $VIM_RELDIR    - File path relativize to current directory
"     $VIM_RELNAME   - File name relativize to current directory
"     $VIM_ROOT      - Project root directory
"     $VIM_CWORD     - Current word under cursor
"     $VIM_CFILE     - Current filename under cursor
"     $VIM_GUI       - Is running under gui ?
"     $VIM_VERSION   - Value of v:version
"     $VIM_MODE      - Execute via 0:!, 1:makeprg, 2:system(), 3:silent
"     $VIM_COLUMNS   - How many columns in vim's screen
"     $VIM_LINES     - How many lines in vim's screen
"
"     Parameters also accept these environment variables wrapped by
"     "$(...)", and "$(VIM_FILEDIR)" will be expanded as file directory.
"
"     It is safe to use "$(...)" than "%:xx" when filenames contain spaces.
"
" There can be some options before [cmd]:
"     -mode=0/1/2  - start mode: 0(async, default), 1(makeprg), 2(!)
"     -cwd=?       - initial directory, (use current directory if unset)
"     -save=0/1/2  - non-zero to save current/1 or all/2 modified buffer(s)
"     -program=?   - set to 'make' to use '&makeprg'
"     -raw=1       - use raw output (not match with the errorformat)
"
"     All options must start with a minus and position **before** `[cmd]`.
"     Since no shell command starts with a minus. So they can be
"     distinguished from shell command easily without any ambiguity.
"
" Stop the running job by signal TERM:
"     :AsyncStop[!]
"
"     when "!" is included, job will be stopped by signal KILL
"
" Settings:
"     g:asyncrun_exit - script will be executed after finished
"     g:asyncrun_bell - non-zero to ring a bell after finished
"     g:asyncrun_mode - 0:async(require vim 7.4.1829) 1:sync 2:shell
"     g:asyncrun_encs - shell program output encoding
"     g:asyncrun_open - open quickfix window at given height
"
" Modes:
"     -mode=async     - run in quickfix window (default)
"     -mode=make      - run in makeprg
"     -mode=bang      - run in !xxx
"     -mode=system    - run in new system window (windows) or ! (others)
"     -mode=terminal  - run in a reusable terminal window
"
" Variables:
"     g:asyncrun_code - exit code
"     g:asyncrun_status - 'running', 'success' or 'failure'
"
" Requirements:
"     vim 7.4.1829 is minimal version to support async mode
"     vim 8.1.1 is minial version to use "-mode=term"
"
" Examples:
"     :AsyncRun gcc % -o %<
"     :AsyncRun make
"     :AsyncRun -raw -cwd=$(VIM_FILEDIR) python "$(VIM_FILEPATH)"
"     :AsyncRun -cwd=<root> make
"     :AsyncRun! grep -n -R <cword> .
"     :noremap <F7> :AsyncRun gcc % -o %< <cr>
"
" Run in the internal terminal:
"     :AsyncRun -mode=term bash
"     :AsyncRun -mode=term -pos=tab bash
"     :AsyncRun -mode=term -pos=curwin bash
"     :AsyncRun -mode=term -pos=top -rows=15 bash
"     :AsyncRun -mode=term -pos=bottom -rows=15 bash
"     :AsyncRun -mode=term -pos=left -cols=40 bash
"     :AsyncRun -mode=term -pos=right -cols=40 bash
"
" Additional:
"     AsyncRun uses quickfix window to show job outputs, in order to
"     see the outputs in realtime, you need open quickfix window at
"     first by using :copen (see :help copen/cclose). Or use
"     ':call asyncrun#quickfix_toggle(8)' to open/close it rapidly.
"

" vim: set et fenc=utf-8 ff=unix sts=4 sw=4 ts=4 :


"----------------------------------------------------------------------
"- Global Settings & Variables
"----------------------------------------------------------------------

" script will be executed after finished.
let g:asyncrun_exit = get(g:, 'asyncrun_exit', '')

" non-zero to ring a bell after finished.
let g:asyncrun_bell = get(g:, 'asyncrun_bell', 0)

" stoponexit option of job_start
let g:asyncrun_stop = get(g:, 'asyncrun_stop', '')

" specify how to run your command
let g:asyncrun_mode = get(g:, 'asyncrun_mode', 0)

" Use quickfix-ID to allow concurrent use of quickfix list and not
" interleave streamed output of a running command with output from
" other plugins
if !exists('g:asyncrun_qfid')
	let g:asyncrun_qfid = has('patch-8.0.1023') || has('nvim-0.6.1')
en

" command hook
let g:asyncrun_hook = get(g:, 'asyncrun_hook', '')

" quickfix scroll mode
let g:asyncrun_last = get(g:, 'asyncrun_last', 0)

" speed for each timer
let g:asyncrun_timer = get(g:, 'asyncrun_timer', 50)

" previous exit code
let g:asyncrun_code = get(g:, 'asyncrun_code', '')

" status: 'running', 'success' or 'failure'
let g:asyncrun_status = get(g:, 'asyncrun_status', '')

" command encoding
let g:asyncrun_encs = get(g:, 'asyncrun_encs', '')

" trim empty lines ?
let g:asyncrun_trim = get(g:, 'asyncrun_trim', 0)

" user text
let g:asyncrun_text = get(g:, 'asyncrun_text', '')

" enable local errorformat ?
let g:asyncrun_local = get(g:, 'asyncrun_local', 1)

" name of autocmd in QuickFixCmdPre / QuickFixCmdPost
let g:asyncrun_auto = get(g:, 'asyncrun_auto', '')

" specify shell rather than &shell
let g:asyncrun_shell = get(g:, 'asyncrun_shell', '')

" specify shell cmd flag rather than &shellcmdflag
let g:asyncrun_shellflag = get(g:, 'asyncrun_shellflag', '')

" external runners for '-mode=terminal'
let g:asyncrun_runner = get(g:, 'asyncrun_runner', {})

" command modifier for '-program=xxx'
let g:asyncrun_program = get(g:, 'asyncrun_program', {})

" command translator for '-program=xxx'
let g:asyncrun_translator = get(g:, 'asyncrun_translator', {})

" silent the autocmds ?
let g:asyncrun_silent = get(g:, 'asyncrun_silent', 1)

" skip autocmds
let g:asyncrun_skip = get(g:, 'asyncrun_skip', 0)

" last args
let g:asyncrun_info = get(g:, 'asyncrun_info', '')

" 0: no save, 1: save current buffer, 2: save all modified buffers.
let g:asyncrun_save = get(g:, 'asyncrun_save', 0)

" enable stdin ?
if !exists('g:asyncrun_stdin')
	let g:asyncrun_stdin = has('win32') || has('win64') || has('win95')
en

" external script for '-mode=4'
let g:asyncrun_script = get(g:, 'asyncrun_script', '')

" strict to execute vim script
let g:asyncrun_strict = get(g:, 'asyncrun_strict', 0)

" events
let g:asyncrun_event = get(g:, 'asyncrun_event', {})

" terminal job name
let g:asyncrun_name = ''



"----------------------------------------------------------------------
"- Internal Functions
"----------------------------------------------------------------------

" error message
fun! s:ErrorMsg(msg)
	echohl ErrorMsg
	echom 'ERROR: '. a:msg
	echohl NONE
endfunc

" show not support message
fun! s:NotSupport()
	let msg = "required: +timers +channel +job and vim >= 7.4.1829"
	call s:ErrorMsg(msg)
endfunc

" run autocmd
fun! s:AutoCmd(name)
	if has('autocmd') && ((g:asyncrun_skip / 2) % 2) == 0
		if g:asyncrun_silent
			exec 'silent doautocmd User AsyncRun'.a:name
		el
			exec 'doautocmd User AsyncRun'.a:name
		en
	en
endfunc

" change directory with right command
fun! s:chdir(path)
	if has('nvim')
		let cmd = haslocaldir()? 'lcd' : (haslocaldir(-1, 0)? 'tcd' : 'cd')
	el
		let cmd = haslocaldir()? ((haslocaldir() == 1)? 'lcd' : 'tcd') : 'cd'
	en
	silent execute cmd . ' '. fnameescape(a:path)
endfunc

" safe shell escape for neovim
fun! s:shellescape(path)
	if s:asyncrun_windows == 0
		return shellescape(a:path)
	en
	let hr = shellescape(a:path)
	if &ssl != 0
		let hr = s:StringReplace(hr, "'", '"')
	en
	return hr
endfunc

" save/restore view
fun! s:save_restore_view(mode)
	if a:mode == 0
		let w:__asyncrun_view__ = winsaveview()
	elseif exists('w:__asyncrun_view__')
		call winrestview(w:__asyncrun_view__)
		unlet w:__asyncrun_view__
	en
endfunc

let s:asyncrun_windows = 0
let g:asyncrun_windows = 0
let s:asyncrun_support = 0
let g:asyncrun_support = 0
let s:asyncrun_gui = has('gui_running')
let g:asyncrun_gui = has('gui_running')

" check running in windows
if has('win32') || has('win64') || has('win95') || has('win16')
	let s:asyncrun_windows = 1
	let g:asyncrun_windows = 1
en

" check has advanced mode
if (v:version >= 800 || has('patch-7.4.1829')) && (!has('nvim'))
	if has('job') && has('channel') && has('timers')
		let s:asyncrun_support = 1
		let g:asyncrun_support = 1
	en
elseif has('nvim')
	let s:asyncrun_support = 1
	let g:asyncrun_support = 1
en

" check is gui loaded in neovim
if has('nvim')
	if exists('g:GuiLoaded')
		if g:GuiLoaded != 0
			let s:asyncrun_gui = 1
			let g:asyncrun_gui = 1
		en
	elseif exists('*nvim_list_uis') && len(nvim_list_uis()) > 0
		let uis = nvim_list_uis()[0]
		let s:asyncrun_gui = get(uis, 'ext_termcolors', 0)? 0 : 1
		let g:asyncrun_gui = s:asyncrun_gui
	elseif exists("+termguicolors") && (&termguicolors) != 0
		let s:asyncrun_gui = 1
		let g:asyncrun_gui = 1
	en
en

" check qfid
let s:has_qfid = has('patch-8.0.1023') || has('nvim-0.6.1')


"----------------------------------------------------------------------
"- build in background
"----------------------------------------------------------------------
let s:async_nvim = has('nvim')? 1 : 0
let s:async_info = {
\ 'text'      :  "" ,
\ 'post'      :  '' ,
\ 'postsave'  :  '' ,
\ 'qfid'      :  -1 ,
\ }
let s:async_output  = {}
let s:async_head    = 0
let s:async_tail    = 0
let s:async_code    = 0
let s:async_state   = 0
let s:async_start   = 0
let s:async_debug   = 0
let s:async_quick   = 0
let s:async_scroll  = 0
let s:async_congest = 0
let s:async_efm = &errorformat
let s:async_term = {}

" check :cbottom available ?
if s:async_nvim == 0
	let s:async_quick = (v:version >= 800 || has('patch-7.4.1997'))? 1 : 0
el
	let s:async_quick = has('nvim-0.2.0')? 1 : 0
en

" check if we have vim 8.0.100
if s:async_nvim == 0 && v:version >= 800
	let s:async_congest = has('patch-8.0.100')? 1 : 0
	let s:async_congest = 0
en

" append to quickfix
fun! s:AppendText(textlist, raw)
	let qfid = s:async_info.qfid
	if qfid < 0
		if a:raw == 0
			if and(g:asyncrun_skip, 1) == 0
				caddexpr a:textlist
			el
				noautocmd caddexpr a:textlist
			en
		el
			let items = []
			for text in a:textlist
				let items += [{'text': text}]
			endfor
			if and(g:asyncrun_skip, 1) == 0
				call setqflist(items, 'a')
			el
				noautocmd call setqflist(items, 'a')
			en
			unlet items
		en
	el
		let info = {'id': qfid}
		if a:raw == 0
			let info.lines = a:textlist
		el
			let items = []
			for text in a:textlist
				let items += [{'text': text}]
			endfor
			let info.items = items
		en
		if and(g:asyncrun_skip, 1) == 0
			call setqflist([], 'a', info)
		el
			noautocmd call setqflist([], 'a', info)
		en
		unlet info
	en
endfunc

" quickfix window cursor check
fun! s:AsyncRun_Job_Cursor()
	if &buftype == 'quickfix'
		if line('.') != line('$')
			let s:async_check_last = 0
		en
	en
endfunc

" find quickfix window and scroll to the bottom then return last window
fun! s:AsyncRun_Job_AutoScroll()
	if s:async_quick == 0
		if &buftype == 'quickfix'
			silent exec 'normal! G'
		en
	el
		cbottom
	en
endfunc

" check if quickfix window can scroll now
fun! s:AsyncRun_Job_CheckScroll()
	if g:asyncrun_last == 0
		if &buftype == 'quickfix'
			return (line('.') == line('$'))
		el
			return 1
		en
	elseif g:asyncrun_last == 1
		let s:async_check_last = 1
		let l:winnr = winnr()
		" Execute AsyncRun_Job_Cursor() in quickfix
		let l:quickfixwinnr = bufwinnr("[Quickfix List]")
		if l:quickfixwinnr != -1  " -1 mean the buffer has no window or do not exists
			noautocmd exec '' . l:quickfixwinnr . 'windo call s:AsyncRun_Job_Cursor()'
		en
		noautocmd silent! exec ''.l:winnr.'wincmd w'
		return s:async_check_last
	elseif g:asyncrun_last == 2
		return 1
	el
		if &buftype == 'quickfix'
			return (line('.') == line('$'))
		el
			return (!pumvisible())
		en
	en
endfunc

" invoked on timer or finished
fun! s:AsyncRun_Job_Update(count, ...)
	let encoding = s:async_info.encoding
	let encoding = (encoding != '')? encoding : (g:asyncrun_encs)
	let l:iconv = (encoding != "")? 1 : 0
	let l:count = 0
	let l:total = 0
	let l:check = s:AsyncRun_Job_CheckScroll()
	let l:efm1 = &g:efm
	let l:efm2 = &l:efm
	let once = (a:0 < 1)? get(g:, 'asyncrun_once', 0) : (a:1)
	if encoding == &encoding
		let l:iconv = 0
	en
	if g:asyncrun_local != 0
		let &l:efm = s:async_info.errorformat
		let &g:efm = s:async_info.errorformat
	en
	let pathfix = get(g:, 'asyncrun_pathfix', 0)
	if pathfix != 0
		let l:previous_cwd = getcwd()
		silent! call s:chdir(s:async_info.cwd)
	en
	let l:raw = (&efm == '')? 1 : 0
	if s:async_info.raw == 1
		let l:raw = 1
	en
	if once != 0
		let array = []
	en
	while s:async_tail < s:async_head
		let l:text = s:async_output[s:async_tail]
		if l:iconv != 0
			try
				let l:text = iconv(l:text, encoding, &encoding)
			catch /.*/
			endtry
		en
		let l:text = substitute(l:text, '\r$', '', 'g')
		if once == 0
			if l:text != ''
				call s:AppendText([l:text], l:raw)
			elseif g:asyncrun_trim == 0
				call s:AppendText([''], l:raw)
			en
		el
			if l:text != ''
				let array += [l:text]
			elseif g:asyncrun_trim == 0
				let array += [l:text]
			en
		en
		let l:total += 1
		unlet s:async_output[s:async_tail]
		let s:async_tail += 1
		let l:count += 1
		if a:count > 0 && l:count >= a:count
			break
		en
	endwhile
	if once != 0
		call s:AppendText(array, l:raw)
		unlet array
	en
	if pathfix != 0
		silent! call s:chdir(l:previous_cwd)
	en
	if g:asyncrun_local != 0
		if l:efm1 != &g:efm | let &g:efm = l:efm1 | endif
		if l:efm2 != &l:efm | let &l:efm = l:efm2 | endif
	en
	if s:async_scroll != 0 && l:total > 0 && l:check != 0
		call s:AsyncRun_Job_AutoScroll()
	en
	return l:count
endfunc

" trigger autocmd
fun! s:AsyncRun_Job_AutoCmd(mode, auto)
	if !has('autocmd') | return | endif
	let name = (a:auto == '')? g:asyncrun_auto : a:auto
	if name !~ '^\w\+$' || name == 'NONE' || name == '<NONE>'
		return
	en
	if ((g:asyncrun_skip / 4) % 2) != 0
		return 0
	en
	if a:mode == 0
		if g:asyncrun_silent
			silent exec 'doautocmd QuickFixCmdPre '. name
		el
			exec 'doautocmd QuickFixCmdPre '. name
		en
	el
		if g:asyncrun_silent
			silent exec 'doautocmd QuickFixCmdPost '. name
		el
			exec 'doautocmd QuickFixCmdPost '. name
		en
	en
endfunc

" invoked on timer
fun! g:AsyncRun_Job_OnTimer(id)
	let limit = (g:asyncrun_timer < 10)? 10 : g:asyncrun_timer
	" check on command line window
	if &ft == 'vim' && &buftype == 'nofile'
		return
	en
	if s:async_nvim == 0
		if exists('s:async_job')
			call job_status(s:async_job)
		en
	en
	if s:async_info.once == 0
		call s:AsyncRun_Job_Update(limit)
	en
	if and(s:async_state, 7) == 7
		if s:async_info.once != 0
			call s:AsyncRun_Job_Update(-1, 1)
		en
		if s:async_head == s:async_tail
			call s:AsyncRun_Job_OnFinish()
		en
	en
endfunc

" invoked on "callback" when job output
fun! s:AsyncRun_Job_OnCallback(channel, text)
	if !exists("s:async_job")
		return
	en
	if type(a:text) != 1
		return
	en
	let s:async_output[s:async_head] = a:text
	let s:async_head += 1
	if s:async_congest != 0
		if s:async_info.once == 0
			call s:AsyncRun_Job_Update(-1)
		en
	en
endfunc

" because exit_cb and close_cb are disorder, we need OnFinish to guarantee
" both of then have already invoked
fun! s:AsyncRun_Job_OnFinish()
	" caddexpr '(OnFinish): '.a:what.' '.s:async_state
	if s:async_state == 0
		return -1
	en
	if exists('s:async_job')
		unlet s:async_job
	en
	if exists('s:async_timer')
		call timer_stop(s:async_timer)
		unlet s:async_timer
	en
	call s:AsyncRun_Job_Update(-1, s:async_info.once)
	let l:current = localtime()
	let l:last = l:current - s:async_start
	let l:check = s:AsyncRun_Job_CheckScroll()
	if s:async_code == 0
		"\ let l:text = "[Finished in ".l:last." seconds]"
		let l:text = ""
		if !s:async_info.strip
			call s:AppendText([l:text], 1)
		en
		let g:asyncrun_status = "success"
	el
		let l:text = 'with code '.s:async_code
		let l:text = "[Finished in ".l:last." seconds ".l:text."]"
		call s:AppendText([l:text], 1)
		let g:asyncrun_status = "failure"
	en
	let s:async_state = 0
	if s:async_scroll != 0 && l:check != 0
		call s:AsyncRun_Job_AutoScroll()
	en
	let g:asyncrun_code = s:async_code
	let g:asyncrun_name = ''
	if g:asyncrun_bell != 0
		exec "norm! \<esc>"
	en
	if s:async_info.post != ''
		exec s:async_info.post
		let s:async_info.post = ''
	en
	if g:asyncrun_exit != ""
		exec g:asyncrun_exit
	en
	call s:AsyncRun_Job_AutoCmd(1, s:async_info.auto)
	call s:AutoCmd('Stop')
	redrawstatus!
	redraw
endfunc

" invoked on "close_cb" when channel closed
fun! s:AsyncRun_Job_OnClose(channel)
	" caddexpr "[close]"
	let s:async_debug = 1
	let l:limit = 128
	let l:options = {'timeout':0}
	while ch_status(a:channel) == 'buffered'
		let l:text = ch_read(a:channel, l:options)
		if l:text == '' " important when child process is killed
			let l:limit -= 1
			if l:limit < 0 | break | endif
		el
			call s:AsyncRun_Job_OnCallback(a:channel, l:text)
		en
	endwhile
	let s:async_debug = 0
	if exists('s:async_job')
		call job_status(s:async_job)
	en
	let s:async_state = or(s:async_state, 4)
endfunc

" invoked on "exit_cb" when job exited
fun! s:AsyncRun_Job_OnExit(job, message)
	" caddexpr "[exit]: ".a:message." ".type(a:message)
	let s:async_code = a:message
	let s:async_state = or(s:async_state, 2)
endfunc

" invoked on neovim when stderr/stdout/exit
fun! s:AsyncRun_Job_NeoVim(job_id, data, event)
	if a:event == 'stdout' || a:event == 'stderr'
		let l:index = 0
		let l:size = len(a:data)
		let cache = (a:event == 'stdout')? s:neovim_stdout : s:neovim_stderr
		while l:index < l:size
			let cache .= a:data[l:index]
			if l:index + 1 < l:size
				let s:async_output[s:async_head] = cache
				let s:async_head += 1
				let cache = ''
			en
			let l:index += 1
		endwhile
		if a:event == 'stdout'
			let s:neovim_stdout = cache
		el
			let s:neovim_stderr = cache
		en
	elseif a:event == 'exit'
		if type(a:data) == type(1)
			let s:async_code = a:data
		en
		if s:neovim_stdout != ''
			let s:async_output[s:async_head] = s:neovim_stdout
			let s:async_head += 1
		en
		if s:neovim_stderr != ''
			let s:async_output[s:async_head] = s:neovim_stderr
			let s:async_head += 1
		en
		let s:async_state = or(s:async_state, 6)
	en
endfunc


"----------------------------------------------------------------------
" AsyncRun Interface
"----------------------------------------------------------------------

" start background build
fun! s:AsyncRun_Job_Start(cmd)
	let l:running = 0
	let l:empty = 0
	if s:asyncrun_support == 0
		call s:NotSupport()
		return -1
	en
	if exists('s:async_job')
		if !has('nvim')
			if job_status(s:async_job) == 'run'
				let l:running = 1
			en
		el
			if s:async_job > 0
				let l:running = 1
			en
		en
	en
	if type(a:cmd) == 1
		if a:cmd == '' | let l:empty = 1 | endif
	elseif type(a:cmd) == 3
		if a:cmd == [] | let l:empty = 1 | endif
	en
	if s:async_state != 0 || l:running != 0
		call s:ErrorMsg("background job is still running")
		return -2
	en
	if l:empty != 0
		call s:ErrorMsg("empty arguments")
		return -3
	en
	let l:args = []
	if g:asyncrun_shell == ''
		let l:args += split(&shell)
		let l:args += split(&shellcmdflag)
	el
		let l:args += split(g:asyncrun_shell)
		let l:args += split(g:asyncrun_shellflag)
	en
	let s:async_info.errorformat = s:async_efm
	let l:name = []
	if type(a:cmd) == 1
		let l:name = a:cmd
		if s:asyncrun_windows == 0
			let l:args += [a:cmd]
		el
			let l:tmp = s:ScriptWrite(a:cmd, 0)
			if s:async_nvim == 0
				let l:args += [l:tmp]
			el
				let l:args = s:shellescape(l:tmp)
			en
		en
	elseif type(a:cmd) == 3
		if s:asyncrun_windows == 0
			let l:temp = []
			for l:item in a:cmd
				if index(['|', '`'], l:item) < 0
					let l:temp += [fnameescape(l:item)]
				el
					let l:temp += ['|']
				en
			endfor
			let l:args += [join(l:temp, ' ')]
		el
			let l:args += a:cmd
		en
		let l:vector = []
		for l:x in a:cmd
			let l:vector += ['"'.l:x.'"']
		endfor
		let l:name = join(l:vector, ', ')
	en
	let s:async_state = 0
	let s:async_output = {}
	let s:async_head = 0
	let s:async_tail = 0
	let s:async_info.post = s:async_info.postsave
	let s:async_info.auto = s:async_info.autosave
	let s:async_info.postsave = ''
	let s:async_info.autosave = ''
	let s:async_info.qfid = -1
	let g:asyncrun_text = s:async_info.text
	call s:AutoCmd('Pre')
	if s:async_nvim == 0
		let l:options = {}
		let l:options['callback'] = function('s:AsyncRun_Job_OnCallback')
		let l:options['close_cb'] = function('s:AsyncRun_Job_OnClose')
		let l:options['exit_cb'] = function('s:AsyncRun_Job_OnExit')
		if v:version < 800
			let l:options['exit_cb'] = "<SID>AsyncRun_Job_OnExit"
		en
		let l:options['out_io'] = 'pipe'
		let l:options['err_io'] = 'out'
		let l:options['in_io'] = 'null'
		let l:options['out_mode'] = 'nl'
		let l:options['err_mode'] = 'nl'
		let l:options['stoponexit'] = 'term'
		if g:asyncrun_stop != ''
			let l:options['stoponexit'] = g:asyncrun_stop
		en
		if s:async_info.range > 0
			let l:options['in_io'] = 'buffer'
			let l:options['in_mode'] = 'nl'
			let l:options['in_buf'] = s:async_info.range_buf
			let l:options['in_top'] = s:async_info.range_top
			let l:options['in_bot'] = s:async_info.range_bot
		elseif exists('*ch_close_in')
			if g:asyncrun_stdin != 0
				let l:options['in_io'] = 'pipe'
			en
		en
		let s:async_job = job_start(l:args, l:options)
		let l:success = (job_status(s:async_job) != 'fail')? 1 : 0
		if l:success && l:options['in_io'] == 'pipe'
			silent! call ch_close_in(job_getchannel(s:async_job))
		en
	el
		let l:callbacks = {'shell': 'AsyncRun'}
		let l:callbacks['on_stdout'] = function('s:AsyncRun_Job_NeoVim')
		let l:callbacks['on_stderr'] = function('s:AsyncRun_Job_NeoVim')
		let l:callbacks['on_exit'] = function('s:AsyncRun_Job_NeoVim')
		let s:neovim_stdout = ''
		let s:neovim_stderr = ''
		if s:async_info.range <= 0
			if g:asyncrun_stdin == 0 && has('nvim-0.6.0')
				let l:callbacks.stdin = 'null'
			en
		en
		let s:async_job = jobstart(l:args, l:callbacks)
		let l:success = (s:async_job > 0)? 1 : 0
		if l:success != 0
			if s:async_info.range > 0
				let l:top = s:async_info.range_top
				let l:bot = s:async_info.range_bot
				let l:lines = getline(l:top, l:bot)
				if exists('*chansend')
					call chansend(s:async_job, l:lines)
				elseif exists('*jobsend')
					call jobsend(s:async_job, l:lines)
				en
			en
			if exists('*chanclose')
				silent! call chanclose(s:async_job, 'stdin')
			elseif exists('*jobclose')
				silent! call jobclose(s:async_job, 'stdin')
			en
		en
	en
	if l:success != 0
		let s:async_state = or(s:async_state, 1)
		let g:asyncrun_status = "running"
		let s:async_start = localtime()
		let l:arguments = "[".l:name."]"
		let l:title = ':AsyncRun ' . l:name
		if !s:async_info.append
			call setqflist([], ' ', l:title)
		en
		if g:asyncrun_qfid && s:has_qfid
			let s:async_info.qfid = getqflist({'id':0}).id
		en
		if !s:async_info.strip
			call s:AppendText([l:arguments], 1)
		en
		let l:name = 'g:AsyncRun_Job_OnTimer'
		let s:async_timer = timer_start(100, l:name, {'repeat':-1})
		call s:AsyncRun_Job_AutoCmd(0, s:async_info.auto)
		call s:AutoCmd('Start')
		redrawstatus!
	el
		unlet s:async_job
		call s:ErrorMsg("Background job start failed '".a:cmd."'")
		redrawstatus!
		return -5
	en
	return 0
endfunc


" stop background job
fun! s:AsyncRun_Job_Stop(how)
	let l:how = (a:how != '')? a:how : 'term'
	if s:asyncrun_support == 0
		call s:NotSupport()
		return -1
	en
	while s:async_head > s:async_tail
		let s:async_head -= 1
		unlet s:async_output[s:async_head]
	endwhile
	if exists('s:async_job')
		if s:async_nvim == 0
			if job_status(s:async_job) == 'run'
				if job_stop(s:async_job, l:how)
					call s:AutoCmd('Interrupt')
					return 0
				el
					return -2
				en
			el
				return -3
			en
		el
			if s:async_job > 0
				call s:AutoCmd('Interrupt')
				silent! call jobstop(s:async_job)
			en
		en
	el
		return -4
	en
	return 0
endfunc


" get job status
fun! s:AsyncRun_Job_Status()
	if exists('s:async_job')
		if s:async_nvim == 0
			return job_status(s:async_job)
		el
			return 'run'
		en
	el
		return 'none'
	en
endfunc



"----------------------------------------------------------------------
" Utilities
"----------------------------------------------------------------------

" Replace string
fun! s:StringReplace(text, old, new)
	let l:data = split(a:text, a:old, 1)
	return join(l:data, a:new)
endfunc

" Trim leading and tailing spaces
fun! s:StringStrip(text)
	return substitute(a:text, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunc

" extract options from command
fun! s:ExtractOpt(command)
	let cmd = substitute(a:command, '^\s*\(.\{-}\)\s*$', '\1', '')
	let opts = {}
	while cmd =~# '^-\%(\w\+\)\%([= ]\|$\)'
		let opt = matchstr(cmd, '^-\zs\w\+')
		if cmd =~ '^-\w\+='
			let val = matchstr(cmd, '^-\w\+=\zs\%(\\.\|\S\)*')
		el
			let val = (opt == 'cwd' || opt == 'encoding')? '' : 1
		en
		let opts[opt] = substitute(val, '\\\(\s\)', '\1', 'g')
		let cmd = substitute(cmd, '^-\w\+\%(=\%(\\.\|\S\)*\)\=\s*', '', '')
	endwhile
	let cmd = substitute(cmd, '^\s*\(.\{-}\)\s*$', '\1', '')
	let cmd = substitute(cmd, '^@\s*', '', '')
	let opts.cwd = get(opts, 'cwd', '')
	let opts.mode = get(opts, 'mode', '')
	let opts.save = get(opts, 'save', '')
	let opts.program = get(opts, 'program', '')
	let opts.post = get(opts, 'post', '')
	let opts.text = get(opts, 'text', '')
	let opts.auto = get(opts, 'auto', '')
	let opts.raw = get(opts, 'raw', '')
	let opts.strip = get(opts, 'strip', '')
	let opts.append = get(opts, 'append', '')
	if 0
		echom 'cwd:'. opts.cwd
		echom 'mode:'. opts.mode
		echom 'save:'. opts.save
		echom 'program:'. opts.program
		echom 'command:'. cmd
	en
	return [cmd, opts]
endfunc

" write script to a file and return filename
fun! asyncrun#script_write(command, pause)
	let tmpname = fnamemodify(tempname(), ':h') . '\asyncrun.cmd'
	let command = a:command
	if s:asyncrun_windows != 0
		let lines = ["@echo off\r"]
		let $VIM_COMMAND = a:command
		let $VIM_PAUSE = (a:pause)? 'pause' : ''
		let lines += ["call %VIM_COMMAND% \r"]
		let lines += ["set VIM_EXITCODE=%ERRORLEVEL%\r"]
		let lines += ["call %VIM_PAUSE% \r"]
		let lines += ["exit %VIM_EXITCODE%\r"]
	el
		let shell = (g:asyncrun_shell != '')? g:asyncrun_shell : (&shell)
		let lines = ['#! ' . shell]
		let lines += [command]
		if a:pause != 0
			if executable('bash')
				let pause = 'read -n1 -rsp "press any key to continue ..."'
				let lines += ['bash -c ''' . pause . '''']
			el
				let lines += ['echo "press enter to continue ..."']
				let lines += ['sh -c "read _tmp_"']
			en
		en
		let tmpname = fnamemodify(tempname(), ':h') . '/asyncrun.sh'
	en
	if v:version >= 700
		call writefile(lines, tmpname)
	el
		exe 'redir ! > '.fnameescape(tmpname)
		for line in lines
			silent echo line
		endfor
		redir END
	en
	if s:asyncrun_windows == 0
		if exists('*setfperm')
			silent! call setfperm(tmpname, 'rwxrwxrws')
		en
	en
	return tmpname
endfunc

" write script to a file and return filename
fun! s:ScriptWrite(command, pause)
	return asyncrun#script_write(a:command, a:pause)
endfunc


" full file name
fun! asyncrun#fullname(f)
	let f = a:f
	if f =~ "'."
		try
			redir => m
			silent exe ':marks' f[1]
			redir END
			let f = split(split(m, '\n')[-1])[-1]
			let f = filereadable(f)? f : ''
		catch
			let f = '%'
		endtry
	en
	if f == '%'
		let f = expand('%')
		if &bt == 'terminal' || &bt == 'nofile'
			let f = ''
		en
	elseif f =~ '^\~[\/\\]'
		let f = expand(f)
	en
	let f = fnamemodify(f, ':p')
	if s:asyncrun_windows
		let f = substitute(f, "\\", '/', 'g')
	en
	if f =~ '\/$'
		let f = fnamemodify(f, ':h')
	en
	return f
endfunc

" join two path
fun! s:path_join(home, name)
	let l:size = strlen(a:home)
	if l:size == 0 | return a:name | endif
	let l:last = strpart(a:home, l:size - 1, 1)
	if has("win32") || has("win64") || has("win16") || has('win95')
		let l:first = strpart(a:name, 0, 1)
		if l:first == "/" || l:first == "\\"
			let head = strpart(a:home, 1, 2)
			if index([":\\", ":/"], head) >= 0
				return strpart(a:home, 0, 2) . a:name
			en
			return a:name
		elseif index([":\\", ":/"], strpart(a:name, 1, 2)) >= 0
			return a:name
		en
		if l:last == "/" || l:last == "\\"
			return a:home . a:name
		el
			return a:home . '/' . a:name
		en
	el
		if strpart(a:name, 0, 1) == "/"
			return a:name
		en
		if l:last == "/"
			return a:home . a:name
		el
			return a:home . '/' . a:name
		en
	en
endfunc

" find project root
fun! s:find_root(path, markers, strict)
	fun! s:guess_root(filename, markers)
		let fullname = asyncrun#fullname(a:filename)
		if fullname =~ '^fugitive:/'
			if exists('b:git_dir')
				return fnamemodify(b:git_dir, ':h')
			en
			return '' " skip any fugitive buffers early
		en
		let pivot = fullname
		if !isdirectory(pivot)
			let pivot = fnamemodify(pivot, ':h')
		en
		while 1
			let prev = pivot
			for marker in a:markers
				let newname = s:path_join(pivot, marker)
				if newname =~ '[\*\?\[\]]'
					if glob(newname) != ''
						return pivot
					en
				elseif filereadable(newname)
					return pivot
				elseif isdirectory(newname)
					return pivot
				en
			endfor
			let pivot = fnamemodify(pivot, ':h')
			if pivot == prev
				break
			en
		endwhile
		return ''
	endfunc
	if a:path == '%'
		if exists('b:asyncrun_root') && b:asyncrun_root != ''
			return b:asyncrun_root
		elseif exists('t:asyncrun_root') && t:asyncrun_root != ''
			return t:asyncrun_root
		elseif exists('g:asyncrun_root') && g:asyncrun_root != ''
			return g:asyncrun_root
		en
	en
	let root = s:guess_root(a:path, a:markers)
	if root != ''
		return asyncrun#fullname(root)
	elseif a:strict != 0
		return ''
	en
	" Not found: return parent directory of current file / file itself.
	let fullname = asyncrun#fullname(a:path)
	if isdirectory(fullname)
		return fullname
	en
	return asyncrun#fullname(fnamemodify(fullname, ':h'))
endfunc

" get project root
fun! asyncrun#get_root(path, ...)
	let markers = ['.project', '.git', '.hg', '.svn', '.root']
	if exists('g:asyncrun_rootmarks')
		let markers = g:asyncrun_rootmarks
	en
	if a:0 > 0
		if type(a:1) == type([])
			let markers = a:1
		en
	en
	let strict = (a:0 >= 2)? (a:2) : 0
	let l:hr = s:find_root(a:path, markers, strict)
	if s:asyncrun_windows
		let l:hr = s:StringReplace(l:hr, '/', "\\")
	en
	return l:hr
endfunc

fun! asyncrun#path_join(home, name)
	return s:path_join(a:home, a:name)
endfunc

" change to unix
fun! asyncrun#path_win2unix(winpath, prefix)
	let prefix = a:prefix
	let path = a:winpath
	if path =~ '^\a:[/\\]'
		let drive = tolower(strpart(path, 0, 1))
		let name = strpart(path, 3)
		let p = s:path_join(prefix, drive)
		let p = s:path_join(p, name)
		return tr(p, '\', '/')
	elseif path =~ '^[/\\]'
		let drive = tolower(strpart(getcwd(), 0, 1))
		let name = strpart(path, 1)
		let p = s:path_join(prefix, drive)
		let p = s:path_join(p, name)
		return tr(p, '\', '/')
	el
		return tr(a:winpath, '\', '/')
	en
endfunc

" translate makeprg/grepprg format
fun! asyncrun#translate(program, command)
	let l:program = a:program
	let l:command = a:command
	if l:program =~# '\$\*'
		let l:command = s:StringReplace(l:program, '\$\*', l:command)
	elseif l:command != ''
		let l:command = l:program . ' ' . l:command
	el
		let l:command = l:program
	en
	let l:command = s:StringStrip(l:command)
	let s:async_program_cmd = ''
	silent exec 'AsyncRun -program=<parse> @ '. l:command
	let l:command = s:async_program_cmd
	return l:command
endfunc


"----------------------------------------------------------------------
" init terminal in current window
"----------------------------------------------------------------------
fun! s:terminal_init(opts)
	let command = a:opts.cmd
	let hidden = get(a:opts, 'hidden', 0)
	let shell = (has('nvim') == 0)? 1 : 0
	let pos = get(a:opts, 'pos', 'bottom')
	let pos = (pos == 'background')? 'hide' : pos
	let cwd = get(a:opts, 'cwd', '')
	let cwd = (cwd != '' && isdirectory(cwd))? cwd : ''
	if get(a:opts, 'safe', get(g:, 'asyncrun_term_safe', 0)) != 0
		let command = s:ScriptWrite(command, 0)
		if stridx(command, ' ') >= 0
			let command = s:shellescape(command)
		en
		let shell = 0
	en
	if shell
		if s:asyncrun_windows != 0
			let exe = ($ComSpec == '')? 'cmd.exe' : $ComSpec
			let command = exe . ' /C ' . command
		el
			let args = []
			if g:asyncrun_shell != ''
				let args += split(g:asyncrun_shell)
				let args += split(g:asyncrun_shellflag)
			el
				let args += split(&shell)
				let args += split(&shellcmdflag)
			en
			let args += [command]
			let command = args
		en
	en
	if has('nvim') == 0
		if pos != 'hide'
			let opts = {'curwin':1, 'norestore':1, 'term_finish':'open'}
			let opts.term_kill = 'term'
			let opts.exit_cb = function('s:terminal_exit')
			let close = get(a:opts, 'close', 0)
			if close
				" let opts.term_finish = 'close'
			en
			if has('patch-8.1.0230')
				if cwd != ''
					let opts.cwd = cwd
				en
			en
			try
				let bid = term_start(command, opts)
			catch /^.*/
				call s:ErrorMsg('E37: No write since last change')
				return -1
			endtry
			let jid = (bid > 0)? term_getjob(bid) : -1
			let success = (bid > 0)? 1 : 0
		el
			let opts = {'stoponexit':'term'}
			let opts.exit_cb = function('s:terminal_exit')
			if cwd != ''
				let opts.cwd = cwd
			en
			let jid = job_start(command, opts)
			let bid = -1
			let success = (job_status(jid) != 'fail')? 1 : 0
		en
		let pid = (success)? (job_info(jid)['process']) : -1
	el
		let opts = {}
		let opts.on_exit = function('s:terminal_exit')
		if cwd != ''
			let opts.cwd = cwd
		en
		if pos != 'hide'
			try
				enew
			catch /^.*/
				call s:ErrorMsg('E37: No write since last change')
				return -1
			endtry
			let jid = termopen(command, opts)
			let bid = (&bt == 'terminal')? winbufnr(0) : -1
		el
			let jid = jobstart(command, opts)
			let jid = (jid > 0)? jid : -1
			let bid = -1
		en
		let success = (jid > 0)? 1 : 0
		let pid = (success)? jid : -1
	en
	if success == 0
		call s:ErrorMsg('Process creation failed')
		return -1
	en
	let info = {}
	if pos != 'hide'
		setl  nonumber signcolumn=no norelativenumber
		let b:asyncrun_cmd = a:opts.cmd
		let b:asyncrun_name = get(a:opts, 'name', '')
		if get(a:opts, 'listed', 1) == 0
			setl  nobuflisted
		en
		exec has('nvim')? 'startinsert' : ''
		if has_key(a:opts, 'hidden')
			exec 'setl  bufhidden=' . (hidden? 'hide' : '')
		en
		if exists('*win_getid')
			let info.winid = win_getid()
		en
	en
	let info.name = get(a:opts, 'name', '')
	let info.post = get(a:opts, 'post', '')
	let info.cmd = get(a:opts, 'cmd', '')
	if has_key(a:opts, 'exit')
		let info.exit = a:opts.exit
	en
	let info.pid = pid
	let info.jid = jid
	let info.bid = bid
	let info.close = get(a:opts, 'close', 0)
	let s:async_term[pid] = info
	return pid
endfunc


"----------------------------------------------------------------------
" init terminal in current window
"----------------------------------------------------------------------
fun! s:terminal_open(opts)
	let previous = getcwd()
	if a:opts.cwd != ''
		silent! call s:chdir(a:opts.cwd)
	en
	let hr = s:terminal_init(a:opts)
	if a:opts.cwd != ''
		silent! call s:chdir(previous)
	en
	return hr
endfunc


"----------------------------------------------------------------------
" exit callback
"----------------------------------------------------------------------
fun! s:terminal_exit(...)
	if has('nvim') == 0
		let pid = job_info(a:1)['process']
	el
		let pid = a:1
	en
	let code = a:2
	if !has_key(s:async_term, pid)
		return -1
	en
	let info = s:async_term[pid]
	unlet s:async_term[pid]
	let g:asyncrun_code = code
	let g:asyncrun_name = info.name
	if info.close != 0
		let bid = info.bid
		if bid >= 0
			if getbufvar(bid, '&bt', '') == 'terminal'
				silent! exec "bd! " . bid
			en
		en
	en
	if info.post != ''
		exec info.post
	en
	if has_key(info, 'exit')
		let l:F = function(info.exit)
		call l:F(info.name, code)
		unlet l:F
	en
endfunc


"----------------------------------------------------------------------
" run in a terminal
"----------------------------------------------------------------------
fun! s:start_in_terminal(opts)
	let pos = get(a:opts, 'pos', 'bottom')
	if has('patch-8.1.1') == 0 && has('nvim-0.3') == 0
		call s:ErrorMsg("Terminal is not available in this vim")
		return -1
	en
	let avail = -1
	for ii in range(winnr('$'))
		let wid = ii + 1
		if getwinvar(wid, '&bt') == 'terminal'
			if has('nvim') == 0
				let bid = winbufnr(wid)
				if term_getstatus(bid) == 'finished'
					let avail = wid
					break
				en
			el
				let ch = getwinvar(wid, '&channel')
				let status = (jobwait([ch], 0)[0] == -1)? 1 : 0
				if status == 0
					let avail = wid
					break
				en
			en
		en
	endfor
	let focus = get(a:opts, 'focus', 1)
	if pos ==? 'tab'
		if get(a:opts, 'reuse', 0) == 0
			exec "tab split"
			if pos ==# 'TAB'
				exec "-tabmove"
			en
		el
			let avail = -1
			for i in range(tabpagenr('$'))
				if tabpagewinnr(i + 1, '$') == 1
					let bid = tabpagebuflist(i + 1)[0]
					if getbufvar(bid, '&bt', '') == 'terminal'
						if has('nvim') == 0
							if term_getstatus(bid) == 'finished'
								let avail = i + 1
								break
							en
						el
							let ch = getbufvar(bid, '&channel')
							let status = (jobwait([ch], 0)[0] == -1)? 1 : 0
							if status == 0
								let avail = i + 1
								break
							en
						en
					en
				en
			endfor
			if avail < 0
				exec "tab split"
				if pos ==# 'TAB'
					exec "-tabmove"
				en
			el
				exec 'tabn ' . avail
			en
		en
		let hr = s:terminal_open(a:opts)
		if hr >= 0
			if focus == 0
				exec has('nvim')? 'stopinsert' : ''
				if pos ==# 'TAB'
					exec 'tabnext'
				el
					exec 'tabprevious'
				en
			en
		en
		return 0
	elseif pos == 'cur' || pos == 'curwin' || pos == 'current'
		let hr = s:terminal_open(a:opts)
		return 0
	elseif pos == 'hide' || pos == 'background'
		let hr = s:terminal_open(a:opts)
		return 0
	en
	let uid = win_getid()
	keepalt noautocmd windo call s:save_restore_view(0)
	keepalt noautocmd call win_gotoid(uid)
	let origin = win_getid()
	if avail < 0 || get(a:opts, 'reuse', 1) == 0
		let rows = get(a:opts, 'rows', '')
		let cols = get(a:opts, 'cols', '')
		if pos == 'top'
			exec "leftabove " . rows . "split"
		elseif pos == 'bottom' || pos == 'bot'
			exec "rightbelow " . rows . "split"
		elseif pos == 'left'
			exec "leftabove " . cols . "vs"
		elseif pos == 'right'
			exec "rightbelow " . cols . "vs"
		el
			exec "rightbelow " . rows . "split"
		en
	en
	if avail > 0
		exec "normal! ". avail . "\<c-w>\<c-w>"
	en
	let uid = win_getid()
	keepalt noautocmd call win_gotoid(origin)
	keepalt noautocmd windo call s:save_restore_view(1)
	keepalt noautocmd call win_gotoid(origin)
	noautocmd call win_gotoid(uid)
	let hr = s:terminal_open(a:opts)
	if focus == 0 && hr >= 0
		exec has('nvim')? 'stopinsert' : ''
		call win_gotoid(origin)
	en
	return 0
endfunc


"----------------------------------------------------------------------
" invoke event
"----------------------------------------------------------------------
fun! s:DispatchEvent(name, ...)
	if has_key(g:asyncrun_event, a:name)
		let l:F = g:asyncrun_event[a:name]
		if type(l:F) == type('')
			let test = l:F
			unlet l:F
			let l:F = function(test)
		en
		if a:0 == 0
			call l:F()
		el
			let args = []
			for index in range(a:0)
				let args += ['a:' . (index + 1)]
			endfor
			let text = join(args, ',')
			let cmd = 'call l:F(' . text . ')'
			exec cmd
		en
		unlet l:F
	en
endfunc


"----------------------------------------------------------------------
" run command
"----------------------------------------------------------------------
fun! s:run(opts)
	let l:opts = deepcopy(a:opts)
	let l:command = a:opts.cmd
	let l:retval = ''
	let l:mode = g:asyncrun_mode
	let l:runner = ''
	let l:opts.origin = l:opts.cmd

	if a:opts.mode != ''
		let l:mode = a:opts.mode
	en

	" mode alias
	let l:modemap = {'async':0, 'make':1, 'bang':2, 'python':3, 'os':4,
				\ 'hide':5, 'terminal': 6, 'execute':1, 'term':6, 'system':4}

	let l:modemap['external'] = 4
	let l:modemap['quickfix'] = 0
	let l:modemap['vim'] = 2
	let l:modemap['wait'] = 3

	let l:mode = get(l:modemap, l:mode, l:mode)

	" alias "-mode=raw" to "-mode=async -raw=1"
	if type(l:mode) == type('') && l:mode == 'raw'
		let l:mode = 0
		let l:opts.raw = 1
	elseif type(l:mode) == 0 && l:mode == 6
		let pos = get(l:opts, 'pos', '')
		if pos != ''
			call s:DispatchEvent('runner', pos)
		en
		if has_key(g:asyncrun_runner, pos)
			let l:runner = pos
		elseif pos == 'bang' || pos == 'vim'
			let l:mode = 2
		elseif pos == 'extern' || pos == 'external'
			let l:mode = 4
		elseif pos == 'system' || pos == 'os'
			let l:mode = 4
		elseif pos == 'quickfix'
			let l:mode = 0
			let l:opts.raw = 1
		en
	en

	" process makeprg/grepprg in -program=?
	let l:program = ""

	let s:async_efm = a:opts.errorformat

	if l:opts.program == 'make'
		let l:program = &makeprg
	elseif l:opts.program == 'grep'
		let l:program = &grepprg
		let s:async_efm = &grepformat
	elseif l:opts.program == 'wsl'
		if s:asyncrun_windows != 0
			let root = ($SystemRoot == '')? 'C:/Windows' : $SystemRoot
			let t1 = root . '/system32/wsl.exe'
			let t2 = root . '/sysnative/wsl.exe'
			let tt = executable(t1)? t1 : (executable(t2)? t2 : '')
			if tt == ''
				call s:ErrorMsg("not find wsl in your system")
				return
			en
			let cmd = s:shellescape(substitute(tt, '\\', '\/', 'g'))
			let dist = get(l:opts, 'dist', get(g:, 'asyncrun_dist', ''))
			if dist != ''
				let cmd = cmd . ' -d ' . dist
			en
			let l:command = cmd . ' ' . l:command
		el
			call s:ErrorMsg("only available for Windows")
			return ''
		en
	elseif has_key(g:asyncrun_translator, l:opts.program)
		let name = l:opts.program
		let l:program = g:asyncrun_translator[name]
	elseif l:opts.program != ''
		let name = l:opts.program
		if name != ''
			call s:DispatchEvent('program', name)
		en
		let test = ['cygwin', 'msys', 'mingw32', 'mingw64']
		let test += ['clang64', 'clang32']
		if has_key(g:asyncrun_program, name) != 0
			let l:F = g:asyncrun_program[name]
			if type(l:F) == type('')
				let t = l:F
				unlet l:F
				let l:F = function(t)
			en
			unsilent let l:command = l:F(l:opts)
			unlet l:F
		elseif index(test, name) >= 0
			unsilent let l:command = s:program_msys(l:opts)
		el
			call s:ErrorMsg(name . " not found in g:asyncrun_program")
			return ''
		en
		if l:command == ''
			return ''
		en
		let l:opts.cmd = l:command
	en

	if l:program != ''
		let l:command = asyncrun#translate(l:program, l:command)
	en

	if l:command =~ '^\s*$'
		echohl ErrorMsg
		echom "E471: Command required"
		echohl NONE
		return
	en

	let l:wrapper = get(g:, 'asyncrun_wrapper', '')

	if l:wrapper != ''
		let l:command = l:wrapper . ' ' . l:command
	en

	if l:mode >= 10
		let l:opts.cmd = l:command
		if g:asyncrun_hook != ''
			exec 'call '. g:asyncrun_hook .'(l:opts)'
		en
		return ''
	elseif l:mode == 7
		if s:asyncrun_windows != 0 && s:asyncrun_gui != 0
			let l:mode = 4
		el
			let script = get(g:, 'asyncrun_script', '')
			let l:mode = (script == '')? 2 : 4
		en
	en

	let g:asyncrun_cmd = l:command
	let t = s:StringStrip(l:command)

	if strpart(t, 0, 1) == ':' && g:asyncrun_strict == 0
		exec strpart(t, 1)
		return ''
	elseif l:runner != ''
		let l:F = g:asyncrun_runner[l:runner]
		if type(l:F) == type('')
			let l:t = l:F
			unlet l:F
			let l:F = function(l:t)
		en
		let obj = deepcopy(l:opts)
		let obj.cmd = command
		let obj.src = a:opts.cmd
		call l:F(obj)
		unlet l:F
		return ''
	en

	if exists('g:asyncrun_open')
		let s:asyncrun_open = g:asyncrun_open
		if has_key(a:opts, 'open')
			let s:asyncrun_open = a:opts.open
		en
		if has_key(a:opts, 'silent')
			if a:opts.silent
				let s:asyncrun_open = 0
			en
		en
	en

	if l:mode == 0 && s:asyncrun_support != 0
		let s:async_info.postsave = opts.post
		let s:async_info.autosave = opts.auto
		let s:async_info.text = opts.text
		let s:async_info.raw = opts.raw
		let s:async_info.range = opts.range
		let s:async_info.range_top = opts.range_top
		let s:async_info.range_bot = opts.range_bot
		let s:async_info.range_buf = opts.range_buf
		let s:async_info.strip = opts.strip
		let s:async_info.append = opts.append
		let s:async_info.cwd = getcwd()
		let s:async_info.once = get(opts, 'once', 0)
		let s:async_info.encoding = get(opts, 'encoding', g:asyncrun_encs)
		if s:AsyncRun_Job_Start(l:command) != 0
			call s:AutoCmd('Error')
		en
	elseif l:mode <= 1 && has('quickfix')
		call s:AutoCmd('Pre')
		call s:AutoCmd('Start')
		let l:makesave = &l:makeprg
		let l:script = s:ScriptWrite(l:command, 0)
		if s:asyncrun_windows != 0
			let &l:makeprg = s:shellescape(l:script)
		el
			let &l:makeprg = 'source '. s:shellescape(l:script)
		en
		let l:efm1 = &g:efm
		let l:efm2 = &l:efm
		if g:asyncrun_local != 0
			let &g:efm = s:async_efm
			let &l:efm = s:async_efm
		en
		if has('autocmd')
			call s:AsyncRun_Job_AutoCmd(0, opts.auto)
			exec "noautocmd make!"
			call s:AsyncRun_Job_AutoCmd(1, opts.auto)
		el
			exec "make!"
		en
		if g:asyncrun_local != 0
			if l:efm1 != &g:efm | let &g:efm = l:efm1 | endif
			if l:efm2 != &l:efm | let &l:efm = l:efm2 | endif
		en
		let &l:makeprg = l:makesave
		if s:asyncrun_windows == 0
			try | call delete(l:script) | catch | endtry
		en
		let g:asyncrun_text = opts.text
		if opts.post != ''
			exec opts.post
		en
		call s:AutoCmd('Stop')
	elseif l:mode <= 2
		let autocmd = get(opts, 'autocmd', 0)
		if autocmd != 0
			call s:AutoCmd('Pre')
			call s:AutoCmd('Start')
		en
		exec '!'. escape(l:command, '%#')
		let g:asyncrun_text = opts.text
		if opts.post != ''
			exec opts.post
		en
		if autocmd != 0
			call s:AutoCmd('Stop')
		en
	elseif l:mode == 3
		let autocmd = get(opts, 'autocmd', 0)
		if autocmd != 0
			call s:AutoCmd('Pre')
			call s:AutoCmd('Start')
		en
		if s:asyncrun_windows == 0
			let l:retval = system(l:command)
			let g:asyncrun_shell_error = v:shell_error
		elseif has('nvim')
			let l:retval = system(l:command)
			let g:asyncrun_shell_error = v:shell_error
		elseif has('python3')
			let l:script = s:ScriptWrite(l:command, 0)
			py3 import subprocess, vim
			py3 argv = {'args': vim.eval('l:script'), 'shell': True}
			py3 argv['stdout'] = subprocess.PIPE
			py3 argv['stderr'] = subprocess.STDOUT
			py3 p = subprocess.Popen(**argv)
			py3 text = p.stdout.read()
			py3 p.stdout.close()
			py3 c = p.wait()
			if has('patch-7.4.145')
				let l:retval = py3eval('text')
				let g:asyncrun_shell_error = py3eval('c')
			el
				py3 text = text.replace('\\', '\\\\').replace('"', '\\"')
				py3 text = text.replace('\n', '\\n').replace('\r', '\\r')
				py3 vim.command('let l:retval = "%s"'%text)
				py3 vim.command('let g:asyncrun_shell_error = %d'%c)
			en
		elseif has('python')
			let l:script = s:ScriptWrite(l:command, 0)
			py import subprocess, vim
			py argv = {'args': vim.eval('l:script'), 'shell': True}
			py argv['stdout'] = subprocess.PIPE
			py argv['stderr'] = subprocess.STDOUT
			py p = subprocess.Popen(**argv)
			py text = p.stdout.read()
			py p.stdout.close()
			py c = p.wait()
			if has('patch-7.4.145')
				let l:retval = pyeval('text')
				let g:asyncrun_shell_error = pyeval('c')
			el
				py text = text.replace('\\', '\\\\').replace('"', '\\"')
				py text = text.replace('\n', '\\n').replace('\r', '\\r')
				py vim.command('let l:retval = "%s"'%text)
				py vim.command('let g:asyncrun_shell_error = %d'%c)
			en
		el
			let l:retval = system(l:command)
			let g:asyncrun_shell_error = v:shell_error
		en
		let g:asyncrun_text = opts.text
		if opts.post != ''
			exec opts.post
		en
		if autocmd != 0
			call s:AutoCmd('Stop')
		en
	elseif l:mode <= 5
		let script = get(g:, 'asyncrun_script', '')
		if script != '' && l:mode == 4
			let $VIM_COMMAND = l:command
			let l:command = script . ' ' . l:command
			if s:asyncrun_windows
				let ccc = s:shellescape(s:ScriptWrite(l:command, 0))
				silent exec '!start /b cmd /C '. ccc
			el
				call system(l:command . ' &')
			en
		elseif s:asyncrun_windows
			if l:mode == 4
				let l:ccc = s:shellescape(s:ScriptWrite(l:command, 1))
				silent exec '!start cmd /C '. l:ccc
			el
				let l:ccc = s:shellescape(s:ScriptWrite(l:command, 0))
				silent exec '!start /b cmd /C '. l:ccc
			en
			redraw
		el
			if l:mode == 4
				exec '!' . escape(l:command, '%#')
			el
				call system(l:command . ' &')
			en
		en
		let g:asyncrun_text = opts.text
		if opts.post != ''
			exec opts.post
		en
	elseif l:mode == 6
		let opts.cmd = l:command
		call s:start_in_terminal(opts)
	en

	return l:retval
endfunc


"----------------------------------------------------------------------
" asyncrun - run
"----------------------------------------------------------------------
fun! asyncrun#run(bang, opts, args, ...)
	let l:macros = {}
	let l:macros['VIM_FILEPATH'] = expand("%:p")
	let l:macros['VIM_FILENAME'] = expand("%:t")
	let l:macros['VIM_FILEDIR'] = expand("%:p:h")
	let l:macros['VIM_FILENOEXT'] = expand("%:t:r")
	let l:macros['VIM_PATHNOEXT'] = expand("%:p:r")
	let l:macros['VIM_FILEEXT'] = "." . expand("%:e")
	let l:macros['VIM_FILETYPE'] = (&filetype)
	let l:macros['VIM_CWD'] = getcwd()
	let l:macros['VIM_RELDIR'] = expand("%:h:.")
	let l:macros['VIM_RELNAME'] = expand("%:p:.")
	let l:macros['VIM_CWORD'] = expand("<cword>")
	let l:macros['VIM_CFILE'] = expand("<cfile>")
	let l:macros['VIM_CLINE'] = line('.')
	let l:macros['VIM_VERSION'] = ''.v:version
	let l:macros['VIM_SVRNAME'] = v:servername
	let l:macros['VIM_COLUMNS'] = ''.&columns
	let l:macros['VIM_LINES'] = ''.&lines
	let l:macros['VIM_GUI'] = has('gui_running')? 1 : 0
	let l:macros['VIM_ROOT'] = asyncrun#get_root('%')
	let l:macros['VIM_HOME'] = expand(split(&rtp, ',')[0])
	let l:macros['VIM_PRONAME'] = fnamemodify(l:macros['VIM_ROOT'], ':t')
	let l:macros['VIM_DIRNAME'] = fnamemodify(l:macros['VIM_CWD'], ':t')
	let l:macros['VIM_PWD'] = l:macros['VIM_CWD']
	let l:macros['<cwd>'] = l:macros['VIM_CWD']
	let l:macros['<root>'] = l:macros['VIM_ROOT']
	let l:macros['<pwd>'] = l:macros['VIM_PWD']
	let l:retval = ''

	" handle: empty extension
	if expand("%:e") == ''
		let l:macros['VIM_FILEEXT'] = ''
	en

	" call init scripts
	call s:DispatchEvent('init')
	call s:AutoCmd('Init')

	" extract options
	let [l:command, l:opts] = s:ExtractOpt(s:StringStrip(a:args))

	" check lazy load
	if get(l:opts, 'mode', '') == 'load'
		return ''
	en

	" combine options
	if type(a:opts) == type({})
		for [l:key, l:val] in items(a:opts)
			let l:opts[l:key] = l:val
		endfor
	en

	" parse makeprg/grepprg and return
	if l:opts.program == '<parse>'
		let s:async_program_cmd = l:command
		return s:async_program_cmd
	elseif l:opts.program == '<display>'
		let l:opts.cmd = l:command
		echo l:opts
		return ''
	en

	" update marcros
	let l:macros['VIM_RUNNAME'] = get(l:opts, 'name', '')

	" update info (current running command text)
	let g:asyncrun_info = a:args

	" setup range
	let l:opts.range = 0
	let l:opts.range_top = 0
	let l:opts.range_bot = 0
	let l:opts.range_buf = 0

	if a:0 >= 3
		if a:1 > 0 && a:2 <= a:3
			let l:opts.range = 2
			let l:opts.range_top = a:2
			let l:opts.range_bot = a:3
			let l:opts.range_buf = bufnr('%')
		en
	en

	" check cwd
	if l:opts.cwd != ''
		for [l:key, l:val] in items(l:macros)
			let l:replace = (l:key[0] != '<')? '$('.l:key.')' : l:key
			let l:opts.cwd = s:StringReplace(l:opts.cwd, l:replace, l:val)
		endfor
		let l:opts.savecwd = getcwd()
		silent! call s:chdir(l:opts.cwd)
		let l:macros['VIM_CWD'] = getcwd()
		let l:macros['VIM_RELDIR'] = expand("%:h:.")
		let l:macros['VIM_RELNAME'] = expand("%:p:.")
		let l:macros['VIM_CFILE'] = expand("<cfile>")
		let l:macros['VIM_DIRNAME'] = fnamemodify(l:macros['VIM_CWD'], ':t')
		let l:macros['<cwd>'] = l:macros['VIM_CWD']
	en

	" windows can use $(WSL_XXX)
	if s:asyncrun_windows != 0
		let wslnames = ['FILEPATH', 'FILENAME', 'FILEDIR', 'FILENOEXT']
		let wslnames += ['PATHNOEXT', 'FILEEXT', 'FILETYPE', 'RELDIR']
		let wslnames += ['RELNAME', 'CFILE', 'ROOT', 'HOME', 'CWD']
		for name in wslnames
			let src = l:macros['VIM_' . name]
			let l:macros['WSL_' . name] = asyncrun#path_win2unix(src, '/mnt')
		endfor
	en

	" replace macros and setup environment variables
	for [l:key, l:val] in items(l:macros)
		let l:replace = (l:key[0] != '<')? '$('.l:key.')' : l:key
		if l:key[0] != '<'
			if strpart(l:key, 0, 4) != 'WSL_'
				exec 'let $'.l:key.' = l:val'
			en
		en
		let l:command = s:StringReplace(l:command, l:replace, l:val)
		let l:opts.text = s:StringReplace(l:opts.text, l:replace, l:val)
	endfor

	" config
	let l:opts.cmd = l:command
	let l:opts.macros = l:macros
	let l:opts.mode = get(l:opts, 'mode', g:asyncrun_mode)
	let l:opts.errorformat = get(l:opts, 'errorformat', &errorformat)
	let s:async_scroll = (a:bang == '!')? 0 : 1

	" check scroll
	if has_key(l:opts, 'scroll')
		let s:async_scroll = (l:opts.scroll == '0')? 0 : 1
	en

	" check if need to save
	let l:save = get(l:opts, 'save', '')

	if l:save == ''
		let l:save = ''. g:asyncrun_save
	en

	if l:save == '1'
		silent! update
	elseif l:save
		silent! wall
	en

	" run command
	let l:retval = s:run(l:opts)

	" restore cwd
	if l:opts.cwd != ''
		silent! call s:chdir(l:opts.savecwd)
	en

	return l:retval
endfunc


"----------------------------------------------------------------------
" asyncrun - stop
"----------------------------------------------------------------------
fun! asyncrun#stop(bang)
	if a:bang == ''
		return s:AsyncRun_Job_Stop('term')
	el
		return s:AsyncRun_Job_Stop('kill')
	en
endfunc



"----------------------------------------------------------------------
" asyncrun - status
"----------------------------------------------------------------------
fun! asyncrun#status()
	return s:AsyncRun_Job_Status()
endfunc



"----------------------------------------------------------------------
" asyncrun - version
"----------------------------------------------------------------------
fun! asyncrun#version()
	return '2.9.11'
endfunc


"----------------------------------------------------------------------
" Commands
"----------------------------------------------------------------------
com!  -bang -nargs=+ -range=0 -complete=file AsyncRun
		\ call asyncrun#run('<bang>', '', <q-args>, <count>, <line1>, <line2>)

com!  -bar -bang -nargs=0 AsyncStop call asyncrun#stop('<bang>')


"----------------------------------------------------------------------
" run command in msys
"----------------------------------------------------------------------
fun! s:program_msys(opts)
	let tmpname = fnamemodify(tempname(), ':h') . '\asyncruz.cmd'
	let script = fnamemodify(tempname(), ':h') . '\asyncrun.sh'
	let program = a:opts.program
	if s:asyncrun_windows == 0
		call s:ErrorMsg('program ' . program . ' is only for windows')
		return ''
	en
	let check = ['msys', 'mingw32', 'mingw64', 'clang32', 'clang64']
	let lines = ["@echo off\r"]
	let lines += ["set CHERE_INVOKING=enabled_from_arguments\r"]
	if program == 'cygwin'
		let home = get(g:, 'asyncrun_cygwin', '')
		if home == ''
			call s:ErrorMsg('g:asyncrun_cygwin needs to set to cygwin root')
			return ''
		en
		if !isdirectory(home)
			call s:Errormsg('path not find in g:asyncrun_cygwin')
			return ''
		en
		let bash = s:path_join(home, 'bin/bash.exe')
		if !executable(bash)
			call s:ErrorMsg('invalid path in g:asyncrun_cygwin')
			return ''
		en
		let mount = '/cygdrive'
		let prefix = 'CYGWIN_'
	elseif index(check, program) >= 0
		let home = get(g:, 'asyncrun_msys', '')
		if home == ''
			call s:ErrorMsg('g:asyncrun_msys needs to set to msys root')
			return ''
		en
		if !isdirectory(home)
			call s:ErrorMsg('path not find in g:asyncrun_msys')
			return ''
		en
		let bash = s:path_join(home, 'usr/bin/bash.exe')
		if !executable(bash)
			call s:ErrorMsg('invalid path in g:asyncrun_msys')
			return ''
		en
		let lines += ["set MSYSTEM=" . toupper(program) . "\r"]
		let mount = '/'
		let prefix = 'MSYS_'
	en
	let bash = s:StringReplace(bash, '/', "\\")
	let path = asyncrun#path_win2unix(fnamemodify(script, ':p'), mount)
	let flag = ' --login ' . (get(a:opts, 'inter', '')? '-i' : '')
	let text = s:shellescape(bash) . flag . ' "' . path . '"'
	let lines += ['call ' . text . "\r"]
	call writefile(lines, tmpname)
	let command = a:opts.cmd
	let names = ['FILEPATH', 'FILENAME', 'FILEDIR', 'FILENOEXT']
	let names += ['PATHNOEXT', 'FILEEXT', 'FILETYPE', 'RELDIR']
	let names += ['RELNAME', 'CFILE', 'ROOT', 'HOME', 'CWD']
	let lines = ['#! /bin/sh']
	for name in names
		let src = a:opts.macros['VIM_' . name]
		let dst = asyncrun#path_win2unix(src, mount)
		let target = '$(' . prefix . name . ')'
		let command = s:StringReplace(command, target, dst)
		let lines += ['export '. prefix . name . "='" . dst . "'"]
	endfor
	let lines += ['unset VIM']
	let lines += ['unset VIMRUNTIME']
	let cwd = asyncrun#path_win2unix(getcwd(), mount)
	let lines += ["cd '" . cwd . "'"]
	let lines += [command]
	call writefile(lines, script)
	return tmpname
endfunc


"----------------------------------------------------------------------
" Fast command to toggle quickfix
"----------------------------------------------------------------------
fun! asyncrun#quickfix_toggle(size, ...)
	let l:mode = (a:0 == 0)? 2 : (a:1)
	fun! s:WindowCheck(mode)
		if &buftype == 'quickfix'
			let s:quickfix_open = 1
			return
		en
		if a:mode == 0
			let w:quickfix_save = winsaveview()
		el
			if exists('w:quickfix_save')
				call winrestview(w:quickfix_save)
				unlet w:quickfix_save
			en
		en
	endfunc
	let s:quickfix_open = 0
	let l:winnr = winnr()
	keepalt noautocmd windo call s:WindowCheck(0)
	keepalt noautocmd silent! exec ''.l:winnr.'wincmd w'
	if l:mode == 0
		if s:quickfix_open != 0
			silent! cclose
		en
	elseif l:mode == 1
		if s:quickfix_open == 0
			keepalt exec 'botright copen '. ((a:size > 0)? a:size : ' ')
			keepalt wincmd k
		en
	elseif l:mode == 2
		if s:quickfix_open == 0
			keepalt exec 'botright copen '. ((a:size > 0)? a:size : ' ')
			keepalt wincmd k
		el
			silent! cclose
		en
	en
	keepalt noautocmd windo call s:WindowCheck(1)
	keepalt noautocmd silent! exec ''.l:winnr.'wincmd w'
endfunc



"----------------------------------------------------------------------
" auto open quickfix window
"----------------------------------------------------------------------
if has("autocmd")
	fun! s:check_quickfix()
		let height = get(g:, "asyncrun_open", 0)
		if exists('s:asyncrun_open')
			let height = s:asyncrun_open
		en
		" echo 'height: '.height . ' ' .s:asyncrun_open
		if height > 0
			call asyncrun#quickfix_toggle(height, 1)
		en
	endfunc
	aug  asyncrun_augroup
		au!
		au User AsyncRunStart call s:check_quickfix()
	aug  END
en


" vim: set ts=4 sw=4 tw=78 noet :


