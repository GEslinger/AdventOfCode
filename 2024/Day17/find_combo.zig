const std = @import("std");

pub fn main() void {
    var b: u3 = 0;
    var c: u3 = 0;

    var done = false;
    while (!done) : (b +%= 1) {
        while (c < std.math.maxInt(u3)) : (c += 1) {
            std.debug.print("Checking b: {}, c:{}\n", .{ b, c });
            if (b ^ c == 6 and c == @as(u64, 32) >> b) {
                done = true;
                break;
            }
        }
        c = 0;
    }

    std.debug.print("Success!\n", .{});
}
