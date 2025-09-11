const std = @import("std");
const print = std.debug.print;
const Stone = u64;
const Counter = u128;

// NOTE: DYNAMIC PROGRAMMING RULES!!!

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    var alloc = gpa.allocator();
    defer _ = gpa.deinit();

    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();
    const contents = try file.readToEndAlloc(alloc, 1_000_000);
    defer alloc.free(contents);

    print("Contents:\n{s}\n", .{contents});

    var stone_rules = std.AutoHashMap(Stone, [2]?Stone).init(alloc);
    defer stone_rules.deinit();

    var start_stone_count = std.AutoHashMap(Stone, Counter).init(alloc);
    defer start_stone_count.deinit();
    var result_stone_count = try start_stone_count.clone();
    defer result_stone_count.deinit();

    {
        var first_stones_strings = std.mem.tokenizeAny(u8, contents, " \r\n");
        while (first_stones_strings.next()) |stone_string| {
            const stone = try std.fmt.parseInt(Stone, stone_string, 10);
            const entry = try start_stone_count.getOrPutValue(stone, 0);
            entry.value_ptr.* += 1;
        }
    }

    var fmt_buf: [1_000]u8 = undefined;
    const limit = 75;
    for (0..limit) |level| {
        result_stone_count.clearRetainingCapacity();
        _ = level;

        var stone_iter = start_stone_count.iterator();
        while (stone_iter.next()) |entry| {
            const stone_val = entry.key_ptr.*;
            const count = entry.value_ptr.*;

            // Manage rules, add new if not existing
            const rule_entry = try stone_rules.getOrPut(stone_val);
            const rule = rule_entry.value_ptr;
            if (!rule_entry.found_existing) {
                rule.* = [2]?Stone{ null, null };

                const val_string = try std.fmt.bufPrint(&fmt_buf, "{}", .{stone_val});
                if (stone_val == 0) { // Base case
                    rule.*[0] = 1;
                } else if (val_string.len % 2 == 0) { // Even number of digits
                    const first_half_str = val_string[0 .. val_string.len / 2];
                    const second_half_str = val_string[val_string.len / 2 .. val_string.len];

                    const first_half = try std.fmt.parseInt(Stone, first_half_str, 10);
                    const second_half = try std.fmt.parseInt(Stone, second_half_str, 10);

                    rule.*[0] = first_half;
                    rule.*[1] = second_half;
                } else { // fallback rule
                    rule.*[0] = stone_val * 2024;
                }

                //print("Rule for {} -> {any} and {any}\n", .{ stone_val, rule.*[0], rule.*[1] });
            }

            // Apply rule to current count, save as result.
            for (rule) |result_optional| {
                const result_stone_val = result_optional orelse continue;
                const result_entry = try result_stone_count.getOrPutValue(result_stone_val, 0);

                result_entry.value_ptr.* += count;
            }
        }

        // Move to next step
        start_stone_count.clearAndFree();
        start_stone_count = try result_stone_count.clone();
    }

    var total: Counter = 0;
    var result_iter = result_stone_count.iterator();
    while (result_iter.next()) |entry| total += entry.value_ptr.*;
    print("Rules identified: {}\n", .{stone_rules.count()});
    print("Total at {} blinks: {}\n", .{ limit, total });
}
