const std = @import("std");
const print = std.debug.print;
const aoc = @import("aoc");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var lines = try aoc.inputLineIterator(alloc);
    defer alloc.free(lines.contents);

    var id: u64 = 1;
    var sum: u64 = 0;
    var total_power: u64 = 0;
    while (lines.next()) |line| : (id += 1) {
        //print("{s}\n", .{line});

        const id_removed = std.mem.trimStart(u8, line, "Game 0123456789");
        var game_iter = std.mem.tokenizeAny(u8, id_removed, ":;");
        var possible = true;
        var max = [_]u64{ 0, 0, 0 };
        while (game_iter.next()) |game| {
            //print("{s}\n", .{game});
            var steps = std.mem.tokenizeAny(u8, game, ",");
            while (steps.next()) |step| {
                //print("{s}\n", .{step});
                var info = std.mem.tokenizeAny(u8, step, " ");
                const num = try std.fmt.parseInt(u64, info.next().?, 10);
                const color = info.next().?[0];
                const threshold: u64 = switch (color) {
                    'r' => 12,
                    'g' => 13,
                    'b' => 14,
                    else => unreachable,
                };

                //print("Comparing {} and {}\n", .{ num, threshold });
                if (num > threshold) possible = false;

                if (color == 'r' and num > max[0]) max[0] = num;
                if (color == 'g' and num > max[1]) max[1] = num;
                if (color == 'b' and num > max[2]) max[2] = num;
            }
        }

        total_power += max[0] * max[1] * max[2];

        if (possible) sum += id;
    }

    print("Sum of possible IDs (Part 1): {}\n", .{sum});
    print("Total power of games (Part 2): {}\n", .{total_power});
}
