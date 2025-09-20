const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var seen_comps: std.ArrayList([2]u8) = .empty;
    defer seen_comps.deinit(alloc);

    var adjacency: [][]u64 = undefined;

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
        }
        line_iter.reset();

        // Construct adjacency matrix
        const uniques = seen_comps.items.len;
        adjacency = try alloc.alloc([]u64, uniques);
        for (0..uniques) |i| {
            adjacency[i] = try alloc.alloc(u64, uniques);
            for (0..uniques) |j| {
                adjacency[i][j] = 0;
            }
        }

        // Fill in adjacency matrix
        while (line_iter.next()) |line| {
            var comp_iter = std.mem.tokenizeAny(u8, line, "-");
            const a_id = comp_iter.next().?;
            const b_id = comp_iter.next().?;

            const a = has(a_id, seen_comps).?;
            const b = has(b_id, seen_comps).?;

            adjacency[a][b] += 1;
            adjacency[b][a] += 1;
        }
    }

    //for (seen_comps.items) |comp| print("{s} ", .{comp});
    print("\n", .{});
    //print_2d(adjacency);
    print("\n", .{});

    //var clique_index: std.ArrayList(usize) = .empty;
    //defer clique_index.deinit(alloc);

    const L = struct {
        val: u64,
        exclude: bool = false,
        //node: std.DoublyLinkedList.Node = .{},
    };
    //var clique_buf: [100]L = undefined;
    var clique_index: std.ArrayList(L) = .empty;
    defer clique_index.deinit(alloc);

    var try_clique: std.ArrayList([2]u8) = .empty;
    defer try_clique.deinit(alloc);
    var longest_clique: std.ArrayList([2]u8) = .empty;
    defer longest_clique.deinit(alloc);

    var max_excluded: u64 = 99;

    root: for (adjacency, 0..) |row, i| {
        try_clique.clearRetainingCapacity();
        clique_index.clearRetainingCapacity();
        //var clique_index: std.DoublyLinkedList = .{};
        //var buf_index: usize = 0;
        var edges: u64 = 0;
        for (row, 0..) |val, j| {
            if (val == 1) {
                //clique_buf[buf_index] = L{ .val = j };
                //clique_index.append(&clique_buf[buf_index].node);
                //buf_index += 1;
                try clique_index.append(alloc, L{ .val = j });
                edges += 1;
            }
        }

        var excluded: u64 = 0;
        //print("Root {s}\n", .{seen_comps.items[i]});
        //print("Edges {}\n", .{edges});
        //print("Max exclusions: {}\n", .{max_excluded});
        member: for (clique_index.items) |*clique_member| {
            if (clique_member.exclude) continue;

            //print("\tMember {s}\n", .{seen_comps.items[clique_member.val]});
            for (clique_index.items) |*check_member| {
                if (clique_member.val == check_member.val or
                    clique_member.val == i or
                    check_member.val == i) continue;
                if (check_member.exclude) continue;

                if (adjacency[clique_member.val][check_member.val] != 1) {
                    //print("\t\tExclude!\n", .{});
                    clique_member.exclude = true;
                    excluded += 1;
                    //continue :member;
                    if (excluded > max_excluded) continue :root;
                    continue :member;
                }
            }
            continue :member;
        }
        if (excluded < max_excluded) max_excluded = excluded;

        try try_clique.append(alloc, seen_comps.items[i]);
        for (clique_index.items) |final_member| {
            if (final_member.exclude) continue;
            //print("{s},", .{seen_comps.items[final_member.val]});
            try try_clique.append(alloc, seen_comps.items[final_member.val]);
        }

        if (try_clique.items.len >= longest_clique.items.len) {
            print("\nNew longest! {}\n", .{try_clique.items.len});
            longest_clique.clearAndFree(alloc);
            longest_clique = try try_clique.clone(alloc);
            std.mem.sort([2]u8, longest_clique.items, {}, struct {
                fn lessThan(_: void, a: [2]u8, b: [2]u8) bool {
                    //print("Comparing {s} and {s}\n", .{ a, b });
                    if (a[0] < b[0]) return true;
                    if (a[0] == b[0] and a[1] < b[1]) return true;
                    return false;
                }
            }.lessThan);

            for (longest_clique.items) |clique| print("{s},", .{clique});
            print("\n", .{});
        }
        //print("\nTotal len: {}\n\n", .{size});

    }

    for (longest_clique.items) |clique| print("{s},", .{clique});
    print("\n", .{});
}

//std.mem.sort([2]u8, longest_clique.items, {}, struct {
//    fn lessThan(_: void, a: [2]u8, b: [2]u8) bool {
//        //print("Comparing {s} and {s}\n", .{ a, b });
//        if (a[0] < b[0]) return true;
//        if (a[0] == b[0] and a[1] < b[1]) return true;
//        return false;
//    }
//}.lessThan);

fn get_col(two_d: anytype, idx: usize, col: anytype) void {
    for (two_d, 0..) |row, j| {
        col[j] = row[idx];
    }
}

fn print_2d(two_d: anytype) void {
    for (two_d) |one_d| {
        for (one_d) |value| {
            print("{}  ", .{value});
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
