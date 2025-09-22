const std = @import("std");
const print = std.debug.print;
const aoc = @import("aoc");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var lines = try aoc.inputLineIterator(alloc);
    defer alloc.free(lines.contents);

    var matrix: std.ArrayList([]const u8) = .empty;
    defer matrix.deinit(alloc);

    var symbols: std.ArrayList([2]usize) = .empty;
    defer symbols.deinit(alloc);

    var numbers = std.AutoHashMap([2]usize, u64).init(alloc);
    defer numbers.deinit();

    var i: usize = 0;
    while (lines.next()) |line| : (i += 1) {
        try matrix.append(alloc, line);

        for (line, 0..) |char, j| {
            switch (char) {
                '.', '0'...'9' => {},
                else => try symbols.append(alloc, [2]usize{ i, j }),
            }
        }
    }

    var gear_ratio_sum: u64 = 0;
    for (symbols.items) |coords| {
        const neighbors = aoc.neighbors8(matrix.items, coords);
        const has_gear = (matrix.items[coords[0]][coords[1]] == '*');

        var potential_gear_ratio: u64 = 1;
        var buddies: usize = 0;
        for (neighbors.arr[0..neighbors.len]) |n| {
            const is_numeric = aoc.isNumeric(matrix.items[n[0]][n[1]]);

            if (!is_numeric) continue;
            //print("{any} - {c}\n", .{ n, matrix.items[n[0]][n[1]] });

            var x = n[1];
            const number_start: usize = while (x > 0) : (x -= 1) {
                if (!aoc.isNumeric(matrix.items[n[0]][x - 1])) break x;
            } else 0;

            x = n[1];
            const number_end: usize = while (x < matrix.items[n[0]].len) : (x += 1) {
                if (!aoc.isNumeric(matrix.items[n[0]][x])) break x;
            } else matrix.items[n[0]].len;

            //print("Number runs {} - {}\n", .{ number_start, number_end });
            //print("Number is: {s}\n", .{matrix.items[n[0]][number_start..number_end]});

            const num = try std.fmt.parseInt(
                u64,
                matrix.items[n[0]][number_start..number_end],
                10,
            );

            const result = try numbers.getOrPut([2]usize{ n[0], number_start });
            if (!result.found_existing) {
                potential_gear_ratio *= num;
                buddies += 1;
            }
            result.value_ptr.* = num;
        }

        if (has_gear and buddies == 2) gear_ratio_sum += potential_gear_ratio;
    }

    var total: u64 = 0;
    var iter = numbers.iterator();
    while (iter.next()) |entry| {
        total += entry.value_ptr.*;
    }

    print("Sum total of all numbers with symbol neighbors: {}\n", .{total});
    print("Total gear ratio product: {}", .{gear_ratio_sum});
}
