const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    {
        var file = try std.fs.cwd().openFile("input", .{});
        defer file.close();

        const contents = try file.readToEndAlloc(alloc, 1_000_000);

        var lines = std.mem.splitAny(u8, contents, "\n");
        {
            var line_count: usize = 0;
            while (lines.next()) |_| line_count += 1;
            lines.reset();
        }

        var line_num: usize = 0;
        while (lines.next()) |dirty_line| : (line_num += 1) {
            const line = std.mem.trim(u8, dirty_line, "\r");
            _ = line;
        }
    }
}
