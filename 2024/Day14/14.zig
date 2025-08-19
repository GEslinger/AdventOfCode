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

    var steps: i32 = 0;
    const bound_x: u32 = 101;
    const bound_y: u32 = 103;
    var max_neighbors: u64 = 0;

    while (steps < 100_000) : (steps += 1) {
        for (pos.items, vel.items, 0..) |p, v, i| {
            const x = @mod(p[0] + v[0], bound_x);
            const y = @mod(p[1] + v[1], bound_y);
            pos.items[i][0] = x;
            pos.items[i][1] = y;
        }

        var neighbors: u64 = 0;
        for (pos.items) |p1| {
            for (pos.items) |p2| {
                const dev_x: u32 = @intCast(@max(p1[0], p2[0]) - @min(p1[0], p2[0]));
                const dev_y: u32 = @intCast(@max(p1[1], p2[1]) - @min(p1[1], p2[1]));
                if (dev_x == 1 or dev_y == 1) neighbors += 1;
            }
        }
        if (neighbors > max_neighbors) {
            max_neighbors = neighbors;
            print("{} STEPS\n", .{steps + 1});
            print("{} NEIGHBORS\n", .{neighbors});

            for (0..bound_y) |y| {
                for (0..bound_x) |x| {
                    var count: u32 = 0;
                    for (pos.items) |p| {
                        if (p[0] == x and p[1] == y) count += 1;
                    }
                    if (count == 0) {
                        print(".", .{});
                    } else {
                        print("{}", .{count});
                    }
                }
                print("\n", .{});
            }
        }

        //std.time.sleep(1_000_000_00);
    }
}
