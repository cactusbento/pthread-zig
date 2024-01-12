const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("pthread", .{
        .root_source_file = .{ .path = "src/pthread.zig" },
        .link_libc = true,
    });

    const exe = b.addExecutable(.{
        .name = "zig-pthread",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("pthread", mod);
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the example program");
    run_step.dependOn(&run_cmd.step);

    const module_test = b.addTest(.{
        .root_source_file = .{ .path = "src/pthread.zig" },
        .target = target,
        .optimize = optimize,
    });
    const run_module_tests = b.addRunArtifact(module_test);
    const exe_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe_tests.root_module.addImport("pthread", mod);
    const run_exe_tests = b.addRunArtifact(exe_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_module_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
