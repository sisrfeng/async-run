## Open quickfix window when text adds to it

Add these few lines to your `.vimrc`:

```VimL
augroup vimrc
    autocmd QuickFixCmdPost * botright copen 8
augroup END
```

And the quickfix window will open when something adds to it.


## Toggle Quickfix window in right way

AsyncRun uses quickfix window to show job outputs, in order to see the outputs in realtime, you need open quickfix window at first by using `:copen` (see :help copen).

A better way is to use `:botright copen` when you have multiple vertical splitted windows.

You can leave quickfix window always open or you can make a function to toggle it when you need it.

Some times when you are opening the quickfix window, you just want to read the content in it. But `:copen` will move current window to the quickfix window, so you need save current window id before `:copen` and move to previous window after `:copen` finished. 

Spliting a new window in vim will get previous window scrolled, which is annoying when you  toggle quickfix window frequently. You can use vim builtin `winsaveview()` / `winrestview()` to prevent previous window scroll before and after `:copen`.

So there are some vimscript to write, if you want to use quickfix efficiently. Fortunately, there is an `asyncrun#quickfix_toggle(height)` function for you to toggle quickfix window in a convenience way.

Use F9 to toggle quickfix window rapidly:

```VimL
:noremap <F9> :call asyncrun#quickfix_toggle(8)<cr>
```

This function will:

* Open a new quickfix window if it hasn't been open in the current tab page.
* Close a quickfix window if it has already been open in the current tab page.
* Jump back to previous window when open/close the quickfix window
* Avoid automatic scroll in previous window when open a new quickfix window

Now you can have your F9 to toggle quickfix window open or close rapidly.

more usage:

open quickfix window:

```VimL
:call asyncrun#quickfix_toggle(8, 1)
```

close quickfix window

```VimL
:call asyncrun#quickfix_toggle(8, 0)
```

automate opening quickfix window when text adds to it  (will be triggered by other quickfix commands too)

```VimL
augroup vimrc
    autocmd QuickFixCmdPost * call asyncrun#quickfix_toggle(8, 1)
augroup END
```

automate opening quickfix window when AsyncRun starts (won't be triggered by other quickfix commands)

```VimL
augroup vimrc
    autocmd User AsyncRunStart call asyncrun#quickfix_toggle(8, 1)
augroup END
```

