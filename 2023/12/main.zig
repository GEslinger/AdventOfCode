const std = @import("std");
const print = std.debug.print;
const aoc = @import("aoc");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var lines = try aoc.inputLineIterator(alloc);
    defer alloc.free(lines.contents);

    var broken_list: std.ArrayList(u16) = .empty;
    defer broken_list.deinit(alloc);

    var num_for_consumed: std.ArrayList(std.ArrayList(u64)) = .empty;
    try num_for_consumed.appendNTimes(alloc, .empty, 50);
    defer {
        for (num_for_consumed.items) |*list| list.deinit(alloc);
        num_for_consumed.deinit(alloc);
    }

    while (lines.next()) |line| : ({
        broken_list.clearRetainingCapacity();
        for (num_for_consumed.items) |*list| list.clearRetainingCapacity();
        num_for_consumed.clearRetainingCapacity();
    }) {
        var line_split = std.mem.tokenizeAny(u8, line, " ");
        // Grab for later
        const corrupt_record = line_split.next().?;

        // Parse the list of broken springs
        var broken_spring_iter = std.mem.tokenizeAny(u8, line_split.next().?, ",");
        while (broken_spring_iter.next()) |num_string| {
            const num = try std.fmt.parseInt(u16, num_string, 10);
            try broken_list.append(alloc, num);
        }

        print("Broken: {any}\n", .{broken_list.items});
        for (0..broken_list.items.len) |i| try num_for_consumed.items[i].appendNTimes(alloc, 0, corrupt_record.len + 1);

        for (corrupt_record, 0..) |char, i| {
            print("{c}  - pos {}\n", .{ char, i });
            for (broken_list.items, 0..) |to_consume, index| {
                // Ensure # or ? continuguous
                var should_count = for (0..to_consume) |check_offset| {
                    if (i + check_offset >= corrupt_record.len) {
                        print("Overshoot, not possible.\n", .{});
                        break false;
                    }

                    if (corrupt_record[i + check_offset] == '.') {
                        print("Bust.\n", .{});
                        break false;
                    }
                } else true;

                // Either end of record or not a # to provide separation
                if (i + to_consume + 1 >= corrupt_record.len) {
                    should_count = false;
                } else if (corrupt_record[i + to_consume + 1] == '#') {
                    should_count = false;
                }

                if (should_count) {
                    print("Counting it!\n", .{});
                    num_for_consumed.items[index].items[i + to_consume] += 1;
                }

                print("# of arrangements having consumed {} (@index {})\n", .{ to_consume, index });
                const list = num_for_consumed.items[index];
                print("{any}\n", .{list.items});
            }
        }

        print("\n\n", .{});
        break;
    }
}
