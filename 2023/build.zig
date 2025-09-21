const std = @import("std");

// Although this function looks imperative, it does not perform the build
// directly and instead it mutates the build graph (`b`) that will be then
// executed by an external runner. The functions in `std.Build` implement a DSL
// for defining build steps and express dependencies between them, allowing the
// build runner to parallelize the build automatically (and the cache system to
// know when a step doesn't need to be re-run).
pub fn build(b: *std.Build) void {
    // Standard target options allow the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});
    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("aoc", .{
        .root_source_file = b.path("aoc_utils/root.zig"),
        .target = target,
    });
    const mod_tests = b.addTest(.{
        .root_module = mod,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);
    const mod_test_step = b.step("testmod", "Run tests on utils module");
    mod_test_step.dependOn(&run_mod_tests.step);

    const run_step = b.step("run", "Run the app");
    const test_step = b.step("test", "Run tests");

    const day_to_do = b.option(u8, "day", "Day to run");
    for (1..26) |day| {
        if (day_to_do orelse 0 != day) continue;

        var str_buf: [2]u8 = undefined;
        var path_buf: [11]u8 = undefined;
        const day_str = std.fmt.bufPrint(&str_buf, "{d:0>2}", .{day}) catch unreachable;
        const day_src_path = std.fmt.bufPrint(&path_buf, "{s}/main.zig", .{day_str}) catch unreachable;

        // Have to do this because the build routines cause a panic on file not found
        _ = std.fs.cwd().access(day_src_path, .{}) catch continue;

        const exe = b.addExecutable(.{
            .name = day_str,
            .root_module = b.createModule(.{
                .root_source_file = b.path(day_src_path),
                .target = target,
                .optimize = optimize,
                .imports = &.{
                    .{ .name = "aoc", .module = mod },
                },
            }),
        });

        const exe_tests = b.addTest(.{
            .root_module = exe.root_module,
        });

        const day_install = b.addInstallArtifact(exe, .{});
        const run_cmd = b.addRunArtifact(exe);
        const run_exe_tests = b.addRunArtifact(exe_tests);

        b.getInstallStep().dependOn(&day_install.step);

        run_step.dependOn(&run_cmd.step);
        run_cmd.step.dependOn(b.getInstallStep());

        test_step.dependOn(&run_exe_tests.step);

        if (b.args) |args| {
            //for (args) |arg| std.debug.print("Argument {s}\n", .{arg});
            run_cmd.addArgs(args);
        }
    }
}
