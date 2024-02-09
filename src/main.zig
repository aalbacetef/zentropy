const std = @import("std");
const util = @import("./util.zig");
const entropy = @import("./entropy.zig");
const formatter = @import("./formatter.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const status = gpa.deinit();
        switch (status) {
            .leak => std.debug.print("leaked\n", .{}),
            .ok => {},
        }
    }

    run(allocator) catch |err| {
        switch (err) {
            error.FileNotFound => std.debug.print("error: file not found\n\n", .{}),
            else => {},
        }

        printHelp();
    };
}

fn run(allocator: std.mem.Allocator) !void {
    const first_arg = try util.firstArg(allocator) orelse {
        std.debug.print("please provide a path\n", .{});
        return;
    };
    defer allocator.free(first_arg);

    if (isHelp(first_arg)) {
        printHelp();
        return;
    }

    var streamer = try util.FileStreamer.init(.{
        .fpath = first_arg,
        .allocator = allocator,
        .chunk_size = 10 * 1024,
    });
    defer streamer.deinit();

    var h = entropy.Histogram.init();

    while (try streamer.next()) |bytes| {
        h.munch(bytes);
    }

    const ent = entropy.calculate(h);
    const fsize: f64 = @floatFromInt(h.total);
    const possible = fsize * ent;
    const compr = 100.0 * (1.0 - ent);

    const largest_field = "possible file size";
    const logger = formatter.Logger{
        .allocator = allocator,
        .field_width = largest_field.len,
    };

    const w = std.io.getStdOut().writer();

    try logger.banner(w, "zentropy", .{});

    try logger.printFloat(w, "entropy", ent, "nats");
    try logger.printFloat(w, "entropy (bits)", ent * 8.0, "bits");
    try logger.printValue(w, "file size", fsize);
    try logger.printValue(w, "possible file size", possible);
    try logger.printFloat(w, "compression", compr, "%");
}

fn isHelp(s: []u8) bool {
    const possible = [_][]const u8{
        "-h",
        "--help",
        "h",
        "help",
    };

    for (possible) |v| {
        if (std.mem.eql(u8, s, v)) {
            return true;
        }
    }

    return false;
}

fn printHelp() void {
    std.debug.print(
        \\ zentropy
        \\
        \\     Calculate Shannon Entropy for a file 
        \\
        \\ Usage
        \\
        \\     zentropy FILE
        \\ 
    , .{});
}

test "it calculates file entropy correctly" {
    const testCases = [_]struct {
        want: f64,
        size: usize,
        fpath: []const u8,
    }{
        .{ .want = 1.0, .size = 65536, .fpath = "testdata/random.file" },
        .{ .want = 0.25, .size = 777, .fpath = "testdata/deadbeef.file" },
        .{ .want = 0.60, .size = 45, .fpath = "testdata/deadbeef.file.gz" },
    };

    for (testCases) |c| {
        var streamer = try util.FileStreamer.init(.{
            .allocator = std.testing.allocator,
            .fpath = c.fpath,
            .chunk_size = 1024,
        });
        defer streamer.deinit();

        var h = entropy.Histogram{ .data = [_]u64{0} ** 256 };
        while (try streamer.next()) |bytes| {
            h.munch(bytes);
        }

        try std.testing.expectEqual(c.size, h.total);

        const ent = entropy.calculate(h);
        try std.testing.expectApproxEqRel(c.want, ent, 0.001);
    }
}
