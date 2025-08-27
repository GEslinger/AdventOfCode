const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var map: [][]u8 = undefined;

    {
        const file = try std.fs.cwd().openFile("input", .{});
        defer file.close();
        const contents = try file.readToEndAlloc(alloc, 1_000_000);

        var lines = std.mem.tokenizeAny(u8, contents, "\r\n");
        var line_count: usize = 0;
        while (lines.next()) |_| line_count += 1;
        lines.reset();

        map = alloc.alloc([]u8, line_count);
    }
}
