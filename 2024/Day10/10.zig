const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

var routes: u64 = 0;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const alloc = gpa.allocator();

    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();
    const contents = try file.readToEndAlloc(alloc, 1_000_000);

    var ends = std.AutoHashMap([2]u64, void).init(alloc);
    defer ends.deinit();
    var starts = std.ArrayList([2]u64).init(alloc);
    defer starts.deinit();

    var map: [][]u64 = undefined;

    var lines = std.mem.tokenizeAny(u8, contents, "\n");

    const num_rows = blk: {
        var rows: usize = 0;
        while (lines.next()) |_| : (rows += 1) {} else {
            lines.reset();
            break :blk rows;
        }
    };

    map = try alloc.alloc([]u64, num_rows);
    {
        var row: usize = 0;
        while (lines.next()) |line| : (row += 1) {
            map[row] = try alloc.alloc(u64, line.len);

            for (line, 0..) |char, col| {
                switch (char) {
                    '0' => try starts.append([_]u64{ row, col }),
                    '1'...'9' => {},
                    //'9' => try ends.put([_]u64{ row, col }, {}),
                    else => continue,
                }

                map[row][col] = char - '0';
            }
        }
    }

    defer {
        for (map, 0..) |_, row| {
            alloc.free(map[row]);
        }
        alloc.free(map);
    }

    var points = std.ArrayList([2]u64).init(alloc);
    defer points.deinit();

    var total: u64 = 0;
    for (starts.items) |start| {
        //print("Startin at row {} column {}...", .{ start[0], start[1] });
        try points.append(start);
        while (points.items.len > 0) {
            inline for (@typeInfo(Dir).@"enum".fields) |dir| {
                if (try takeNextStep(points.items[0], @enumFromInt(dir.value), map, &ends, &points)) break;
            }

            _ = points.orderedRemove(0);
        }

        //print("Score: {}\n", .{ends.count()});
        total += ends.count();
        ends.clearRetainingCapacity();
        points.clearRetainingCapacity();
    }

    print("Total score: {}.\n", .{total});
    print("Total routes: {}.\n", .{routes});
}

fn takeNextStep(point: [2]u64, dir: Dir, map: [][]u64, ends: *std.AutoHashMap([2]u64, void), points: *std.ArrayList([2]u64)) !bool {
    const point_val = map[point[0]][point[1]];
    if (point_val == 9) {
        //print("{any}\n", .{points.items});
        //print("Now found a 9!!! at r{} c{}\n", .{ point[0], point[1] });
        _ = try ends.getOrPut(point);
        routes += 1;
        return true;
    }

    // Bounds Check
    switch (dir) {
        Dir.Right => if (point[1] >= map[point[0]].len - 1) return false,
        Dir.Down => if (point[0] >= map.len - 1) return false,
        Dir.Left => if (point[1] <= 0) return false,
        Dir.Up => if (point[0] <= 0) return false,
    }

    const next_point: [2]u64 = switch (dir) {
        Dir.Right => [2]u64{ point[0], point[1] + 1 },
        Dir.Down => [2]u64{ point[0] + 1, point[1] },
        Dir.Left => [2]u64{ point[0], point[1] - 1 },
        Dir.Up => [2]u64{ point[0] - 1, point[1] },
    };

    if (map[next_point[0]][next_point[1]] == point_val + 1) {
        //print("Value {} at r{} c{}, going {s}\n", .{ point_val, point[0], point[1], @tagName(dir) });
        try points.append(next_point);
    }

    return false;
}

const Dir = enum {
    Right,
    Down,
    Left,
    Up,
};
