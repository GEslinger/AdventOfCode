const std = @import("std");
const print = std.debug.print;
const aoc = @import("aoc");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var spelled_nums = std.StringHashMap(u64).init(alloc);
    defer spelled_nums.deinit();
    try spelled_nums.put("one", 1);
    try spelled_nums.put("two", 2);
    try spelled_nums.put("three", 3);
    try spelled_nums.put("four", 4);
    try spelled_nums.put("five", 5);
    try spelled_nums.put("six", 6);
    try spelled_nums.put("seven", 7);
    try spelled_nums.put("eight", 8);
    try spelled_nums.put("nine", 9);

    var lines = try aoc.inputLineIterator(alloc);
    defer alloc.free(lines.contents);

    var calib_total: u64 = 0;
    while (lines.next()) |line| {
        var first: ?u64 = null;
        var last: ?u64 = null;
        for (line) |char| {
            last = std.fmt.parseInt(u64, &[_]u8{char}, 10) catch continue;
            if (first == null) first = last;
        }
        const line_total = (first orelse break) * 10 + (last orelse break);
        calib_total += line_total;
    }

    print("Part 1: Calibration Total {}\n", .{calib_total});

    // NOTE: Part 2
    calib_total = 0;
    lines.internal_iter.reset();
    while (lines.next()) |line| {
        var first: ?u64 = null;
        var last: ?u64 = null;
        for (line, 0..) |char, i| {
            for (i..i + 6) |j_uncapped| {
                const j = if (j_uncapped > line.len) line.len else j_uncapped;
                //print("{s}\n", .{line[i..j]});
                if (spelled_nums.get(line[i..j])) |num| last = num;
            }
            if (first == null) first = last;
            last = std.fmt.parseInt(u64, &[_]u8{char}, 10) catch continue;
            if (first == null) first = last;
        }
        //print("First {any}, Last {any}\n", .{ first, last });
        const line_total = first.? * 10 + last.?;
        calib_total += line_total;
    }
    print("Part 2: Calibration Total {}\n", .{calib_total});
}
