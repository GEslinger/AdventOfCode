const std = @import("std");
const print = std.debug.print;
const aoc = @import("aoc");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var lines = try aoc.inputLineIterator(alloc);
    defer alloc.free(lines.contents);

    var map: std.ArrayList([]const u8) = .empty;
    defer map.deinit(alloc);

    const start = blk: {
        var find_start: ?[2]usize = null;
        var i: usize = 0;
        while (lines.next()) |line| : (i += 1) {
            print("{s}\n", .{line});
            try map.append(alloc, line);

            for (line, 0..) |char, j| {
                if (char == 'S') find_start = [_]usize{ i, j };
            }
        }
        break :blk find_start orelse @panic("No start!\n");
    };

    var current_coord = start;
    var last_dir: ?usize = null;
    var iteration: usize = 0;
    while (true) : (iteration += 1) {
        const current_char = map.items[current_coord[0]][current_coord[1]];
        print("Currently on {c}\n", .{current_char});

        // up, down, left, right
        const get = getU4(current_char);

        for (0..4) |dir| {
            // Check if direction allowed
            if (get & (@as(u4, 1) << @intCast(dir)) == 0) continue;
            print("{c} allowed\n", .{@as(u8, switch (dir) {
                0 => 'R',
                1 => 'L',
                2 => 'D',
                3 => 'U',
                else => unreachable,
            })});

            // Check if backtracking
            const lol = (get & 8 >> 1) | (get & 4 << 1) | (get & 2 >> 1) | (get & 1 << 1);
            if (last_dir) |last| {
                print("Last was {}\n", .{last});
                print("{b:0<4}\n", .{lol});

                if (lol & (@as(u4, 1) << @intCast(dir)) == 0) continue;
                print("Can do!", .{});
            }

            const dir_coord = switch (dir) {
                0 => [2]usize{ current_coord[0], current_coord[1] + 1 },
                1 => [2]usize{ current_coord[0], current_coord[1] - 1 },
                2 => [2]usize{ current_coord[0] + 1, current_coord[1] },
                3 => [2]usize{ current_coord[0] - 1, current_coord[1] },
                else => unreachable,
            };
            const char_at_dir = map.items[dir_coord[0]][dir_coord[1]];

            print("Seeing {c}\n", .{char_at_dir});

            current_coord = dir_coord;
            last_dir = dir;
            break;

            //print("{b:0<4}\n", .{getU4(char_at_dir) ^ 0b0110});
        }

        if (iteration > 5) break;
    }

    _ = &last_dir;
    _ = &current_coord;
}

fn getU4(char: u8) u4 {
    return switch (char) {
        'S' => 0b1111,
        '|' => 0b1100,
        '-' => 0b0011,
        'L' => 0b1001,
        'F' => 0b0101,
        '7' => 0b0110,
        'J' => 0b1010,
        else => unreachable,
    };
}
