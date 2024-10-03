const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zentropy",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    const test_step = b.step("test", "unit tests");
    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    test_step.dependOn(&run_exe_unit_tests.step);

    const libs = [_][]const u8{
        "src/entropy.zig",
        "src/formatter.zig",
        "src/strings.zig",
        "src/util.zig",
    };

    for (libs) |l| {
        const t = b.addTest(.{
            .root_source_file = b.path(l),
            .target = target,
            .optimize = optimize,
        });

        const r = b.addRunArtifact(t);
        test_step.dependOn(&r.step);
    }
}
