const std = @import("std");
const print = std.debug.print;
const aoc = @import("aoc");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var lines = try aoc.inputLineIterator(alloc);
    defer alloc.free(lines.contents);
    //while (lines.next()) |line| {
    //print("{s}\n", .{line});
    //}
    var fmt_buf: [100]u8 = @splat(0);
    var fmt_buf_i: usize = 0;

    var times: std.ArrayList(u64) = .empty;
    defer times.deinit(alloc);

    var dists: std.ArrayList(u64) = .empty;
    defer dists.deinit(alloc);

    const times_slice = std.mem.trimStart(u8, lines.next().?, "Time: ");
    var times_iter = std.mem.tokenizeAny(u8, times_slice, " ");
    while (times_iter.next()) |time_str| {
        const time = try std.fmt.parseInt(u64, time_str, 10);
        try times.append(alloc, time);

        @memcpy(fmt_buf[fmt_buf_i .. fmt_buf_i + time_str.len], time_str);
        fmt_buf_i += time_str.len;
    }
    const time_no_space = try std.fmt.parseInt(u64, fmt_buf[0..fmt_buf_i], 10);

    fmt_buf_i = 0;
    const dists_slice = std.mem.trimStart(u8, lines.next().?, "Distance: ");
    var dists_iter = std.mem.tokenizeAny(u8, dists_slice, " ");
    while (dists_iter.next()) |dist_str| {
        const dist = try std.fmt.parseInt(u64, dist_str, 10);
        try dists.append(alloc, dist);

        @memcpy(fmt_buf[fmt_buf_i .. fmt_buf_i + dist_str.len], dist_str);
        fmt_buf_i += dist_str.len;
    }
    const record_no_space = try std.fmt.parseInt(u64, fmt_buf[0..fmt_buf_i], 10);

    var win_multiplier: u64 = 1;
    for (times.items, dists.items) |time, record| {
        print("Time available {}, record to beat {}\n", .{ time, record });

        var wins: u64 = 0;
        for (0..time) |i| {
            if (i * (time - i) > record) wins += 1;
        }

        print("Total ways: {}\n", .{wins});
        win_multiplier *= wins;
    }

    print("Answer part 1: {}\n", .{win_multiplier});

    // Part 2 using a little math trick
    print("Time available {}, record {}\n", .{ time_no_space, record_no_space });
    const limit: usize = for (0..time_no_space) |i| {
        if (i * (time_no_space - i) > record_no_space) break i;
    } else unreachable;
    print("Number of ways : {}\n", .{time_no_space - 2 * limit + 1});
}
