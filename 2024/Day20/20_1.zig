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
        const file = try std.fs.cwd().openFile("input", .{});
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

    var cheats: std.ArrayList(u64) = .empty; // Savings
    defer cheats.deinit(alloc);

    var path_iter = path.iterator();
    while (path_iter.next()) |node| {
        const time_start = node.value_ptr.*;
        for (neighbors(map, node.key_ptr.*)) |c_1_opt| {
            if (c_1_opt) |c_1| {
                if (map[c_1[0]][c_1[1]] != '#') continue;
                for (neighbors(map, c_1)) |c_2_opt| {
                    if (c_2_opt) |c_2| {
                        if (path.get(c_2)) |time_end| {
                            if (time_end <= time_start + 2) continue;
                            const savings = time_end - time_start - 2;
                            //print("Valid cheat saving {} ps: {} -> {} -> {}\n", .{ savings, node.key_ptr.*, c_1, c_2 });
                            try cheats.append(alloc, savings);
                        }
                    }
                }
            }
        }
    }

    std.mem.sort(u64, cheats.items, {}, std.sort.desc(u64));
    var total: u64 = 0;
    for (cheats.items) |cheat| {
        if (cheat >= 100) total += 1;
    }
    //print("All cheats: {any}\n", .{cheats.items});
    print("Total: {}\n", .{total});
}

fn neighbors(map: [][]u8, coords: @Vector(2, usize)) [4]?@Vector(2, usize) {
    const y, const x = coords;
    var out = [_]?@Vector(2, usize){ null, null, null, null };
    if (x > 0) out[0] = @Vector(2, usize){ y, x - 1 };
    if (y > 0) out[1] = @Vector(2, usize){ y - 1, x };
    if (x < map[y].len - 1) out[2] = @Vector(2, usize){ y, x + 1 };
    if (y < map.len - 1) out[3] = @Vector(2, usize){ y + 1, x };

    return out;
}
