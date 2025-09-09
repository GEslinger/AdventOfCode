const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var keys: std.ArrayList([5]u8) = .empty;
    defer keys.deinit(alloc);
    var locks: std.ArrayList([5]u8) = .empty;
    defer locks.deinit(alloc);
    {
        const file = try std.fs.cwd().openFile("mini", .{});
        const contents = try file.readToEndAlloc(alloc, 1_000_000);

        var line_iter = std.mem.splitAny(u8, contents, "\n");
        while (line_iter.next()) |dirty_line| {
            var line = std.mem.trimEnd(u8, dirty_line, "\r");

            if (line.len == 0) continue;

            var new_item = [_]u8{ 0, 0, 0, 0, 0 };
            for (0..6) |_| {
                line = std.mem.trimEnd(u8, line_iter.next().?, "\r");
                for (line, 0..) |char, i| {
                    if (char == '#') new_item[i] += 1;
                }
            }
            if (line[0] == '#') {
                try keys.append(alloc, new_item);
            } else {
                try locks.append(alloc, new_item);
            }
        }
    }

    print("Keys: {any}\n", .{keys.items});
    print("Locks: {any}\n", .{locks.items});
}
