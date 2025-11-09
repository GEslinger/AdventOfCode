const std = @import("std");
const print = std.debug.print;
const aoc = @import("aoc");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var lines = try aoc.inputLineIterator(alloc);
    defer alloc.free(lines.contents);

    var seq_a: std.ArrayList(i64) = .empty;
    defer seq_a.deinit(alloc);
    var seq_b: std.ArrayList(i64) = .empty;
    defer seq_b.deinit(alloc);

    var current = &seq_a;
    var build = &seq_b;

    var end_tower: std.ArrayList(i64) = .empty;
    defer end_tower.deinit(alloc);
    var start_tower: std.ArrayList(i64) = .empty;
    defer start_tower.deinit(alloc);

    var sum_1: i64 = 0;
    var sum_2: i64 = 0;

    while (lines.next()) |line| {
        //print("{s}\n", .{line});
        var num_strings = std.mem.tokenizeAny(u8, line, " ");
        while (num_strings.next()) |num_string| {
            const num = try std.fmt.parseInt(i64, num_string, 10);
            try current.append(alloc, num);
        }

        var all_zero = false;
        while (all_zero == false) {
            all_zero = true;
            for (current.items[0 .. current.items.len - 1], current.items[1..], 0..) |a, b, i| {
                const next_num = b - a;
                try build.append(alloc, next_num);
                //print("{} ", .{next_num});

                if (next_num != 0) all_zero = false;

                if (i == 0) try start_tower.append(alloc, a);
                if (i == current.items.len - 2) try end_tower.append(alloc, b);
            }
            //print("\n", .{});

            current.clearRetainingCapacity();
            const tmp = current;
            current = build;
            build = tmp;
        }

        var result_1: i64 = 0; // add_tower.getLast();
        for (end_tower.items) |value| {
            result_1 += value;
        }

        //print("Start tower: {any}\n", .{start_tower.items});
        var i: usize = start_tower.items.len;
        var result_2: i64 = 0;
        while (i > 0) {
            i -= 1;
            result_2 = start_tower.items[i] - result_2;
        }

        // Reset for next row
        //print("Result: {}\n", .{result_2});
        sum_1 += result_1;
        sum_2 += result_2;
        current.clearRetainingCapacity();
        build.clearRetainingCapacity();
        end_tower.clearRetainingCapacity();
        start_tower.clearRetainingCapacity();
    }

    print("Part 1: {}\n", .{sum_1});
    print("Part 2: {}\n", .{sum_2});
}
