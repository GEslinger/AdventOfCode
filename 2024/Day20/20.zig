const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var map: [][]u8 = undefined;
    var current = @Vector(2, usize){ 0, 0 };
    var end = @Vector(2, usize){ 0, 0 };

    {
        const file = try std.fs.cwd().openFile("mini", .{});
        defer file.close();
        const contents = try file.readToEndAlloc(alloc, 1_000_000);

        var lines = std.mem.tokenizeAny(u8, contents, "\r\n");
        var line_count: usize = 0;
        while (lines.next()) |_| line_count += 1;
        lines.reset();

        map = try alloc.alloc([]u8, line_count);
        var row: usize = 0;
        while (lines.next()) |line| : (row += 1) {
            map[row] = try alloc.alloc(u8, line.len);
            @memcpy(map[row], line);
            for (line, 0..) |char, col| {
                if (char == 'S') current = @Vector(2, usize){ row, col };
                if (char == 'E') end = @Vector(2, usize){ row, col };
            }
        }
    }

    //for (map) |line| {
    //    print("{s}\n", .{line});
    //}

    //print("Start {}, End {}\n", .{ current, end });

    var path = std.AutoHashMap(@Vector(2, usize), u64).init(alloc);
    defer path.deinit();
    var time: u64 = 0;
    try path.put(current, time);

    race: while (map[current[0]][current[1]] != 'E') {
        for (neighbors(map, current)) |maybe_n| {
            if (maybe_n) |n| {
                if (map[n[0]][n[1]] != '#' and !path.contains(n)) {
                    time += 1;
                    try path.put(n, time);
                    current = n;
                    continue :race;
                }
            }
        }
    }

    //print("End node: {any}ps.\nTime to cheat!\n", .{path.get(end)});

    var cheats = std.AutoHashMap(@Vector(4, usize), u64).init(alloc);
    defer cheats.deinit();
    var c_tree: std.ArrayList(Node) = .empty;
    var c_tree_seen = std.AutoHashMap(@Vector(2, usize), u64).init(alloc);
    defer c_tree.deinit(alloc);

    var path_iter = path.iterator();
    while (path_iter.next()) |node| {
        const t_start = node.value_ptr.*;
        const pos_start = node.key_ptr.*;
        print("Starting {}\n", .{pos_start});

        for (neighbors(map, pos_start)) |n_opt| {
            if (n_opt) |n| {
                if (map[n[0]][n[1]] == '#') {
                    try c_tree.append(alloc, Node{ .pos = n, .len = 1 });
                }
            }
        }

        while (c_tree.pop()) |c_node| {
            //print("Popped investigating {}\n", .{c_node.pos});
            if (c_node.len > 20) continue;

            if (map[c_node.pos[0]][c_node.pos[1]] != '#') {
                const t_end = path.get(c_node.pos).?;
                if (t_start + c_node.len >= t_end) continue;
                const savings = t_end - (t_start + c_node.len);
                print("Valid cheat starting {} ending at {} saving {}\n", .{ pos_start, c_node.pos, savings });
                const entry = try cheats.getOrPut(@Vector(4, usize){ pos_start[0], pos_start[1], c_node.pos[0], c_node.pos[1] });
                if (entry.found_existing) {
                    //print("It's already there, updating savings\n", .{});
                    if (entry.value_ptr.* < savings) entry.value_ptr.* = savings;
                } else {
                    entry.value_ptr.* = savings;
                }

                continue;
            }

            for (neighbors(map, c_node.pos)) |n_opt| {
                if (n_opt) |n| {
                    if (c_tree_seen.contains(n)) {
                        if (c_tree_seen.get(n).? < c_node.len + 1) continue;
                    }
                    //print("Gonna add neighbor {}\n", .{n});
                    try c_tree.append(alloc, Node{ .pos = n, .len = c_node.len + 1 });
                    try c_tree_seen.put(n, c_node.len + 1);
                }
            }
        }

        c_tree_seen.clearRetainingCapacity();
    }

    var total: u64 = 0;
    var c_iter = cheats.valueIterator();
    while (c_iter.next()) |val| {
        if (val.* == 72) total += 1;
    }

    print("Total: {}\n", .{total});
}

const Node = struct {
    pos: @Vector(2, usize),
    len: u64,
};

fn neighbors(map: [][]u8, coords: @Vector(2, usize)) [4]?@Vector(2, usize) {
    const y, const x = coords;
    var out = [_]?@Vector(2, usize){ null, null, null, null };
    if (x > 0) out[0] = @Vector(2, usize){ y, x - 1 };
    if (y > 0) out[1] = @Vector(2, usize){ y - 1, x };
    if (x < map[y].len - 1) out[2] = @Vector(2, usize){ y, x + 1 };
    if (y < map.len - 1) out[3] = @Vector(2, usize){ y + 1, x };

    return out;
}
