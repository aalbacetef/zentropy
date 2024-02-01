const std = @import("std");
const testing = std.testing;

const bits = 8;
const max_size = 1 << bits;

pub const Histogram = struct {
    total: u64 = 0,
    data: [max_size]u64 = undefined,

    pub fn init() Histogram {
        var h = Histogram{};

        @memset(&h.data, 0);

        return h;
    }

    pub fn munch(self: *Histogram, bytes: []u8) void {
        for (bytes) |c| {
            self.data[c] += 1;
        }
        self.total += bytes.len;
    }
};

pub fn calculate(h: Histogram) f64 {
    var entr: f64 = 0;
    const total: f64 = @floatFromInt(h.total);

    for (h.data) |val| {
        if (val == 0) {
            continue;
        }

        const p: f64 = @as(f64, @floatFromInt(val)) / total;
        entr += p * std.math.log2(p);
    }

    return -entr;
}
