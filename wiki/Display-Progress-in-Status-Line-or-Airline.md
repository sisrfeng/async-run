AsyncRun jobs have three states: `running`, `success` and `failure`. You can edit your `.vimrc` to view these states in the quickfix windows' statusline:

```VimL
let g:asyncrun_status = "stopped"
augroup QuickfixStatus
	au! BufWinEnter quickfix setlocal 
		\ statusline=%t\ [%{g:asyncrun_status}]\ %{exists('w:quickfix_title')?\ '\ '.w:quickfix_title\ :\ ''}\ %=%-15(%l,%c%V%)\ %P
augroup END
```

Global variable `g:asyncrun_status` indicates the these three states:

- running: set when a async job is start
- success: set when exit normally which exit code is 0
- failure: set when exit abnormally which exit code is not 0

You can use `vim-airline` to indicate command status too: 

Add these lines to your .vimrc:

```VimL
let g:asyncrun_status = "stopped" 
let g:airline_section_error = airline#section#create_right(['%{g:asyncrun_status}'])
```

Now, we have `vim-airline` cooperating with AsyncRun, 
you can adjust the position where g:asyncrun_status located by reading the help of airline.


