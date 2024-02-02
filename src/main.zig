const std = @import("std");
const time = std.time;
const util = @import("./util.zig");
const entropy = @import("./entropy.zig");
const formatter = @import("./formatter.zig");

const Instant = time.Instant;
const Timer = time.Timer;

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

    const first_arg = try util.firstArg(allocator);
    var streamer = try util.FileStreamer.init(.{
        .fpath = first_arg,
        .allocator = allocator,
        .chunk_size = 100 * 1024 * 1024,
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

    const logger = formatter.Logger{ .allocator = allocator };

    const w = std.io.getStdOut().writer();
    try logger.banner(w, "zentropy", .{});

    try logger.printFloat(w, "entropy", ent, "nats");
    try logger.printValue(w, "file size", fsize);
    try logger.printValue(w, "possible file size", possible);
    try logger.printFloat(w, "compression", compr, "%");
}

const sizes = enum(u64) {
    bytes = 10,
    kb = 20,
    mb = 30,
    gb = 40,
};

const prefixes = enum(u8) {
    bytes = ' ',
    kb = 'K',
    mb = 'M',
    gb = 'G',
};

test "it calculates file entropy correctly" {
    const want: f64 = 1.0;

    var streamer = try util.FileStreamer.init(.{
        .allocator = std.testing.allocator,
        .fpath = "testdata/random.file",
        .chunk_size = 1024,
    });
    defer streamer.deinit();

    var h = entropy.Histogram{ .data = [_]u64{0} ** 256 };
    while (try streamer.next()) |bytes| {
        h.munch(bytes);
    }

    const wantBytes = 65536;
    try std.testing.expectEqual(wantBytes, h.total);

    const ent = entropy.calculate(h);
    try std.testing.expectApproxEqRel(want, ent, 0.001);
}
