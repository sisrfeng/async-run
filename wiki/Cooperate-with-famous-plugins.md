# fugitive

simply add a few lines in your .vimrc to get cooperate with [vim-fugitive](https://github.com/tpope/vim-fugitive):

```VimL
command! -bang -nargs=* -complete=file Make AsyncRun -program=make @ <args>
```

The '@' sign is a separator to indicate following string is the parameters of 'make'. 

After fugitive commit: [17db9ca](https://github.com/tpope/vim-fugitive/commit/d4bcc75ef6449c0e5592513fb1e0a42b017db9ca) , 
You are required to provide your own asynchronous `Gpush` and `Gfetch`:

```VimL
command! -bang -bar -nargs=* Gpush execute 'AsyncRun<bang> -cwd=' .
          \ fnameescape(FugitiveGitDir()) 'git push' <q-args>
command! -bang -bar -nargs=* Gfetch execute 'AsyncRun<bang> -cwd=' .
          \ fnameescape(FugitiveGitDir()) 'git fetch' <q-args>
```

Now `Gpush` and `Gfetch` in vim-fugitive can be started with asyncrun. 

It is unwise to add a ':Make' command directly in asyncrun.vim, which may lead to conflict with other plugins.
After adding these lines, `Gpush` and `Gfetch` in vim-fugitive now can behave like a common asyncrun command:

![](https://skywind3000.github.io/images/p/asyncrun/cooperate_with_fugitive.gif)

One more thing, don't forget to disable plugins like vim-dispatch and vim-build-tools-wrapper, which will override your `:Make` definition in your .vimrc to get it work.

# errormarker

[errormarker](https://github.com/mh21/errormarker.vim) is a plugin to highlights and sets error markers for lines with compile errors. It is very handy and has more than 5K downloads in [vim.org](http://www.vim.org/scripts/script.php?script_id=1861).

This plugin relys on an autocmd named `QuickFixCmdPost make` which will be triggered at the end of ':make' command.
And we can trigger that autocmd by setting "g:asyncrun_auto" to "make":

```VimL
let g:asyncrun_auto = "make"
```

This will execute an "doautocmd QuickFixCmdPre make" before executing and "doautocmd QuickFixCmdPost make" after job finished, which will get `errormaker` to read and process the content of quickfix window:

![](https://skywind3000.github.io/images/p/asyncrun/errormarker.jpg)

Now when any AsyncRun command completes, `errormaker` will show the markers and ballons on the errors and warnings of source file. It's pretty cool. 

Here you may ask, "it is a very useful autocmd why doesn't asyncrun trigger it by default ?"

Because many people may set a quickfixpost command to translate encoding in quickfix window like below, which will cause a strange experience with asyncrun:

```VimL
	function QfMakeConv()
	   let qflist = getqflist()
	   for i in qflist
	      let i.text = iconv(i.text, "cp936", "utf-8")
	   endfor
	   call setqflist(qflist)
	endfunction

	au QuickfixCmdPost make call QfMakeConv()
```

This piece of code is from `:h QuickFixCmdPost-example`, many non-english-speaking people use it. `setqflist` will make the cursor of quickfix window rewind to the first line, it's innocuity in the old days, but very ugly with async jobs.

There is also a local autocmd option `-auto=?` if you want to trigger the autocmd just for the current command:

```VimL
:AsyncRun -auto=make gcc %
```

So, both "g:asyncrun_auto" and "-auto=?" can get errormaker to work.


# vim-airline

Add these lines to your .vimrc:

```VimL
let g:asyncrun_status = ''
let g:airline_section_error = airline#section#create_right(['%{g:asyncrun_status}'])
```

Now, we have `vim-airline` displaying the status of AsyncRun, 
you can adjust the position where g:asyncrun_status located by reading the help of airline.


(this page is still been editing in progress ...)