const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var seen_comps: std.ArrayList([2]u8) = .empty;
    defer seen_comps.deinit(alloc);

    var adjacency: [][]i8 = undefined;
    var result: [][]i8 = undefined;

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
        }
        line_iter.reset();

        // Construct adjacency matrix
        const uniques = seen_comps.items.len;
        adjacency = try alloc.alloc([]i8, uniques);
        result = try alloc.alloc([]i8, uniques);
        for (0..uniques) |i| {
            adjacency[i] = try alloc.alloc(i8, uniques);
            result[i] = try alloc.alloc(i8, uniques);
            for (0..uniques) |j| {
                adjacency[i][j] = 0;
                result[i][j] = 0;
            }
        }

        // Fill in adjacency matrix
        while (line_iter.next()) |line| {
            var comp_iter = std.mem.tokenizeAny(u8, line, "-");
            const a = has(comp_iter.next().?, seen_comps).?;
            const b = has(comp_iter.next().?, seen_comps).?;

            adjacency[a][b] += 1;
            adjacency[b][a] += 1;
        }
    }

    for (seen_comps.items) |comp| print(" {s}", .{comp});
    print("\n", .{});
    print_2d(adjacency);
    print("\n", .{});

    const col = try alloc.alloc(i8, seen_comps.items.len);

    // WARN: MATRIX MULTIPLICATION
    get_col(adjacency, 15, col);
    print("{any}\n", .{col});

    for (0..3) |power| {
        for (adjacency, 0..) |row, i| {
            for (row, 0..) |value, j| {
                var total: i8 = 0;

                result[i][j] = 
            }
        }

        @memcpy(adjacency, result);
    }
}

fn get_col(two_d: anytype, idx: usize, col: anytype) void {
    for (two_d, 0..) |row, j| {
        col[j] = row[idx];
    }
}

fn print_2d(two_d: anytype) void {
    for (two_d) |one_d| {
        print("{any}\n", .{one_d});
    }
}

fn has(a: anytype, b_list: anytype) ?usize {
    for (b_list.items, 0..) |b, i| {
        if (a[0] == b[0] and a[1] == b[1]) return i;
    }
    return null;
}
