I mainly use vim to write C/C++ codes, and the plugin [AsyncRun](https://github.com/skywind3000/asyncrun.vim) is originated for C/C++ development. I continue updating it for almost 2 years. Here is a quick glance for speeding up your work flow:

## Quick setup

```VimL
Plug 'skywind3000/asyncrun.vim'

" automatically open quickfix window when AsyncRun command is executed
" set the quickfix window 6 lines height.
let g:asyncrun_open = 6

" ring the bell to notify you job finished
let g:asyncrun_bell = 1

" F10 to toggle quickfix window
nnoremap <F10> :call asyncrun#quickfix_toggle(6)<cr>
```

When you input `:AsyncRun echo hello` in the command line:

![](https://github.com/skywind3000/asyncrun.vim/raw/master/doc/simple.png)

You will see the realtime command output in the open quickfix window.

## Compile and run a single file

Let's take a look at single file compilation, just like the build system in sublime, we can setup F9 for this:

```VimL
nnoremap <silent> <F9> :AsyncRun gcc -Wall -O2 "$(VIM_FILEPATH)" -o "$(VIM_FILEDIR)/$(VIM_FILENOEXT)" <cr>
```

The macros in `$(..)` form will be expanded as the real file name or directory, and then we will have F5 for run:

```VimL
nnoremap <silent> <F5> :AsyncRun -raw -cwd=$(VIM_FILEDIR) "$(VIM_FILEDIR)/$(VIM_FILENOEXT)" <cr>
```

The double quotation mark is used to handle path names containing spaces. The option `-cwd=$(VIM_FILEDIR)` means running the file in the file's directory. The absolute path name `$(VIM_FILEDIR)/$(VIM_FILENOEXT)` is used because linux needs a `./` prefix to running executables in current directory, but windows doesn't . Using the absolute path name of the binary file can handle this crossing platform issue.

Another option `-raw` means the output will not be matched by vim's errorformat, and will be displayed in quickfix as what it is. Now you can compile your file with F9, check the compilation errors in quickfix window and press F5 to run the binary.

## Build C/C++ projects

No matter what build tool you are using, `make` or `cmake`, project building means acting to a group of files. It requires locating the project root directory. AsyncRun uses a simple method called `root markers` to identify the project root. The Project Root is identified as the nearest ancestor directory of the current file which contains one of these directories or files:

```text
let g:asyncrun_rootmarks = ['.svn', '.git', '.root', '_darcs', 'build.xml'] 
```

If none of the parent directories contains these root markers, the directory of the current file is used as the project root. This enables us to use either `<root>` or `$(VIM_ROOT)` to represent the project root. and F7 can be setup to build the current project:

```VimL
nnoremap <silent> <F7> :AsyncRun -cwd=<root> make <cr>
```

What if your current project is not in any git or subversion repository ? How to find out where is my project root ? The solution is very simple, just put an empty `.root` file in your project root, it has been defined in `g:asyncrun_rootmarks` just now.

Let's move on, setup F8 to run the current project:

```VimL
nnoremap <silent> <F8> :AsyncRun -cwd=<root> -raw make run <cr>
```

The project will run in its root directory. Of course, you need define the `run` rule in your own makefile. 
then remap F6 to test:

```VimL
nnoremap <silent> <F6> :AsyncRun -cwd=<root> -raw make test <cr>
```

If you are using cmake, F4 can be map to update your `Makefile`:

```VimL
nnoremap <silent> <F4> :AsyncRun -cwd=<root> cmake . <cr>
```

Due to the implementation of C runtime, if the process is running is a non-tty environment, all the data in stdout will be buffered until process exits. So, there must be a `fflush(stdout)` after your `printf` statement if you want to see the real-time output. or you can close the stdout buffer at the beginning by

```c
setbuf(stdout, NULL);
```

At the mean time, if you are writing C++ code, a `std::endl` can be appended to the end of `std::cout`. It can force flush the stdout buffer.  If you are developing on windows, AsyncRun can open a new cmd window for the child process:

```VimL
nnoremap <silent> <F5> :AsyncRun -cwd=$(VIM_FILEDIR) -mode=4 "$(VIM_FILEDIR)/$(VIM_FILENOEXT)" <cr>
nnoremap <silent> <F8> :AsyncRun -cwd=<root> -mode=4 make run <cr>
```

Using the option `-mode=4` on windows will open a new prompt window to run the command, just like running command line programs in Visual Studio. Finally, we have these key mappings below:

- F4: update Makefile with cmake.
- F5: run the single file
- F6: run project test
- F7: build project
- F8: run project
- F9: compile the single file
- F10: toggle quickfix window

It is more like build system in NotePad++ and GEdit. If you are using cmake heavily, you can write a simple shell script located in `~/.vim/script/build.sh` to combine F4 and F7 together: it will update Makefile if CMakeList.txt has been changed, then exectute `make`. 

## Advanced usage

You can also define shell scripts in your dotfiles repository and execute the script with F3:

```VimL
nnoremap <F3> :AsyncRun -cwd=<root> sh /path/to/your/dotfiles/script/build_advanced.sh <cr>
```

The following shell environment variables are defined by AsyncRun:

```text
$VIM_FILEPATH  - File name of current buffer with full path
$VIM_FILENAME  - File name of current buffer without path
$VIM_FILEDIR   - Full path of current buffer without the file name
$VIM_FILEEXT   - File extension of current buffer
$VIM_FILENOEXT - File name of current buffer without path and extension
$VIM_CWD       - Current directory
$VIM_RELDIR    - File path relativize to current directory
$VIM_RELNAME   - File name relativize to current directory 
$VIM_ROOT      - Project root directory
$VIM_CWORD     - Current word under cursor
$VIM_CFILE     - Current filename under cursor
$VIM_GUI       - Is running under gui ?
$VIM_VERSION   - Value of v:version
$VIM_COLUMNS   - How many columns in vim's screen
$VIM_LINES     - How many lines in vim's screen
$VIM_SVRNAME   - Value of v:servername for +clientserver usage 
```

All the above environment variables can be used in your `build_advanced.sh`. Using the external shell script file can do more complex work then a single command.

## Grep symbols

Sometimes, If you don't have a well setup environment in you remote linux box, `grep` is the most cheap way to search symbol definition and references among sources. Now we will have F2 to search keyword under cursor:

```VimL
if has('win32') || has('win64')
    noremap <silent><F2> :AsyncRun! -cwd=<root> findstr /n /s /C:"<C-R><C-W>" 
            \ "\%CD\%\*.h" "\%CD\%\*.c*" <cr>
else
    noremap <silent><F2> :AsyncRun! -cwd=<root> grep -n -s -R <C-R><C-W> 
            \ --include='*.h' --include='*.c*' '<root>' <cr>
endif
```

The above script will run grep or findstr in your project root directory, and find symbols in only `.c`, `.cpp` and `.h` files. When we move around the cursor and press F2, the symbol references in current project will be displayed in the quickfix window immediately.

You can improve this script to support more file types in your `vimrc` .