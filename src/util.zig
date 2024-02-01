const std = @import("std");

pub const Errors = error{
    NoFilepath,
    UnexpectedEmpty,
};

// firstArg will return the first argument, skipping arg0 (the program name).
pub fn firstArg(allocator: std.mem.Allocator) ![]const u8 {
    var args = std.process.argsWithAllocator(allocator) catch |err| return err;
    defer args.deinit();

    // skip arg0 / program name
    _ = args.skip();

    if (args.next()) |arg| {
        if (arg.len == 0) {
            return Errors.UnexpectedEmpty;
        }

        return arg;
    }

    return Errors.NoFilepath;
}

// absFilePath
// TODO: support expanding path (e.g: ~/), don't fall over when path doesn't exist.
// TODO: should only allocate a new buffer if size is smaller.
// caller must free returned slice.
fn absPath(allocator: std.mem.Allocator, fpath: []const u8) ![]u8 {
    var buf = try allocator.alloc(u8, std.fs.MAX_PATH_BYTES);
    defer allocator.free(buf);

    const abspath = try std.fs.realpath(fpath, buf[0..std.fs.MAX_PATH_BYTES]);
    var fpath_buf = try allocator.alloc(u8, abspath.len);

    for (0.., abspath) |k, byte| {
        fpath_buf[k] = byte;
    }
    return fpath_buf;
}

test "it parses the path" {
    const fpath = "./";
    const allocator = std.testing.allocator;
    const abspath = try absPath(allocator, fpath);
    defer allocator.free(abspath);

    std.debug.print("abspath: {s}\n", .{abspath});
}

const StreamFileOpts = struct {
    allocator: std.mem.Allocator,
    chunk_size: usize,
    fpath: []const u8,
};

const StreamFile = struct {
    allocator: std.mem.Allocator,
    chunk_size: usize,
    buf: []u8,
    file: std.fs.File,
    pos: usize = 0,
    fsize: usize = 0,

    fn init(opts: StreamFileOpts) !StreamFile {
        if (opts.chunk_size == 0) {
            return error.ChunkSizeError;
        }

        const abspath = try absPath(opts.allocator, opts.fpath);
        defer opts.allocator.free(abspath);

        const file = try std.fs.openFileAbsolute(abspath, .{ .mode = .read_only });
        errdefer file.close();

        const fsize = (try file.stat()).size;

        return StreamFile{
            .chunk_size = opts.chunk_size,
            .allocator = opts.allocator,
            .file = file,
            .buf = try opts.allocator.alloc(u8, opts.chunk_size),
            .fsize = fsize,
        };
    }

    fn deinit(self: *StreamFile) void {
        self.allocator.free(self.buf);
        self.file.close();
    }

    fn next(self: *StreamFile) !?[]u8 {
        if (self.pos >= self.fsize) {
            return null;
        }

        const bytes_read = try self.file.pread(self.buf, self.pos);
        if (bytes_read == 0) {
            return null;
        }

        self.pos += bytes_read;
        return self.buf;
    }
};

test "it can stream from a file" {
    const fpath = "./testdata/random.file";
    const allocator = std.testing.allocator;

    const abspath = try absPath(allocator, fpath);
    defer allocator.free(abspath);

    var total: u64 = 0;
    var sf = try StreamFile.init(.{
        .fpath = fpath,
        .chunk_size = 1024,
        .allocator = allocator,
    });
    defer sf.deinit();

    while (try sf.next()) |bytes| {
        total += bytes.len;
    }

    const want = 65536; // file size in bytes
    try std.testing.expectEqual(want, total);
}
