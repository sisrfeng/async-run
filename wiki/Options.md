# Option Summary

- [g:asyncrun_exit](#gasyncrun_exit) - script will be executed after finished
- [g:asyncrun_mode](#gasyncrun_mode) - 0:async(require vim 7.4.1829) 1:sync 2:shell
- [g:asyncrun_bell](#gasyncrun_bell) - non-zero to ring a bell after finished
- [g:asyncrun_open](#gasyncrun_open) - above zero to open quickfix window at given height after command starts
- [g:asyncrun_wrapper](#gasyncrun_wrapper) - enable to setup a command prefix
- [g:asyncrun_rootmarks](#gasyncrun_rootmarks) - root markers which is used for locating project root
- [g:asyncrun_encs](#gasyncrun_encs) - set shell encoding if it's different from &encoding
- [g:asyncrun_trim](#gasyncrun_trim) - non-zero to trim the empty lines in the quickfix window.
- [g:asyncrun_auto](#gasyncrun_auto) - event name to trigger QuickFixCmdPre/QuickFixCmdPost
- [g:asyncrun_save](#gasyncrun_save) - non-zero to save current(1) or all(2) modified buffer(s) before executing
- [g:asyncrun_timer](#gasyncrun_timer) - how many messages should be inserted into quickfix every 100ms interval
- [g:asyncrun_local](#gasyncrun_local) - enable use local value of `errorformat`
- [g:asyncrun_shell](#gasyncrun_shell) - override the value of vim's `shell` option.
- [g:asyncrun_shellflag](#gasyncrun_shellflag) - override the value of vim's `shellcmdflag` option.

# Option Details

## g:asyncrun_exit

define a script which will be executed after finished.

- type: `string`
- default: `''`

A text of vimscript to run when job finished. eg:

```VimL
let g:asyncrun_exit = "silent call system('afplay ~/.vim/notify.wav &')"
```

You can play a sound on Mac OS X when job finished like this.

## g:asyncrun_mode

This option indicates how to start the job. 

- type: `integer`
- default: `0`

available modes:

- 0: start job asynchronously. 
- 1: start job with `make` system in vim.
- 2: start job by using `!` command.
- 3: start job in the background, no output to quickfix (+python or +python3 is required on windows).
- 4: start job in a new terminal window on windows.

Mode 0 will fall-back to 1 if you are using an old vim before version 8 or built without +job or +timers.

## g:asyncrun_bell

- type: `integer`
- default: `0`

Ring the bell if set it to non-zero.

## g:asyncrun_wrapper

This can be used to setup a command prefix.

- type: `string`
- default: `''`

eg:

Prefix your command with a `nice` command:

```VimL
let g:asyncrun_wrapper = 'nice -n5'
```

If you config it to `nice -n5`, when you use `:AsyncRun make`, the actual command becomes `nice -n5 make`.

Using powershell on windows:

```VimL
let g:asyncrun_wrapper = 'powershell -command'
```

Then, powershell is used to execute your command on windows.

## g:asyncrun_rootmarks

a list of file-name markers which is used for locating project root.

- type: `list`
- default: `['.git', '.svn', '.project', '.root', '.hg']`

The project root is the nearest ancestor directory of the current file which contains one of these directories or files: .svn, .git, .hg, .root or .project. If none of the parent directories contains these root markers, the directory of the current file is used as the project root. 

for examples:

```VimL
:AsyncRun -cwd=<root> make
:AsyncRun make -f $(VIM_ROOT)/Makefile
:AsyncRun -cwd=<root> gcc $(VIM_RELDIR)/$(VIM_FILENAME) -o $(VIM_RELDIR)/$(VIM_FILENOEXT)
```

Macro `<root>` or `$(VIM_ROOT)` will be expanded as project root directory in your command. ee [Project Root](https://github.com/skywind3000/asyncrun.vim/wiki/Project-Root) for details.

## g:asyncrun_open

If it is above zero, the quickfix window will be open automatically at given height after command starts.

- type: `integer`
- default: `0`

eg:

```VimL
let g:asyncrun_open = 6
```

This will open the quickfix window autoomatically when you use `AsyncRun` command.

## g:asyncrun_encs

Job stdout/stderr encoding 

- type: `string`
- default: `''`

If your system's default encoding is different from vim's encoding, you can use this to tell vim what encoding are you using in the shell environment. for example, if Chinese / Japanese / Latin characters can't be display correctly in the quickfix window. see [encoding](https://github.com/skywind3000/asyncrun.vim/wiki/Quickfix-encoding-problem-when-using-Chinese-or-Japanese)

## g:asyncrun_trim

- type: `integer`
- default: `''`

non-zero to trim the empty lines in the quickfix window.

## g:asyncrun_auto

- type: `string`
- default: `''`

event name to trigger QuickFixCmdPre/QuickFixCmdPost, see [FAQ](https://github.com/skywind3000/asyncrun.vim/wiki/FAQ#can-asyncrunvim-trigger-an-autocommand-quickfixcmdpost-to-get-some-plugin-like-errormaker-processing-the-content-in-quickfix-)

## g:asyncrun_save

Set to non-zero to enable saving file(s) before executing the command.

- type: `integer`
- default: `0`

`0` for skip, `1` for saving current buffer and `2` for saving all modified buffers. This option has lower priority than `AsyncRun`'s `-save` option and could be override by it.

## g:asyncrun_timer

- type: `integer`
- default: `50`

how many messages should be inserted into quickfix every 100ms interval

## g:asyncrun_local

- type: `integer`
- default: `0`

Set to 1 to use local `errorformat`, standard output/error of child process will be matched by local `errorformat` if `g:asyncrun_local` is set to 1.

## g:asyncrun_shell

- type: `string`
- default: `''`

Specify shell executable. by default, AsyncRun will use vim's `shell` option to execute your program, it can be overrided without changing your `&shell` value. Set `g:asyncrun_shell` to non-empty string to specify another shell executable.

## g:asyncrun_shellflag

- type: `string`
- default: `''`

Specify shell flags. by default, AsyncRun will use vim's `shellcmdflag` option to config shell flags, it can be overrided without changing your `&shellcmdflag`. Set `g:asyncrun_shellflag` to non-empty string to specify another shell command flag.

for example:

```VimL
let g:asyncrun_shell = '/usr/bin/zsh'
let g:asyncrun_shellflag = '-c'
```

This will use zsh to execute AsyncRun command without modifying vim's `shell` and `shellcmdflag`