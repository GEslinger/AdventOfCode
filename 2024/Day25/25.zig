const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var keys: std.ArrayList(@Vector(5, u8)) = .empty;
    defer keys.deinit(alloc);
    var locks: std.ArrayList(@Vector(5, u8)) = .empty;
    defer locks.deinit(alloc);
    {
        const file = try std.fs.cwd().openFile("input", .{});
        const contents = try file.readToEndAlloc(alloc, 1_000_000);

        var line_iter = std.mem.splitAny(u8, contents, "\n");
        while (line_iter.peek()) |_| {
            var line: []const u8 = undefined;

            // Discard 1
            _ = line_iter.next();

            var new_item = [_]u8{ 0, 0, 0, 0, 0 };
            for (0..5) |_| {
                line = std.mem.trimEnd(u8, line_iter.next().?, "\r");
                //print("{s}\n", .{line});
                for (line, 0..) |char, i| {
                    if (char == '#') new_item[i] += 1;
                }
            }

            if (line_iter.next()) |l| {
                if (l[0] == '#') {
                    try keys.append(alloc, new_item);
                } else {
                    try locks.append(alloc, new_item);
                }

                _ = line_iter.next();
            }
        }
    }

    //print("Keys: {any}\n", .{keys.items});
    //print("Locks: {any}\n", .{locks.items});

    const threshold: @Vector(5, u8) = @splat(5);
    var total: usize = 0;
    for (locks.items) |lock| {
        k: for (keys.items) |key| {
            if (!@reduce(.And, (lock + key) <= threshold)) continue :k;
            total += 1;
        }
    }

    print("Total: {}\n", .{total});
}
