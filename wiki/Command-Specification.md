## Command 

```VimL
:AsyncRun[!] [options] {cmd} ...
```

## Variable Substitution

Macro variables in the parameters and `-cwd=` option will be expanded before executing:

    $(VIM_FILEPATH)  - File name of current buffer with full path
    $(VIM_FILENAME)  - File name of current buffer without path
    $(VIM_FILEDIR)   - Full path of current buffer without the file name
    $(VIM_FILEEXT)   - File extension of current buffer
    $(VIM_FILENOEXT) - File name of current buffer without path and extension
    $(VIM_PATHNOEXT) - Current file name with full path but without extension
    $(VIM_CWD)       - Current directory
    $(VIM_RELDIR)    - File path relativize to current directory
    $(VIM_RELNAME)   - File name relativize to current directory 
    $(VIM_ROOT)      - Project root directory
    $(VIM_CWORD)     - Current word under cursor
    $(VIM_CFILE)     - Current filename under cursor
    $(VIM_GUI)       - Is running under gui ?
    $(VIM_VERSION)   - Value of v:version
    $(VIM_COLUMNS)   - How many columns in vim's screen
    $(VIM_LINES)     - How many lines in vim's screen
    $(VIM_SVRNAME)   - Value of v:servername for +clientserver usage
    $(VIM_PRONAME)   - Name of current project root directory
    $(VIM_DIRNAME)   - Name of current directory

Vim's filename modifiers are also accepted:

    %:p     - File name of current buffer with full path
    %:t     - File name of current buffer without path
    %:p:h   - File path of current buffer without file name
    %:e     - File extension of current buffer
    %:t:r   - File name of current buffer without path and extension
    %       - File name relativize to current directory
    %:h:.   - File path relativize to current directory
    <cwd>   - Current directory
    <cword> - Current word under cursor
    <cfile> - Current file name under cursor

But modifiers are not recommended, because it is evaluated before `:AsyncRun` command starts, so if there is a `-cwd=xxx` option, some modifiers may yield an out-dated result for the old working directory.

## Common Options

| Option | Default Value | Description |
|:-|:-:|-|
| `-mode=?` | "async" | specify how to run the command as `-mode=?`, available modes are `"async"` (default), `"bang"` (with `!` command) and `"terminal"` (in internal terminal), see [running modes](#running-modes) for details. |
| `-cwd=?` | `unset` | initial directory (use current directory if unset), for example use `-cwd=<root>` to run commands in [project root directory](#project-root), or `-cwd=$(VIM_FILEDIR)` to run commands in current buffer's parent directory. |
| `-save=?` | 0 | use `-save=1` to save current file, `-save=2` to save all modified files before executing. |
| `-program=?` | `unset` | set to `make` to use `&makeprg`, `grep` to use `&grepprt` and `wsl` to execute commands in WSL (windows 10), see [command modifiers](#command-modifier). |
| `-post=?` | `unset` | vimscript to exec after job finished, spaces **must** be escaped to '\ ' |

## Quickfix Options

| Option | Default Value | Description |
|:-|:-:|-|
| `-auto=?`        | `unset` | event name to trigger `QuickFixCmdPre`/`QuickFixCmdPost` [name] autocmd. |
| `-raw`           | `unset` | use raw output if provided, and `&errorformat` will be ignored. |
| `-strip`         | `unset` | remove the heading/trailing messages if provided (omit command and "[Finished in ...]" message). |
| `-errorformat=?` | `unset` | errorformat for error matching, if it is unprovided, use current `&errorformat` value. Beware that `%` needs to be escaped into `\%`. |
| `-silent`        | `unset` | provide `-silent` to prevent open quickfix window (will override `g:asyncrun_open` temporarily) |
| `-scroll=?`      | `unset` | set to `0` to prevent quickfix auto-scrolling |
| `-once=?`        | `unset` | set to `1` to buffer output and flush when job is finished, useful when there are multi-line patterns in your `errorformat` |
| `-encoding=?`    | `unset` | specify command encoding independently (overshadow `g:asyncrun_encs`) |

## Internal Terminal Options

| Option | Default Value | Description |
|:-|:-:|-|
| `-pos=?` | "bottom" | When using internal terminal with `-mode=term`, `-pos` is used to specify where to split the terminal window, it can be one of `"tab"`, `"curwin"`, `"top"`, `"bottom"`, `"left"`, `"right"` and `"external"`. And you can [customize new runners](#customize-runner) and pass runner's name to `-pos` option. |
| `-rows=num` | 0 | When using a horizontal split terminal, this value represents the height of terminal window. |
| `-cols=num` | 0 | When using a vertical split terminal, this value represents the width of terminal window. |
| `-focus=?` | 1 | set to `0` to prevent focus changing when `-mode=term` |
| `-hidden=?` | 0 | set to `1` to setup `bufhidden` to `hide` for internal terminal |
| `-listed` | 1 | when using `-mode=term`, set to 0 to hide the terminal in the buffer list |
| `-close` | `unset` | when using `-mode=term`, close the terminal automatically when terminal process is finished |

## Runner Options

| Option | Default Value | Description |
|:-|:-:|-|
| `-option=?` | `empty` | arbitrary string can be used to pass additional information to the user-defined runner, eg. `:AsyncRun -option=xxx ...` |
