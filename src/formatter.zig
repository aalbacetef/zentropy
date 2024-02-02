const std = @import("std");
const strings = @import("./strings.zig");
const joinStrings = strings.joinStrings;
const repeatString = strings.repeatString;

const sufEntry = struct { limit: f64, suffix: []const u8 };

const table: [4]sufEntry = .{
    .{ .limit = 1 << 10, .suffix = "bytes" },
    .{ .limit = 1 << 20, .suffix = "K" },
    .{ .limit = 1 << 30, .suffix = "M" },
    .{ .limit = 1 << 40, .suffix = "G" },
};

fn findSuffix(v: f64) usize {
    var indx: usize = 0;
    for (0.., table) |k, entry| {
        indx = k;
        if (v < entry.limit) {
            break;
        }
    }

    return indx;
}

test "it suffixes correctly" {
    const cases = [_]struct { v: f64, index: usize }{
        .{ .v = 100, .index = 0 },
        .{ .v = 2000, .index = 1 },
        .{ .v = 2_000_000, .index = 2 },
        .{ .v = 2_000_000_000, .index = 3 },
    };

    for (cases) |c| {
        const want = c.index;
        const got = findSuffix(c.v);

        try std.testing.expectEqual(want, got);
    }
}

const Padding = struct {
    h: usize = 1,
    v: usize = 1,
};

const Box = struct {
    h: []const u8 = "-",
    v: []const u8 = "|",
};

const BannerOptions = struct {
    padding: Padding = .{},
    box: Box = .{},
};

pub const Logger = struct {
    allocator: std.mem.Allocator,
    add_new_line: bool = true,

    pub fn banner(
        self: Logger,
        w: anytype, // this is a proxy for a std.io.Writer
        s: []const u8,
        opts: BannerOptions,
    ) !void {
        const n = s.len;
        const h_len =
            n + (2 * opts.box.h.len) + (2 * opts.padding.h);

        const horizontal = try repeatString(
            self.allocator,
            opts.box.h,
            h_len,
        );

        defer self.allocator.free(horizontal);

        const padding_h = try repeatString(
            self.allocator,
            " ",
            opts.padding.h,
        );
        defer self.allocator.free(padding_h);

        const banner_line = try joinStrings(
            self.allocator,
            &.{
                opts.box.v,
                s,
                opts.box.v,
            },
            padding_h,
        );
        defer self.allocator.free(banner_line);

        const out = try joinStrings(
            self.allocator,
            &.{
                horizontal,
                banner_line,
                horizontal,
            },
            "\n",
        );
        defer self.allocator.free(out);

        try std.fmt.format(w, "{s}", .{out});
        self.appendNewline(w);
    }

    pub fn printFloat(self: Logger, w: anytype, name: []const u8, v: f64, suffix: []const u8) !void {
        try std.fmt.format(w, "{s} => {d:.2} {s}", .{ name, v, suffix });
        self.appendNewline(w);
    }

    pub fn printValue(self: Logger, w: anytype, name: []const u8, v: f64) !void {
        var newline_str = " ";
        if (self.add_new_line) {
            newline_str = "\n";
        }

        const index = findSuffix(v);
        var val = v;
        for (0..index) |_| {
            val = val / 1024.0;
        }

        try self.printFloat(w, name, val, table[index].suffix);
    }

    fn appendNewline(self: Logger, w: anytype) void {
        if (!self.add_new_line) {
            return;
        }

        std.fmt.format(w, "\n", .{}) catch return;
    }
};

test "it prints a banner" {
    const l = Logger{
        .allocator = std.testing.allocator,
        .add_new_line = false,
    };
    const want =
        "==============" ++ "\n" ++
        "|  zentropy  |" ++ "\n" ++
        "==============";

    var buf = try std.testing.allocator.alloc(u8, want.len);
    buf[0] = 0;
    @memset(buf, 0);

    defer std.testing.allocator.free(buf);
    var fb = std.io.fixedBufferStream(buf);

    try l.banner(
        fb.writer(),
        "zentropy",
        .{
            .padding = .{ .h = 2 },
            .box = .{
                .h = "=",
            },
        },
    );

    try std.testing.expectEqualStrings(want, buf);
}
