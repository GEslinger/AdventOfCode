const std = @import("std");
const print = std.debug.print;

const Stone = struct { val: u128, lvl: u8 };

pub fn main() !void {
    print("Hello, world!\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    var alloc = gpa.allocator();
    defer _ = gpa.deinit();

    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();
    const contents = try file.readToEndAlloc(alloc, 1_000_000);
    defer alloc.free(contents);

    print("Contents:\n{s}\n", .{contents});

    var stones = std.ArrayList(Stone).init(alloc);
    defer stones.deinit();

    {
        var first_stones_strings = std.mem.tokenizeAny(u8, contents, " \n");
        while (first_stones_strings.next()) |stone_string| {
            const new_stone = Stone{ .lvl = 0, .val = std.fmt.parseInt(u128, stone_string, 10) catch break };
            try stones.append(new_stone);
        }
    }

    var counter: usize = 0;
    const limit = 40;
    while (stones.pop()) |stone| {
        //print("{any}", .{stones});

        if (stone.lvl == limit) {
            counter += 1;
            continue;
        }

        if (stone.val == 0) {
            try stones.append(Stone{ .lvl = stone.lvl + 1, .val = 1 });
            continue;
        }

        const power = std.math.log10_int(stone.val) + 1;
        if (power % 2 == 0) { // Even number of digits
            const first_half = stone.val / std.math.pow(u128, 10, power / 2);
            const second_half = stone.val - first_half * std.math.pow(u128, 10, power / 2);
            // print("{} :: {}\n", .{ first_half, second_half });
            try stones.append(Stone{ .lvl = stone.lvl + 1, .val = second_half });
            try stones.append(Stone{ .lvl = stone.lvl + 1, .val = first_half });
            continue;
        }

        try stones.append(Stone{ .lvl = stone.lvl + 1, .val = stone.val * 2024 });
    }

    print("count: {}\n", .{counter});
}
