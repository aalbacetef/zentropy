const std = @import("std");
const time = std.time;
const util = @import("./util.zig");
const entropy = @import("./entropy.zig");

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

    const fsize_unit = switch (std.math.log2(h.total)) {
        0...9 => prefixes.bytes,
        10...19 => prefixes.kb,
        20...39 => prefixes.mb,
        else => prefixes.gb,
    };

    const fsize: f64 = @floatFromInt(h.total);
    const file_size = switch (fsize_unit) {
        .bytes => fsize,
        .kb => fsize / 1024.0 / 1024.0,
        .mb => fsize / 1024.0 / 1024.0 / 1024.0,
        .gb => fsize / 1024.0 / 1024.0 / 1024.0 / 1024.0,
    };

    const possible_fsize = file_size / ent;
    const unit: [1]u8 = [_]u8{@intFromEnum(fsize_unit)};

    std.debug.print("|zentropy|\n", .{});
    std.debug.print("---------\n", .{});
    std.debug.print("entropy: {d.4}\n", .{ent});
    std.debug.print("file size: {d.2}{s}\n", .{ file_size, unit });
    std.debug.print("possible file size: {d.2}{s}\n", .{ possible_fsize, unit });
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
