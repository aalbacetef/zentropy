const std = @import("std");

const bits = 8;
const max_size = 1 << bits;

pub const Histogram = struct {
    total: u64 = 0,
    data: [max_size]u64,

    pub fn init() Histogram {
        return .{ .data = [_]u64{0} ** max_size };
    }

    pub fn munch(self: *Histogram, bytes: []u8) void {
        for (bytes) |c| {
            self.data[c] += 1;
        }
        self.total += bytes.len;
    }
};

const log2bytes = 8.0;

pub fn calculate(h: Histogram) f64 {
    var entr: f64 = 0;
    const total: f64 = @floatFromInt(h.total);

    for (h.data) |val| {
        if (val == 0) {
            continue;
        }
        const count: f64 = @floatFromInt(val);
        const p = count / total;
        entr += p * std.math.log2(p);
    }

    // @NOTE: avoid -0
    if (entr == 0.0) {
        return 0.0;
    }

    return -entr / log2bytes;
}

test "it calculates the entropy correctly" {
    var bytes = [_]u8{ 0x0, 0x01, 0x02, 0x03, 0x04 };
    var h = Histogram.init();
    h.munch(&bytes);

    const got = calculate(h);
    const N: f64 = @floatFromInt(bytes.len);
    const want: f64 = std.math.log2(N) / log2bytes;

    try std.testing.expectApproxEqRel(want, got, 0.001);
}
