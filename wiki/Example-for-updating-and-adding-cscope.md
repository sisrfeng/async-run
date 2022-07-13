Modify the code below to fit your need:

```VimL
function! g:CscopeDone()
	exec "cs add ".fnameescape(g:asyncrun_text)
endfunc

function! g:CscopeUpdate(workdir, cscopeout)
	let l:cscopeout = fnamemodify(a:cscopeout, ":p")
	let l:cscopeout = fnameescape(l:cscopeout)
	let l:workdir = (a:workdir == '')? '.' : a:workdir
	try | exec "cs kill ".l:cscopeout | catch | endtry
	exec "AsyncRun -post=call\\ g:CscopeDone() ".
				\ "-text=".l:cscopeout." "
				\ "-cwd=".fnameescape(l:workdir)." ".
				\ "cscope -b -R -f ".l:cscopeout
endfunc

noremap <F11> :call g:CscopeUpdate(".", "cscope.out")<cr>

```

And then you can have your F11 to update cscope files in background.

key points:
- use `-post` to define a piece of vimscript which will be executed after job is finished
- use `-text` to pass a text object to `g:asyncrun_text` when job is finished.

