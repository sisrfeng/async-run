## g:asyncrun_last = 0 (default)

Quickfix window will always scroll, unless current window is a quickfix window and the cursor isn't on the last line.

It is a compromise to both performance and functionality. if you want to read something while background command is still running, you can move to the quickfix window and move the cursor away from the last line.

It will do much less job than mode 1 and get a good performance.

## g:asyncrun_last = 1

Quickfix window will scroll only if the cursor is on the last line, just like output panel in visual studio.

But there are some downsides:

1. unlike `:cbottom` it is not native supported by vim (simulated in vimscript), checking cursor will have a lower performance, but most of time it's acceptable.
2. sometimes cursor blinks in a strange frequency, but not noticeable.

Due to these matters, `g:asyncrun_last` has been set to zero by default, you can turn it on manually.
Hope Bram will support it native some day, and it will be unnecessary to simulated in vimscript any more.

## g:asyncrun_last = 2

Quickfix window will always scroll if you start a command by `:AsyncRun` (not `:AsyncRun!`)

## g:asyncrun_last = 3

- if current window isn't a quickfix window, quickfix window will scroll if `pumvisible()` returns 0.
- if current window is quickfix window, it will scroll only if the cursor is on the last line.

Similar to mode 0, but will do an extra check when you are editing, and disable quickfix scrolling when auto complete popup window is visible.

Sometimes, in some vim version, auto-complete popup window will flicker while populating/scrolling the quickfix window. Maybe we should fire a bug to vim ?