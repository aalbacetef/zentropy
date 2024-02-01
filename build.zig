const std = @import("std");

const lib = struct {
    name: []const u8,
    path: []const u8,
    with_tests: bool = true,
};

const libs: []const lib = &.{
    .{ .name = "entropy", .path = "src/entropy.zig" },
    .{ .name = "util", .path = "src/util.zig" },
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zentropy",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    const test_step = b.step("test", "unit tests");
    const exe_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    test_step.dependOn(&run_exe_unit_tests.step);

    for (libs) |l| {
        b.installArtifact(b.addStaticLibrary(.{
            .name = l.name,
            .root_source_file = .{
                .path = l.path,
            },
            .target = target,
            .optimize = optimize,
        }));

        if (l.with_tests) {
            const t = b.addTest(.{
                .root_source_file = .{ .path = l.path },
                .target = target,
                .optimize = optimize,
            });

            const r = b.addRunArtifact(t);
            test_step.dependOn(&r.step);
        }
    }
}
