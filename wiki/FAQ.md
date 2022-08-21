### Can `asyncrun.vim` trigger an autocommand `QuickFixCmdPost` to get some plugin
(like [errormaker](https://github.com/vim-scripts/errormarker.vim)) processing the content in quickfix ? 
either `g:asyncrun_exit` or `-post` or `g:asyncrun_auto` in your case
without modifing any code in asyncrun.vim.

setup global callback on job finished: 
```VimL
    let g:asyncrun_exit = "silent doautocmd QuickFixCmdPost make"
```

setup local callback on each command: 
```VimL
    :AsyncRun -post=silent\ doautocmd\ QuickFixCmdPost\ make @ make
```

There is a new option in the latest asyncrun (1.3.5) to enable asyncrun trigger QuickFixCmdPre/QuickFixCmdPost 
```VimL
    :let g:asyncrun_auto = "make"
```

After that, asyncrun can cooperate with [errormaker](https://github.com/vim-scripts/errormarker.vim) now.

### Macro '%' is expanded incorrectly on windows if the filename contains spaces ?

    The '%' is expanded and escaped by vim itself on the command line, and if the buffer is named `'hello world'`, `%` will be escaped as `'hello\ world'` by vim. The backslash here is the escaping character, and is okay on all the unix systems, but unfortunately, on windows `cmd.exe` assumes it as a path seperator.

    Here is another accurate form on both windows and unix:

    ```VimL
    :AsyncRun gcc "$(VIM_FILEPATH)" -o "$(VIM_FILEDIR)/$(VIM_FILENAME)"
    ```

    Macros wrapped by `$(...)` are expanded by asyncrun with a string replacing.

    (EDIT: there is since has("patch-7.4.191") the filename modifier :S, so :make %:S will work)

### Since when we have the $(...) macros, why there are still some '%...' macros ?

    Any string starting with a '%', '<' or '#' in vim's command line will be expanded and escaped by vim (see: ":help filename-modifiers"). Only "$(...)" are handled by asyncrun.

    `$(VIM_FILEPATH)` is more accurate than `%:p` on both windows and unix when there are spaces in the filename. 

    But most of time, there is no space in a filename and a lot of people don't use windows in their everyday work.

    In this circumstance, you can use "%..." for short.

### Output in quickfix is not matched by the local value of `errorformat` but the global value of it ?

    Because asyncrun uses caddexpr to populate the quickfix list.
    And caddexpr only works with global value of the errorformat.
    There is an option named `g:asyncrun_local` which can be set to non-zero to get asyncrun to
    temporarily modify `&g:errorformat` to `&l:errorformat`.

    Consider to the performance problems (especially for some crazy stl error outputs), `g:asyncrun_local` is set to zero by default. You can turn it on if you are using local errorformat. See [issue 16](https://github.com/skywind3000/asyncrun.vim/issues/16).

### Automate opening quickfix window

Use autocmd `AsyncRunStart` with `asyncrun#quickfix_toggle` in your vimrc: 
```VimL
    augroup MyGroup
        autocmd User AsyncRunStart call asyncrun#quickfix_toggle(8, 1)
    augroup END
```

    or just set `g:asyncrun_open` to 8 in your vimrc if your AsyncRun is newer than 1.3.22.

    see [best practice of quickfix](https://github.com/skywind3000/asyncrun.vim/wiki/Quickfix-Best-Practice)


### Can't capture command's output in quickfix window ?

Has your `errorformat` been modified by some plugins like vim-go or polyglot ?
These plugins will set `errorformat` to filter out non-error messages in quickfix.

see: 

https://github.com/skywind3000/asyncrun.vim/issues/30

https://github.com/skywind3000/asyncrun.vim/issues/58

You can use: `:AsyncRun -raw command` to avoid output matching errorformat when running your program or adjust the errorformat yourself.

### Can't see the realtime output when running a python script

By default, python will buffer everything written to stdout when running as a background process, you can see nothing until program exit or `sys.stdout.flush()` has been called. 

An alternative way is to set the environment variable `PYTHONUNBUFFERED` to disable python's stdout buffering when running in background. So, if you want to see the python's realtime output without calling `flush()`, you may have `let $PYTHONUNBUFFERED=1` in your `.vimrc`.

### Can't see the realtime output when running a C/C++ program

Same problem like previous one. But there is no environment variable for C/C++ program, you can use this at beginning of your program:

```cpp
setbuf(stdout, NULL);
```

to disable buffering, or call `fflush(stdout)` manually after every `printf`, see [stdout-buffering](https://eklitzke.org/stdout-buffering).

