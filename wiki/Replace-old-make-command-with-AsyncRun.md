You can replace ':make ...' command to:

```VimL
:AsyncRun -program=make @ ...
```

This option will allow asyncrun reading the content of `&makeprg` and composite it with following command into a new one. And old ':make' command can be replaced with this option now:

```VimL
:AsyncRun -program=make @ CFLAGS=-O2
```

The following '@' sign is a separator to indicate following string is the parameters of 'make'. The code above behaves exactly the same thing as ':make CFLAGS=-O2' but it will run in background now.

```VimL
command! -bang -nargs=* -complete=file Make AsyncRun -program=make @ <args>
```

If you add the line above to your .vimrc, you can have ':Make' to replace ':make' easily.


