#### Translate markdown to pdf

```VimL
:AsyncRun pandoc --output $(VIM_FILENOEXT).pdf %:p
```

#### Invoke chrome to open current html (non-windows)

```VimL
:AsyncRun chrome %
```

#### Invoke chrome to open current html (windows)

```VimL
:AsyncRun C:\Program\ Files\ (x86)\Google\Chrome\Application\chrome.exe %
```

#### Update tags in background

Updating tags is very slow for large projects. Previously, there is nothing you can do while waiting ctags running. And now with AsyncRun, we can continue editing / navigating our source code while running the ctags:

```VimL
:AsyncRun ctags -R --fields=+S .
:AsyncRun ctags -R -f %:p:h/ctags.out --fields=+iaS %:p:h
:AsyncRun ctags -R -f $(VIM_FILEDIR)/ctags.out --fields=+iaS %:p:h
```

(NOTE: The last two commands will be expanded as the same thing)

