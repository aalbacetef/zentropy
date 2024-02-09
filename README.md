
# Introduction 

`zentropy` is a tool to measure a file's Shannon entropy, which gives useful information such as theoretical minimum size, but also helpful in identifying specific kinds of files.

Note, various compression algorithms can reach sizes smaller than the one given by calculating Shannon Entropy, as Shannon Entropy assumes a statistical model where the bytes are uncorrelated (i.e: 0 order).

# Usage 

Fairly straightforward, point it at a file! 

```bash
$ zentropy /path/to/file
```

# Installation 

Get a precompiled binary from the release page or build your own with zig!

### Supported platforms

So far, it's only been tested on:

|  arch   |    os   |
| x86_64  | windows |
| x86_64  | linux   |
| x86_64  | mac os  |

