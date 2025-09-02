const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var seen_comps: std.ArrayList([2]u8) = .empty;
    defer seen_comps.deinit(alloc);

    var adjacency: [][]D = undefined;

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
        adjacency = try alloc.alloc([]D, uniques);
        for (0..uniques) |i| {
            adjacency[i] = try alloc.alloc(D, uniques);
            for (0..uniques) |j| {
                adjacency[i][j] = D{ .num = 0, .t_count = 0 };
            }
        }

        // Fill in adjacency matrix
        while (line_iter.next()) |line| {
            var comp_iter = std.mem.tokenizeAny(u8, line, "-");
            const a_id = comp_iter.next().?;
            const b_id = comp_iter.next().?;

            const a = has(a_id, seen_comps).?;
            const b = has(b_id, seen_comps).?;

            adjacency[a][b].num += 1;
            adjacency[b][a].num += 1;
            if (a_id[0] == 't' or b_id[0] == 't') {
                adjacency[a][b].t_count += 1;
                adjacency[b][a].t_count += 1;
            }
        }
    }

    for (seen_comps.items) |comp| print(" {s}", .{comp});
    print("\n", .{});
    print_2d(adjacency);
    print("\n", .{});

    // Matrices for storing intermediate values
    var result: [][]D = try alloc.alloc([]D, adjacency.len);
    var inter: [][]D = try alloc.alloc([]D, adjacency.len);
    for (adjacency, 0..) |_, i| {
        result[i] = try alloc.alloc(D, adjacency[i].len);
        inter[i] = try alloc.alloc(D, adjacency[i].len);
        @memcpy(result[i], adjacency[i]);
        //@memcpy(inter[i], adjacency[i]);
    }

    // WARN: MATRIX MULTIPLICATION

    const col = try alloc.alloc(D, adjacency.len);
    for (0..2) |_| {
        for (result, 0..) |row, i| {
            for (row, 0..) |_, j| {
                get_col(adjacency, j, col);
                var total = D{};
                for (row, col, 0..) |a, b, n| {
                    _ = n;
                    //print("This one: {}", .{seen_comps.items[n]});
                    //print("i: {}, j: {}, a: {}, b:{}\n", .{ i, j, a, b });
                    //total.t_count += a.t_count + b.t_count;
                    total.num += a.num * b.num;
                }

                inter[i][j] = total;
            }
        }

        // Deep copy
        for (inter, 0..) |_, i| {
            @memcpy(result[i], inter[i]);
        }
        print_2d(result);
        print("\n", .{});
    }

    // Getting "trace"
    var trace: i64 = 0;
    for (result, 0..) |_, i| {
        if (seen_comps.items[i][0] == 't') {
            trace += result[i][i].num;
        }
    }

    print("Trace: {}\n", .{trace});
    print("Answer: {}\n", .{@divTrunc(trace, 2)});
}

const D = struct {
    num: i64 = 0,
    t_count: i64 = 0,
};

fn get_col(two_d: anytype, idx: usize, col: anytype) void {
    for (two_d, 0..) |row, j| {
        col[j] = row[idx];
    }
}

fn print_2d(two_d: anytype) void {
    for (two_d) |one_d| {
        for (one_d) |value| {
            print("{} ", .{value.num});
            //print("{}, ", .{value.num});
        }
        print("\n", .{});
    }
}

fn has(a: anytype, b_list: anytype) ?usize {
    for (b_list.items, 0..) |b, i| {
        if (a[0] == b[0] and a[1] == b[1]) return i;
    }
    return null;
}
