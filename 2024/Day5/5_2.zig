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
    var map_nums = std.AutoHashMap(u64, void).init(alloc);
    defer map_nums.deinit();
    var roadmap: []u64 = undefined;
    defer alloc.free(roadmap);

    var middle_sum: u64 = 0;

    var lines = std.mem.splitAny(u8, contents, "\n");
    var i: usize = 0;
    var reading = true;
    line_scan: while (lines.next()) |line| : (i += 1) {
        if (line.len == 0 and reading) {
            print("Divider at line {}.\n", .{i});
            reading = false;

            // Create roadmap
            roadmap = try alloc.alloc(u64, map_nums.count());
            var candidate = try alloc.alloc(u64, map_nums.count());
            defer alloc.free(candidate);

            var nums_iter = map_nums.keyIterator();
            var j: usize = 0;
            place_number: while (nums_iter.next()) |num| : (j += 1) {
                //print("trying to add {}\n", .{num.*});

                for (0..j) |try_pos| {
                    for (0..j) |idx| {
                        //print("current roadmap has {}\n", .{roadmap[idx]});
                        if (idx < try_pos) {
                            candidate[idx] = roadmap[idx];
                        } else if (idx == try_pos) {
                            candidate[idx] = num.*;
                        } else {
                            candidate[idx] = roadmap[idx - 1];
                        }
                        //print("Candidate at idx {} and try_pos {} set to {}\n", .{ idx, try_pos, candidate[idx] });
                    }
                    print("Candidate list for adding {}: {any}\n", .{ num.*, candidate[0..j] });
                    if (j < 1 or checkIfCorrect(candidate[0..j], rules)) {
                        @memcpy(roadmap, candidate[0..candidate.len]);
                        print("YAY!\n", .{});
                        continue :place_number;
                    }
                }

                if (j > 0) unreachable;
            }
            break :line_scan;
        }

        if (reading) {
            // Reading rules
            var rule_defs = std.mem.tokenizeAny(u8, line, "|");
            const first_page = try std.fmt.parseInt(u64, rule_defs.next().?, 10);
            const second_page = try std.fmt.parseInt(u64, rule_defs.next().?, 10);
            const rule: [2]u64 = [2]u64{ first_page, second_page };
            try rules.put(rule, {});
            _ = try map_nums.getOrPut(first_page);
            _ = try map_nums.getOrPut(second_page);
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

            const is_correct = checkIfCorrect(pages.items, rules);
            if (is_correct) continue :line_scan;

            // This is an incorrect update - we need to order it properly.

            print("Good. Middle value: {}\n\n", .{pages.items[middle]});
            middle_sum += pages.items[middle];
        }
    } else lines.reset();

    print("\n\nSum of middle values of valid updates: {}\n", .{middle_sum});
}

fn checkIfCorrect(pages: []u64, rules: std.AutoHashMap([2]u64, void)) bool {
    for (0..pages.len - 1) |first_idx| {
        const first_page = pages[first_idx];

        for (first_idx + 1..pages.len) |second_idx| {
            const second_page = pages[second_idx];

            print("Checking {} before {}? ", .{ first_page, second_page });

            const rule = rules.get([2]u64{ first_page, second_page });
            if (rule) |_| {
                print("FOUND\n", .{});
            } else {
                print("NOT FOUND\n\n", .{});
                return false;
            }
        }
    }
    return true;
}
