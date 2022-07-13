**Important**: this is an experimental trick by @kiryph:


Following diff to `$VIMRUNTIME/autoload/netrw.vim` (version 156) saves asynchronously with `AsyncRun` when you put into your vimrc `let g:netrw_write_AsyncRun = 1`:
```diff
❯ git diff netrw-156.vim netrw.vim
diff --git a/netrw-156.vim b/netrw.vim
index 76485c2..183fc96 100644
--- a/netrw-156.vim
+++ b/netrw.vim
@@ -510,6 +510,7 @@ call s:NetrwInit("g:NetrwTopLvlMenu","Netrw.")
 call s:NetrwInit("g:netrw_win95ftp",1)
 call s:NetrwInit("g:netrw_winsize",50)
 call s:NetrwInit("g:netrw_wiw",1)
+call s:NetrwInit("g:netrw_write_AsyncRun",0)
 if g:netrw_winsize > 100|let g:netrw_winsize= 100|endif
 " ---------------------------------------------------------------------
 " Default values for netrw's script variables: {{{2
@@ -2377,6 +2378,14 @@ fun! netrw#NetWrite(...) range
 "    call Decho("(netrw) Processing your write request...",'~'.expand("<slnum>"))
    endif
+   " NetWrite: Perform AsyncRun Write {{{3
+   " ============================
+   if exists("g:netrw_write_AsyncRun") && g:netrw_write_AsyncRun == 1
+       let bang_cmd = 'AsyncRun -post=call\ delete('.s:ShellEscape(tmpfile,1).')\ |\ echo\ "(netrw)\ Your\ write\ request\ has\ finished." '
+    else
+        let bang_cmd ="!"
+   endif
+
    ".........................................
    " NetWrite: (rcp) NetWrite Method #1 {{{3
    if  b:netrw_method == 1
@@ -2515,7 +2524,7 @@ fun! netrw#NetWrite(...) range
     else
      let useport= ""
     endif
-    call s:NetrwExe(s:netrw_silentxfer."!".g:netrw_scp_cmd.useport." ".s:ShellEscape(tmpfile,1)." ".s:ShellEscape(g:netrw_machine.":".b:netrw_fname,1))
+    call s:NetrwExe(s:netrw_silentxfer.bang_cmd.g:netrw_scp_cmd.useport." ".s:ShellEscape(tmpfile,1)." ".s:ShellEscape(g:netrw_machine.":".b:netrw_fname,1))
     let b:netrw_lastfile = choice

    ".........................................
@@ -2612,9 +2621,11 @@ fun! netrw#NetWrite(...) range

   " NetWrite: Cleanup: {{{3
 "  call Decho("cleanup",'~'.expand("<slnum>"))
-  if s:FileReadable(tmpfile)
-"   call Decho("tmpfile<".tmpfile."> readable, will now delete it",'~'.expand("<slnum>"))
-   call s:NetrwDelete(tmpfile)
+  if !exists("g:netrw_write_AsyncRun") || g:netrw_write_AsyncRun == 0
+    if s:FileReadable(tmpfile)
+"     call Decho("tmpfile<".tmpfile."> readable, will now delete it",'~'.expand("<slnum>"))
+      call s:NetrwDelete(tmpfile)
+    endif
   endif
   call s:NetrwOptionRestore("w:")
```

It was discussed [here](https://github.com/skywind3000/asyncrun.vim/issues/13)

read before using and take your own risk.


