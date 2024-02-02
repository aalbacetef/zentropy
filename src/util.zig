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

test "it reads the first arg" {
    const first_arg = try firstArg(std.testing.allocator);
    const want = "--listen=-"; // on tests at least this is the argument
    try std.testing.expectEqualStrings(want, first_arg);
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

// we're mostly wrapping around std.fs.realpath so just making sure the wrapper
// doesn't leak.
test "absPath doesn't leak" {
    const fpath = "./";
    const allocator = std.testing.allocator;
    const abspath = try absPath(allocator, fpath);
    defer allocator.free(abspath);
}

const FileStreamerOpts = struct {
    allocator: std.mem.Allocator,
    chunk_size: usize,
    fpath: []const u8,
};

pub const FileStreamer = struct {
    allocator: std.mem.Allocator,
    chunk_size: usize,
    buf: []u8,
    file: std.fs.File,
    pos: usize = 0,
    fsize: usize = 0,

    pub fn init(opts: FileStreamerOpts) !FileStreamer {
        if (opts.chunk_size == 0) {
            return error.ChunkSizeError;
        }

        const abspath = try absPath(opts.allocator, opts.fpath);
        defer opts.allocator.free(abspath);

        const file = try std.fs.openFileAbsolute(abspath, .{ .mode = .read_only });
        errdefer file.close();

        const fsize = (try file.stat()).size;

        return FileStreamer{
            .chunk_size = opts.chunk_size,
            .allocator = opts.allocator,
            .file = file,
            .buf = try opts.allocator.alloc(u8, opts.chunk_size),
            .fsize = fsize,
        };
    }

    pub fn deinit(self: *FileStreamer) void {
        self.allocator.free(self.buf);
        self.file.close();
    }

    pub fn next(self: *FileStreamer) !?[]u8 {
        if (self.pos >= self.fsize) {
            return null;
        }

        const bytes_read = try self.file.pread(self.buf, self.pos);
        if (bytes_read == 0) {
            return null;
        }

        self.pos += bytes_read;
        return self.buf[0..bytes_read];
    }
};

test "correctly reads bytes" {
    const cases = [_]struct {
        file: []const u8,
        size: usize,
    }{
        .{ .file = "testdata/random.file", .size = 65536 },
        .{ .file = "testdata/only.same.byte.file", .size = 777 },
        .{ .file = "testdata/only.same.byte.file.gz", .size = 48 },
    };

    for (cases) |c| {
        try testSize(std.testing.allocator, c.file, c.size);
    }
}

fn testSize(allocator: std.mem.Allocator, fpath: []const u8, want: usize) !void {
    const abspath = try absPath(allocator, fpath);
    defer allocator.free(abspath);

    var total: u64 = 0;
    var sf = try FileStreamer.init(.{
        .fpath = fpath,
        .chunk_size = 1024,
        .allocator = allocator,
    });
    defer sf.deinit();

    while (try sf.next()) |bytes| {
        total += bytes.len;
    }

    try std.testing.expectEqual(want, total);
}
