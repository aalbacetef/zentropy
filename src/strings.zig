const std = @import("std");

pub fn repeatString(allocator: std.mem.Allocator, s: []const u8, n: usize) ![]u8 {
    const needed_bytes = s.len * n;
    var buf = try allocator.alloc(u8, needed_bytes);
    var pos: usize = 0;
    const s_len = s.len;

    while (pos < needed_bytes) {
        for (0.., s) |k, c| {
            buf[pos + k] = c;
        }
        pos += s_len;
    }

    return buf;
}

// @TODO: handle empty strings
// @NOTE: grotesquely large strings will fail (prob check with some max value).
// @NOTE: caller must free buffer.
pub fn joinStrings(allocator: std.mem.Allocator, arr: []const []const u8, sep: []const u8) ![]u8 {
    const sep_bytes = (arr.len - 1) * sep.len;

    // compute array bytes
    var arr_bytes: usize = 0;
    for (arr) |item| {
        arr_bytes += item.len;
    }

    const needed_bytes = arr_bytes + sep_bytes;

    var buf = try allocator.alloc(u8, needed_bytes);

    var pos: usize = 0;
    var slice: []u8 = undefined;

    for (arr) |item| {
        slice = buf[pos .. pos + item.len];
        @memcpy(slice, item);
        pos += item.len;

        if (pos == needed_bytes) {
            break;
        }

        slice = buf[pos .. pos + sep.len];
        @memcpy(slice, sep);
        pos += sep.len;
    }

    return buf;
}

test "it repeats string" {
    const want = "--" ** 4;
    const got = try repeatString(std.testing.allocator, "--", 4);
    defer std.testing.allocator.free(got);
    try std.testing.expectEqualStrings(want, got);
}

test "it joins strings" {
    {
        const want = "ab\nba";
        const got = try joinStrings(
            std.testing.allocator,
            &.{ "ab", "ba" },
            "\n",
        );
        defer std.testing.allocator.free(got);
        try std.testing.expectEqualStrings(want, got);
    }
    {
        const want = "ab-----ba";
        const got = try joinStrings(
            std.testing.allocator,
            &.{ "ab", "ba" },
            "-----",
        );
        defer std.testing.allocator.free(got);
        try std.testing.expectEqualStrings(want, got);
    }
}
