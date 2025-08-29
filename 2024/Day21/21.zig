const std = @import("std");
const print = std.debug.print;

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
    printPad(numpad);
    print("\n", .{});
    printPad(keypad);
}

fn printPad(pad: anytype) void {
    for (pad) |row| {
        for (row) |val| {
            defer print("\t", .{});
            if (val == 'X') continue;
            print("{}", .{val});
        }
        print("\n", .{});
    }
}
