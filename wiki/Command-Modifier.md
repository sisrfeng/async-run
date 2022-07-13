## Command Modifier

Command modifiers can be used to change your command before running:

```VimL
let g:asyncrun_program = get(g:, 'asyncrun_program', {})
let g:asyncrun_program.nice = { opts -> 'nice -5' . opts.cmd }
```

When you are using:

```VimL
:AsyncRun -program=nice ls -la
```

The command `ls -la` will be changed into `nice -5 ls -la`.

The `-program=msys`, `-program=wsl` are both implemented as a new command modifier it changes command `ls` into:

```
c:\windows\sysnative\wsl.exe ls
```

And replace any thing like `$(WSL_FILENAME)` and `$(WSL_FILEPATH)` in your command.

