Vim is lack of project management, as files usually belong to projects, you can do nothing to the project if you don't have any information about where the project locates. Inspired by CtrlP, this feature (new in version 1.3.12) is very useful when you've something to do with the whole project. 

Macro `<root>` or `$(VIM_ROOT)` in the command line or in the `-cwd` option will be expanded as the **Project Root Directory** of the current file:

```VimL
:AsyncRun make
:AsyncRun -cwd=<root> make
```

The first command will run `make` in the current directory of vim (which `:pwd` returns), while the second one will run `make` in the project root directory of current file.

```VimL
:AsyncRun -cwd=<root> grep -n -R sendto .
:AsyncRun -cwd=<root> grep -n -R --include=*.c --include=*.cpp --include=*.h sendto .
```

These commands above will change the working directory to the project root of the current file, and grep the keyword `sendto` in the given ext-names.

The **Project Root** is the nearest ancestor directory of the current file which contains one of these directories or files: 

	.svn .git .hg .root .project

If none of the parent directories contains these **root markers**, the directory of the current file is used as the project root. If your current project is not in any git or subversion repository, just put an empty .root file in your project root, AsyncRun will take it as the project root.

## Config Root Markers

The default root markers can also be changed by option `g:asyncrun_rootmarks`:

	:let g:asyncrun_rootmarks = ['.svn', '.git', '.root', '.bzr', '_darcs', 'build.xml'] 

When you are using `-cwd=<root>`, remember to use `$(VIM_XXX)` macros instead of `%` macros because `%` macros will be expanded by vim itself **before** changing directory while `$(VIM_XXX)` will be expanded **after** changing directory.

Incorrect usage:

```VimL
:AsyncRun -cwd=<root> gcc % -o %<
```

Correct way:

```VimL
:AsyncRun -cwd=<root> gcc $(VIM_RELDIR)/$(VIM_FILENAME) -o $(VIM_RELDIR)/$(VIM_FILENOEXT)
```

These macros can also be used in the command line:

```VimL
:AsyncRun make -f $(VIM_ROOT)/Makefile
:AsyncRun svn up $(VIM_ROOT)
```

## Manually set the project root

Use buffer variables to indicate the project root manually for a given file:

```VimL
:let b:asyncrun_root = "/xxxx/path-to-the-project-root"
```

## Find project root outside asyncrun

This will print the project root of current file:

```VimL
:echo asyncrun#get_root('%')
```


