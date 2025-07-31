const std = @import("std");
const print = std.debug.print;
const fmt = std.fmt;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();
    const contents = try file.readToEndAlloc(alloc, 1_000_000);
    defer alloc.free(contents);

    var rules = std.AutoHashMap([2]u64, void).init(alloc);
    defer rules.deinit();

    var middle_sum: u64 = 0;

    var lines = std.mem.splitAny(u8, contents, "\n");
    var i: usize = 0;
    var reading = true;
    line_scan: while (lines.next()) |line| : (i += 1) {
        if (line.len == 0 and reading) {
            print("Divider at line {}.\n", .{i});
            reading = false;
            continue;
        }

        if (reading) {
            // Reading rules
            var rule_defs = std.mem.tokenizeAny(u8, line, "|");
            const first_page = try std.fmt.parseInt(u64, rule_defs.next().?, 10);
            const second_page = try std.fmt.parseInt(u64, rule_defs.next().?, 10);
            const rule: [2]u64 = [2]u64{ first_page, second_page };
            try rules.put(rule, {});
        } else {
            // Testing
            var pages_str = std.mem.tokenizeAny(u8, line, ",");
            _ = pages_str.peek() orelse continue;

            var pages = std.ArrayList(u64).init(alloc);
            defer pages.deinit();

            while (pages_str.next()) |page_str| {
                try pages.append(try std.fmt.parseInt(u64, page_str, 10));
            }

            const middle = pages.items.len / 2;

            for (0..pages.items.len - 1) |first_idx| {
                const first_page = pages.items[first_idx];

                for (first_idx + 1..pages.items.len) |second_idx| {
                    const second_page = pages.items[second_idx];

                    print("Checking {} before {}? ", .{ first_page, second_page });

                    const rule = rules.get([2]u64{ first_page, second_page });
                    if (rule) |_| {
                        print("FOUND\n", .{});
                    } else {
                        print("NOT FOUND\n\n", .{});
                        continue :line_scan;
                    }
                }

                print("\n", .{});
            }
            // All rules have been found
            print("Good. Middle value: {}\n\n", .{pages.items[middle]});
            middle_sum += pages.items[middle];
        }
    } else lines.reset();

    print("\n\nSum of middle values of valid updates: {}\n", .{middle_sum});
}
