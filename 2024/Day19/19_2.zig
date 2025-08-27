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

    // DYNAMIC PROGRAMMING >:O
    var dyn: std.ArrayList(usize) = .empty;
    defer dyn.deinit(alloc);

    //var possible: usize = 0;
    var total_ways: usize = 0;
    for (combos.items) |combo| {
        //print("{s}\n", .{combo});

        try dyn.appendNTimes(alloc, 0, combo.len + 1);
        dyn.items[0] = 1; // Base case

        for (1..combo.len + 1) |end| {
            for (0..end) |start| {
                const slice = combo[start..end];
                //print("Checking slice {}..{}: {s}\n", .{ start, end, slice });
                if (towels.contains(slice)) {
                    //print("Got one! Adding {} slices that end at {}\n", .{ dyn.items[start], end });
                    dyn.items[end] += dyn.items[start];
                }
            }
            //print("Total for {}: {}\n", .{ end, dyn.items[end] });
        }

        //print("Ways for this combo: {}\n", .{dyn.getLast()});
        //print("{any}\n", .{dyn.items});
        total_ways += dyn.getLast();
        dyn.clearRetainingCapacity();
    }

    print("Total ways to do it: {}\n", .{total_ways});
}
