const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var seen_comps: std.ArrayList([2]u8) = .empty;
    defer seen_comps.deinit(alloc);
    var links: std.ArrayList(Link) = .empty;
    defer links.deinit(alloc);

    {
        var file = try std.fs.cwd().openFile("mini", .{});
        defer file.close();
        const contents = try file.readToEndAlloc(alloc, 1_000_000);

        var line_iter = std.mem.tokenizeAny(u8, contents, "\r\n");
        var line_count: usize = 0;
        while (line_iter.next()) |line| : (line_count += 1) {
            var comp_iter = std.mem.tokenizeAny(u8, line, "-");
            while (comp_iter.next()) |comp| {
                const a = [2]u8{ comp[0], comp[1] };

                if (has(a, seen_comps) == null) try seen_comps.append(alloc, a);
            }

            comp_iter.reset();
            const link = 
        }
        line_iter.reset();
    }

    for (seen_comps.items) |comp| print(" {s}", .{comp});
    print("\n", .{});
}

const Link = struct {
    a: *anyopaque,
    b: *anyopaque,
    fn equal(self: Link, other: Link) bool {
        if (self.a == other.a and self.b == other.b) return true;
        if (self.a == other.b and self.b == other.a) return true;
        return false;
    }
};

fn has(a: anytype, b_list: anytype) ?usize {
    for (b_list.items, 0..) |b, i| {
        if (a[0] == b[0] and a[1] == b[1]) return i;
    }
    return null;
}
