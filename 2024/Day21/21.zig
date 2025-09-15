const std = @import("std");
const print = std.debug.print;
const Limit = 8;

// NOTE: Approach:
// I think the best way to do this may
// involve a bottom-up thing, starting with
// the numpad. As in, figure out every path
// with the minimal distance between two
// points on the numpad. Then find the same deal
// for each directional keypad up the chain?
// Maybe all but the shortest can be pruned at
// the next level up.

const numpad = [4][3]u8{
    [3]u8{ '7', '8', '9' },
    [3]u8{ '4', '5', '6' },
    [3]u8{ '1', '2', '3' },
    [3]u8{ 'X', '0', 'A' },
};

const keypad = [2][3]u8{
    [3]u8{ 'X', '^', 'A' },
    [3]u8{ '<', 'v', '>' },
};

const PathPart = struct {
    path: [Limit]u8 = @splat(0),
    next: std.ArrayList(usize) = .empty,
    level: usize,

    fn pathSlice(self: *PathPart) []u8 {
        return self.path[0..pathLength(&self.path)];
    }
};

pub fn main() !void {
    print("Hello, world!\n", .{});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var parts: std.ArrayList(PathPart) = .empty;
    var paths: std.ArrayList(std.ArrayList(u8)) = .empty;
    //var paths: std.ArrayList(std.ArrayList(u8)) = .empty;

    //print("{any}\n", .{paths.items[0].path});
    //

    //try pathsAToB(numpad, 'A', '<', &paths, alloc);

    var seq = "029A";

    print("\n\n", .{});
    for (seq[0..(seq.len - 1)], seq[1..], 0..) |from, to, level| {
        try pathsAToB(numpad, from, to, &parts, alloc, level);
    }
    for (parts.items) |part| {
        print("Level {}: {s}\n", .{ part.level, part.path });
    }
    
    for (parts.items) |*part| {
        if (part.level == 0) {
            for (paths.items) |path| {
                paths.
            }
            var path_begin: std.ArrayList(u8) = .empty;
            try path_begin.appendSlice(alloc, part.pathSlice());
            try paths.append(alloc, path_begin);
        }

        current_level = part.level;
    }
}

fn pathsAToB(
    arr: anytype,
    a: u8,
    b: u8,
    parts: *std.ArrayList(PathPart),
    alloc: std.mem.Allocator,
    level: usize,
) !void {
    print("trying to find {c} to {c}\n", .{ a, b });
    const Point = struct {
        x: usize,
        y: usize,
        path: [Limit]u8 = @splat(0),
        node: std.DoublyLinkedList.Node = .{},
    };

    const max_row = arr.len;
    const max_col = arr[0].len;

    var start_opt: ?Point = null;

    for (arr, 0..) |row, i| {
        for (row, 0..) |char, j| {
            if (char == a) start_opt = Point{ .y = i, .x = j };
        }
    }

    var start = start_opt orelse return E.NoStart;

    var search_tree: std.DoublyLinkedList = .{};
    search_tree.append(&start.node);
    // WARN: FIX IF NOT USING ARENA ALLOCATOR
    //defer {
    //    var delete_node = search_tree.first;
    //    while (delete_node) |node| : (delete_node = node.next) {
    //        alloc.destroy(node)
    //    }
    //}

    // Breadth first search
    var best_path_len: usize = Limit;
    while (search_tree.popFirst()) |node| {
        const point: *Point = @fieldParentPtr("node", node);

        // Filtering
        const len = pathLength(&point.path);
        if (arr[point.y][point.x] == 'X') continue;
        if (len > best_path_len) continue;

        // Return condition
        if (arr[point.y][point.x] == b) {
            print("FOUND: {c} x: {}, y: {}, path: {s}\n", .{ b, point.x, point.y, point.path });
            const new_part = PathPart{ .path = point.path, .level = level };
            try parts.append(alloc, new_part);
            best_path_len = len;
            continue;
        }

        // Add more
        if (point.x > 0) {
            var new_pt = try alloc.create(Point);
            new_pt.* = Point{
                .path = point.path,
                .x = point.x - 1,
                .y = point.y,
            };
            addToPath(&new_pt.path, '<') catch continue;
            //print("new point: x: {}, y: {}, path: {s}\n", .{ new_pt.x, new_pt.y, new_pt.path });
            search_tree.append(&new_pt.node);
        }
        if (point.y > 0) {
            var new_pt = try alloc.create(Point);
            new_pt.* = Point{
                .path = point.path,
                .x = point.x,
                .y = point.y - 1,
            };
            addToPath(&new_pt.path, '^') catch continue;
            //print("new point: x: {}, y: {}, path: {s}\n", .{ new_pt.x, new_pt.y, new_pt.path });
            search_tree.append(&new_pt.node);
        }
        if (point.x < max_col - 1) {
            var new_pt = try alloc.create(Point);
            new_pt.* = Point{
                .path = point.path,
                .x = point.x + 1,
                .y = point.y,
            };
            addToPath(&new_pt.path, '>') catch continue;
            //print("new point: x: {}, y: {}, path: {s}\n", .{ new_pt.x, new_pt.y, new_pt.path });
            search_tree.append(&new_pt.node);
        }
        if (point.y < max_row - 1) {
            var new_pt = try alloc.create(Point);
            new_pt.* = Point{
                .path = point.path,
                .x = point.x,
                .y = point.y + 1,
            };
            addToPath(&new_pt.path, 'v') catch continue;
            //print("new point: x: {}, y: {}, path: {s}\n", .{ new_pt.x, new_pt.y, new_pt.path });
            search_tree.append(&new_pt.node);
        }
    }
}

fn pathLength(path: *[Limit]u8) usize {
    for (path, 0..) |value, i| if (value == 0) return i;
    return Limit;
}

fn addToPath(path: *[Limit]u8, new: u8) !void {
    for (path) |*value| {
        if (value.* == 0) {
            value.* = new;
            return;
        }
    }

    return E.PathTooLong;
}

const E = error{ PathTooLong, NoStart };
