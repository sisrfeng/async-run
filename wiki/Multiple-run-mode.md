There is a `-mode=?` option can allow you specify how to run your command. 

## Available modes

| mode | description |
|--|--|
| async | default behavior, run async command and output to quickfix window |
| bang | same as `!` |
| term | open a reusable built-in terminal window and run your command |
| os | (windows only) open a new cmd.exe window and run your command in it |


## Run command with traditional bang (`!`) command

You may ask, why there is still a `-mode=bang` since you can use `:!command` directly. The reason is asyncrun can setup environment variables and can help you change directory (`-cwd`) before execution:

```VimL
:AsyncRun -mode=bang -cwd=<root> gcc -c "$(VIM_FILENAME)"
```

is different with:

```VimL
:!gcc abc.c -o abc
```

When you are using `AsyncRun -mode=bang`, environment variables (eg `$VIM_FILEDIR`, `$VIM_ROOT` and `$VIM_SVRNAME` ..etc)
 can be setup and you can indicate `-cwd=?` to indicate where to run the command (eg, in current project root).

Sometimes it is helpful than directly using `!`.

## Run command in a reusable built-in terminal window

When you are using `-mode=terminal` or `-mode=term` like:

```VimL
:AsyncRun -mode=term [-pos=?] [-rows=N] [-cols=N] {cmd}
```

AsyncRun will open a new terminal window to run your command:

![](https://github.com/skywind3000/asyncrun.vim/raw/master/images/mode_term.png)

Parameter `-pos` can be one of `tab`, `left`, `right`, `top` and `bottom` to indicate where you want to open the terminal. The window size can be indicated by `-rows` and `-cols`.

If there is an existing terminal window in the current tabpage, AsyncRun will use it without opening a new one. This is more efficient than directly using `:term xxx`, especially when you run a command for multiple times, it will not open a lot of terminal window and force you close them one by one. 

In addition, if the only one existing terminal window is still running the child process, it cannot be reused and a new terminal window will open to prevent overriding an active terminal session.

If your screen is small, a split window is not enough to display your terminal, you can use a tabpage:

```VimL
:AsyncRun -mode=term -pos=term ls -la /usr
```

It will work like:

![](https://github.com/skywind3000/asyncrun.vim/raw/master/images/mode_term_2.png)

The whole tabpage is used for the terminal.

A little difference between tabs and splits is that when you are using `-pos=tab`, asyncrun will always open a new tabpage for the terminal instead of reusing the old ones.


This feature is available for vim 8.1 / neovim 0.3 or later.


## Run command in a new cmd.exe window

If you are using GVim on Windows. The `-mode=os` option can use a new cmd.exe window:

![](https://github.com/skywind3000/asyncrun.vim/raw/master/images/mode_os.png)

Like most windows editors/IDEs, execute program in an external cmd window.
