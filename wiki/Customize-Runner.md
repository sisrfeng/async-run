User-defined runners provide you the possibility to run commands in any way you want, which could be helpful when you want a command run in a `tmux` split, a new `gnome-terminal` window, or a [floaterm](https://github.com/voldikss/vim-floaterm) window. 

## Create a New Runner

A runner is a function with one argument `opts` as a dictionary, from which stores the command string, working directory, and other parameters passed with `:AsyncRun` command. All the runners are required to register in `g:asyncrun_runner` so that AsyncRun can recognize them.

```VimL
function! s:my_runner(opts)
    echo "run: " . a:opts.cmd
endfunction

let g:asyncrun_runner = get(g:, 'asyncrun_runner', {})
let g:asyncrun_runner.test = function('s:my_runner')
```

Than use:

```VimL
:AsyncRun -mode=term -pos=test ls -la $(VIM_FILEDIR)
```

When `-mode=term` and `-pos=test` are provided, runner `test` will be called. In this example, runner function `s:my_runner` does nothing but display the command in the bottom of your vim. 


## Get Information

There is a `opts` argument in the runner function, which contains necessary information:

| Field | Need | Description | Example |
|-|-|-|-|
| cmd | (**required**) | Command string (macros have already been expanded here) | ls -la |
| cwd | (optional) | Working directory (will be an empty string if not provided) | /home/yourname/github |
| mode | (optional) | Running mode | `async`, `terminal`/`term`, or `vim` |
| pos | (optional) | Runner name or terminal position | `TAB`, `gnome`, `tmux`, ... |
| option | (optional) | Runner option passed by `:AsyncRun -option=xxx ...` | ... |
| close | (optional) | Close terminal after job finished | `-close=1` |
| post | (optional) | A vim script needs to be executed after finished | `-post=echo\ "done"  ls -la` |
| program | (optional) | Command modifier | `-program=grep` |
| focus | (optional) | if set to zero, the runner will not get focused | `-focus=0` |
| encoding | (optional) | Command encoding | `-encoding=gbk` |

If `-cwd=xxx` is provided after `:AsyncRun` command, AsyncRun will temporarily change the 
current working directory to the target position when calling runner function. So, you can
either pick the value in `a:opts.cwd` or use the return value from `getcwd()` .

## Range Mode

When use the `:AsyncRun` command in the range mode, additional information can be use:

| Field | Description | Example |
|-|-|-|
| range | > 0 for range mode enabled | 0 |
| range_top | first line of the range, where range starts | 100 |
| range_bot | last line of the range, where range ends | 105 |
| range_buf | buffer id of the document | 1 |

Range support is not compulsory for runners, but it would be nice to provide this feature.

## Real Example

It is very easy to make the command run in a tmux pane with [vimux](https://github.com/benmills/vimux):

```VimL
function! s:run_tmux(opts)
    " asyncrun has temporarily changed working directory for you
    " getcwd() in the runner function is the target directory defined in `-cwd=xxx`  
    let cwd = getcwd()   
    call VimuxRunCommand('cd ' . shellescape(cwd) . '; ' . a:opts.cmd)
endfunction

let g:asyncrun_runner = get(g:, 'asyncrun_runner', {})
let g:asyncrun_runner.tmux = function('s:run_tmux')
```

And you are able to use:

```VimL
:AsyncRun -mode=term -pos=tmux ls -la
```

screenshot:

![](https://github.com/skywind3000/images/raw/master/p/asyncrun_extra/p_tmux.gif)

You can specify pane position (vertical or horizontal) and size, just check vimux's doc.

## Separated Script

Another way to create a runner is to create a separated `.vim` file in the folder:

    autoload/asyncrun/runner/

In one of your `runtimepath`, it will be automatically loaded in need. The script is required to provide a `run` function with the full name:

    asyncrun#runner#{name}#run(opts)

For example, see [gnome.vim](https://github.com/skywind3000/asyncrun.vim/blob/master/autoload/asyncrun/runner/gnome.vim) in the `autoload/asyncrun/runner` folder:

```VimL
function! asyncrun#runner#gnome#run(opts)
    if !executable('gnome-terminal')
        return asyncrun#utils#errmsg('gnome-terminal executable not find !')
    endif
    let cmds = []
    let cmds += ['cd ' . shellescape(getcwd()) ]
    let cmds += [a:opts.cmd]
    let cmds += ['echo ""']
    let cmds += ['read -n1 -rsp "press any key to continue ..."']
    let text = shellescape(join(cmds, ";"))
    let command = 'gnome-terminal -- bash -c ' . text
    call system(command . ' &')
endfunction
```

Try it with:

```VimL
:AsyncRun -mode=term -pos=gnome  ls -la
```

Screenshot:

![](https://github.com/skywind3000/images/raw/master/p/asyncrun_extra/p_gnome_gvim.gif)

## More Examples

In the [runner](https://github.com/skywind3000/asyncrun.vim/tree/master/autoload/asyncrun/runner) folder, some pre-included runner script can be found:

| Runner | Description | Requirement | Link |
|-|-|-|-|
| `gnome` | run in a new gnome terminal | GNOME | [gnome.vim](autoload/asyncrun/runner/gnome.vim) |
| `gnome_tab` | run in a new gnome terminal tab | GNOME | [gnome_tab.vim](autoload/asyncrun/runner/gnome_tab.vim) |
| `xterm` | run in a xterm window | xterm | [xterm.vim](autoload/asyncrun/runner/xterm.vim) |
| `tmux` | run in a separated tmux pane | [Vimux](https://github.com/preservim/vimux) | [tmux.vim](autoload/asyncrun/runner/tmux.vim) |
| `floaterm` | run in a new floaterm window | [floaterm](https://github.com/voldikss/vim-floaterm) | [floaterm.vim](autoload/asyncrun/runner/floaterm.vim) |
| `floaterm_reuse` | run in a reusable floaterm window | [floaterm](https://github.com/voldikss/vim-floaterm) | [floaterm_reuse.vim](autoload/asyncrun/runner/floaterm.vim) |
| `quickui` | run in a quickui window | [vim-quickui](https://github.com/skywind3000/vim-quickui) | [quickui.vim](autoload/asyncrun/runner/quickui.vim) |
| `toggleterm` | run in a toggleterm window | [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) | [toggleterm.vim](autoload/asyncrun/runner/toggleterm.vim) |
| `xfce` | run in a new xfce terminal | xfce4-terminal | [xfce.vim](https://github.com/skywind3000/asyncrun.vim/blob/master/autoload/asyncrun/runner/xfce.vim) |
| `konsole` | run in a new konsole terminal | KDE | [konsole.vim](https://github.com/skywind3000/asyncrun.vim/blob/master/autoload/asyncrun/runner/konsole.vim) |
| `macos` | run in a macOS system terminal | macOS | [macos.vim](https://github.com/skywind3000/asyncrun.vim/blob/master/autoload/asyncrun/runner/macos.vim) |
| `iterm` | run in a new iTerm2 tab | macOS + iTerm2 | [iterm.vim](https://github.com/skywind3000/asyncrun.vim/blob/master/autoload/asyncrun/runner/iterm.vim) |

They can be a good reference if you want to create a new runner.