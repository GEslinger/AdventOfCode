const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var towels = std.StringHashMap(void).init(alloc);
    defer towels.deinit();
    var combos: std.ArrayList([]const u8) = .empty;
    defer combos.deinit(alloc);

    {
        const file = try std.fs.cwd().openFile("input", .{});
        defer file.close();
        const contents = try file.readToEndAlloc(alloc, 1_000_000);

        var lines = std.mem.tokenizeAny(u8, contents, "\r\n");
        var towels_iter = std.mem.tokenizeAny(u8, lines.next().?, ", ");
        while (towels_iter.next()) |new_towel| try towels.put(new_towel, {});

        while (lines.next()) |combo| try combos.append(alloc, combo);
    }

    {
        //var towels_iter = towels.iterator();
        //while (towels_iter.next()) |towel| print("{s}, ", .{towel.key_ptr.*});
        //print("\n", .{});
    }

    var search_tree: std.ArrayList([2]usize) = .empty;
    defer search_tree.deinit(alloc);

    var possible: usize = 0;
    for (combos.items) |combo| {
        print("{s}\n", .{combo});

        var start: usize = 0;
        var end: usize = combo.len;
        const p: bool = while (start < combo.len) : (end -= 1) {
            if (end <= start) {
                if (search_tree.pop()) |idxs| {
                    print("New end\n", .{});
                    start = idxs[0];
                    end = idxs[1];
                    continue;
                } else {
                    break false;
                }
            }
            const slice = combo[start..end];
            print("Check slice {s}\n", .{slice});
            if (towels.contains(slice)) {
                print("Got it!\n", .{});
                try search_tree.append(alloc, [_]usize{ start, end });
                start = end;
                end = combo.len + 1;
            }
        } else true;

        if (p) {
            print("Possible!\n", .{});
            possible += 1;
        } else {
            print("Not possible.\n", .{});
        }

        search_tree.clearRetainingCapacity();
    }

    print("Total possible: {}\n", .{possible});
}
