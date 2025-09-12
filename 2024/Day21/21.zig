const std = @import("std");
const print = std.debug.print;

// NOTE: Approach:
// I think the best way to do this may
// involve a bottom-up thing, starting with
// the numpad. As in, figure out every path
// with the minimal distance between two
// points on the numpad. Then find the same deal
// for each directional keypad up the chain?
// Maybe all but the shortest can be pruned at
// the next level up.

const numpad = [4][3]u8{
    [3]u8{ 7, 8, 9 },
    [3]u8{ 4, 5, 6 },
    [3]u8{ 1, 2, 3 },
    [3]u8{ 'X', 0, 'A' },
};

const keypad = [2][3]u8{
    [3]u8{ 'X', '^', 'A' },
    [3]u8{ '<', 'v', '>' },
};

pub fn main() void {
    print("Hello, world!\n", .{});
}
