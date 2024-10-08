
# Introduction 

`zentropy` is a tool to measure a file's Shannon entropy, which gives useful information such as theoretical minimum size, but also helpful in identifying specific kinds of files.

Note, various compression algorithms can reach sizes smaller than the one given by calculating Shannon entropy, as Shannon entropy assumes a statistical model where the bytes are uncorrelated (i.e: 0 order).

# Usage 

Fairly straightforward, point it at a file! 

```bash
$ zentropy /path/to/file
```

Here's the output of running it against the project's build.zig:

```bash

$ zentropy ./build.zig 

------------
| zentropy |
------------
entropy            => 0.55 nats
entropy (bits)     => 4.36 bits
file size          => 1.59 Kib
possible file size => 887.35 bytes
compression        => 45.49 %

```

# Installation 

Get a precompiled binary from the [release page](https://github.com/aalbacetef/zentropy/releases) or build your own with zig!

### Special steps 

On both Linux and Mac, don't forget to `chmod +x /path/to/binary`. 

Mac might yell at you for trying to run the binary, in which case, just run:

```bash
$ xattr -d com.apple.quarantine /path/to/binary
```

### Supported platforms

So far, it's only been tested on:

|  arch   |    os   |
|---------|---------|
| x86_64  | windows |
| x86_64  | linux   |
| x86_64  | mac os  |


# Roadmap

Some things on the roadmap / to-do list when I have some time:

- [ ] support wasm
- [ ] JSON output
- [ ] wrap in a Docker container
- [ ] allow setting chunk size via env var or cli flag
