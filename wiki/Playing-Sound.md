AsyncRun will ring the bell to notify you job finished if you set `g:asyncrun_bell` to non-zero.
or, we can use `g:asyncrun_exit` with `afplay` to play a wav file:

```VimL
let g:asyncrun_exit = "silent call system('afplay ~/.vim/notify.wav &')"
```

It is useful while you are editing, you have your eyes looking at the source code without worry about the progress of background building jobs. You don't need repeatly move your eyes from souce code area to quickfix window and from quickfix window back to source code area.

Using a voice notification may help you focus on the source code. On windows you need `:!start` to invoke an external command line tool asynchronous, see `:help !start`:

```VimL
let g:asyncrun_exit = 'silent !start playwav.exe "C:/Windows/Media/Windows Error.wav" 200'
```

`playwav.exe` is a command line utility to play .wav files in windows which can be downloaded  from [here](https://github.com/skywind3000/support/blob/master/tools/playwav.exe). 

Choosing a sweet-sounding .wav file is important which will please you in your subconscious. It will encourage you to continue debug-compile-debug-compile even when you are exhausted from finding bugs.

You can be more productive when you are using voice notifications. The more you use, the more you get happy, nothing can attract or stop you from your crazy edit-debug-edit-debug cycle.

