const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var pos = std.ArrayList([2]i32).init(alloc);
    defer pos.deinit();
    var vel = std.ArrayList([2]i32).init(alloc);
    defer vel.deinit();

    {
        var file = try std.fs.cwd().openFile("input", .{});
        defer file.close();

        const contents = try file.readToEndAlloc(alloc, 1_000_000);
        //print("{s}\n\n", .{contents});

        var lines = std.mem.tokenizeAny(u8, contents, "\r\n");
        while (lines.next()) |line| {
            var nums = std.mem.tokenizeAny(u8, line, "pv,= ");

            try pos.append([2]i32{ try std.fmt.parseInt(i32, nums.next().?, 10), try std.fmt.parseInt(i32, nums.next().?, 10) });
            try vel.append([2]i32{ try std.fmt.parseInt(i32, nums.next().?, 10), try std.fmt.parseInt(i32, nums.next().?, 10) });
        }
    }

    //for (pos.items) |p| print("{any}\n", .{p});

    const steps = 100;
    const bound_x: u32 = 101;
    const bound_y: u32 = 103;

    print("Divisions {}, {}\n", .{ (bound_x - 1) / 2, (bound_y - 1) / 2 });
    var q1: i32, var q2: i32, var q3: i32, var q4: i32 = .{ 0, 0, 0, 0 };
    for (pos.items, vel.items, 0..) |p, v, i| {
        const x = @mod(p[0] + v[0] * steps, bound_x);
        const y = @mod(p[1] + v[1] * steps, bound_y);
        pos.items[i][0] = x;
        pos.items[i][1] = y;

        if (x < (bound_x - 1) / 2 and y < (bound_y - 1) / 2) q1 += 1;
        if (x > (bound_x - 1) / 2 and y < (bound_y - 1) / 2) q2 += 1;
        if (x < (bound_x - 1) / 2 and y > (bound_y - 1) / 2) q3 += 1;
        if (x > (bound_x - 1) / 2 and y > (bound_y - 1) / 2) q4 += 1;
    }
    //print("{} {} {} {}\n", .{ q1, q2, q3, q4 });

    for (0..bound_y) |y| {
        for (0..bound_x) |x| {
            var count: u32 = 0;
            for (pos.items) |p| {
                if (p[0] == x and p[1] == y) count += 1;
            }
            //print("{}", .{count});
        }
        //print("\n", .{});
    }

    print("Total: {}\n", .{q1 * q2 * q3 * q4});
}
