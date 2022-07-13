If vim's 'encoding' is different with OS's encoding, output in quickfix window which contains CJK characters may failed, you need add these line to tell asyncrun the output of background command need to be convert to the same encoding as vim:

```VimL
let g:asyncrun_encs = 'gbk'
```

Then everything works fine.
