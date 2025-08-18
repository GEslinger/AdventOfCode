const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    print("Hello, world!\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    //var alloc = gpa.allocator();
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var alloc = arena.allocator();

    const file = try std.fs.cwd().openFile("mini", .{});
    defer file.close();
    const contents = try file.readToEndAlloc(alloc, 1_000_000);
    defer alloc.free(contents);

    var regions = std.ArrayList(*Region).init(alloc);
    //var regions = try alloc.create(std.DoublyLinkedList(*Region));
    defer regions.deinit();

    print("Contents:\n{s}\n", .{contents});

    var row: usize = 0;
    var col: usize = 0;
    for (contents) |char| {
        if (char == '\n') {
            row += 1;
            col = 0;
            continue;
        }

        //const a = regions.Node{.data = Region, .next};
        print("Checking {c} at {}, {}\n", .{ char, row, col });

        var new_region = try alloc.create(Region);
        new_region.* = Region.init(char, &alloc);
        try new_region.points.put([2]usize{ row, col }, {});
        if (regions.items.len == 0) {
            try regions.append(new_region);
            continue;
        } else {
            try regions.append(new_region);
        }

        var not_connected = true;
        var remove_idx = std.ArrayList(usize).init(alloc); //FIXME: Should be a hashmap!!!
        defer remove_idx.deinit();
        //var number_merged: u3 = 0;

        for (regions.items[0 .. regions.items.len - 2], 0..) |region, idx| {
            if (region.letter != char) continue;
            print("VS region idx {}, A:{}, P:{}\n", .{ idx, region.area, region.perimeter });

            if (row > 0) {
                if (region.points.getEntry([2]usize{ row - 1, col })) |_| {
                    not_connected = false;
                    print("Connecting up!\n", .{});

                    const merge_result = try new_region.merge(region);
                    print("Confirm I'm A:{} P:{}\n", .{ new_region.area, new_region.perimeter });
                    if (merge_result.@"1") try remove_idx.append(idx);
                    continue;
                }
            }

            if (col > 0) {
                if (region.points.getEntry([2]usize{ row, col - 1 })) |_| {
                    not_connected = false;
                    print("Connecting left!\n", .{});

                    const merge_result = try new_region.merge(region);
                    print("Confirm I'm A:{} P:{}\n", .{ new_region.area, new_region.perimeter });
                    if (merge_result.@"1") try remove_idx.append(idx);
                    continue;
                }
            }

            //if (number_merged == 1) remove_idx = idx;
        }

        std.debug.assert(remove_idx.items.len <= 2);

        for (remove_idx.items) |idx| {
            print("And removing region idx {}!\n", .{idx});
            print("BEFORE\n", .{});
            for (regions.items, 0..) |region, id| print("{}: {c} {} {}\n", .{ id, region.letter, region.area, region.perimeter });
            _ = regions.orderedRemove(idx);
            print("AFTER\n", .{});
            for (regions.items, 0..) |region, id| print("{}: {c} {} {}\n", .{ id, region.letter, region.area, region.perimeter });
        }

        if (not_connected) {
            print("New region\n", .{});
            //try regions.append(new_region);
        }

        col += 1;
    }

    var total_price: u64 = 0;
    for (regions.items) |region| {
        print("Region of {c}, area {}, perimeter {}\n", .{ region.letter, region.area, region.perimeter });
        total_price += region.area * region.perimeter;

        region.deinit();
        alloc.destroy(region);
    }

    print("Total price: {}\n", .{total_price});
}

const Region = struct {
    const Self = @This();

    area: u64 = 1,
    perimeter: u64 = 4,
    letter: u8,
    points: std.AutoHashMap([2]usize, void),
    alloc: *std.mem.Allocator,

    fn init(letter: u8, alloc: *std.mem.Allocator) Self {
        return Self{
            .letter = letter,
            .points = std.AutoHashMap([2]usize, void).init(alloc.*),
            .alloc = alloc,
        };
    }

    fn deinit(self: *Self) void {
        self.points.deinit();
    }

    /// Owns destruction of "other"
    fn merge(self: *Self, other: *Self) !struct { *Self, bool } {
        if (self.area + other.area > 10000) return MergeError.CrapTooBig;

        if (self == other) {
            // Delete virtual edges
            print("literally me!!! :3\n", .{});
            self.perimeter -= 2;
            return .{ self, false };
        }

        var other_point_iter = other.points.iterator();
        while (other_point_iter.next()) |other_point| {
            try self.points.put(other_point.key_ptr.*, {});
        }

        self.area += other.area;
        self.perimeter += other.perimeter - 2;

        print("now I'm A:{} P:{}\n", .{ self.area, self.perimeter });

        //other.points.deinit();
        //other.alloc.destroy(other);

        return .{ self, true };
    }
};

const MergeError = error{
    CrapTooBig,
};
