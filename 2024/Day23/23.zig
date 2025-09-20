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
        var file = try std.fs.cwd().openFile("input", .{});
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
            var link: Link = undefined;
            link.a = seen_comps.items[has(comp_iter.next().?, seen_comps).?];
            link.b = seen_comps.items[has(comp_iter.next().?, seen_comps).?];
            try links.append(alloc, link);
        }
    }

    print("Total links: {}\nTotal computers: {}\n", .{ links.items.len, seen_comps.items.len });

    var total: u64 = 0;
    for (links.items[0..], 0..) |link1, a| {
        for (links.items[0..a], 0..) |link2, b| {
            const others = link1.otherLinkEnds(link2) orelse continue;
            for (links.items[0..b], 0..) |link3, c| {
                _ = c;
                if (!link3.equal(others)) continue;
                if (link1.a[0] == 't' or link1.b[0] == 't' or
                    link2.a[0] == 't' or link2.b[0] == 't' or
                    link3.a[0] == 't' or link3.b[0] == 't')
                {
                    total += 1;
                }
            }
        }
    }

    print("Total: {}\n", .{total});
}

const Link = struct {
    a: [2]u8,
    b: [2]u8,
    fn equal(self: Link, other: Link) bool {
        return ((std.mem.eql(u8, &self.a, &other.a) and std.mem.eql(u8, &self.b, &other.b)) or
            (std.mem.eql(u8, &self.a, &other.b) and std.mem.eql(u8, &self.b, &other.a)));
    }

    fn otherLinkEnds(self: Link, other: Link) ?Link {
        //if (equal(self, other)) return null;

        if (std.mem.eql(u8, &self.a, &other.a)) return Link{ .a = self.b, .b = other.b };
        if (std.mem.eql(u8, &self.b, &other.a)) return Link{ .a = self.a, .b = other.b };
        if (std.mem.eql(u8, &self.a, &other.b)) return Link{ .a = self.b, .b = other.a };
        if (std.mem.eql(u8, &self.b, &other.b)) return Link{ .a = self.a, .b = other.a };

        return null;
    }
};

fn has(a: anytype, b_list: anytype) ?usize {
    for (b_list.items, 0..) |b, i| {
        if (a[0] == b[0] and a[1] == b[1]) return i;
    }
    return null;
}
