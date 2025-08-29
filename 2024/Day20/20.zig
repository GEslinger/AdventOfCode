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

    print("End node: {any}ps.\nTime to cheat!\n", .{path.get(end)});
    print("Bounds: 0,0 to {}, {}\n", .{ map.len, map[0].len });

    // NOTE: JUST FIND ALL POINTS ON PATH WITHIN X+Y <= 20??? CAN WE CHEAT OVERTOP A PATH?
    var cheats: std.ArrayList(u64) = .empty;
    defer cheats.deinit(alloc);

    var path_iter = path.iterator();
    while (path_iter.next()) |start_entry| {
        const p_pos = start_entry.key_ptr.*;
        //print("Starting at {}\n", .{p_pos});
        const start_time = start_entry.value_ptr.*;

        for (0..41) |y_step| {
            const y_off = blk: {
                const tmp: i64 = @intCast(y_step);
                break :blk tmp - 20;
            };
            for (0..41) |x_step| {
                const x_off = blk: {
                    const tmp: i64 = @intCast(x_step);
                    break :blk tmp - 20;
                };

                if (y_off == 0 and x_off == 0) continue;
                if (@abs(y_off) + @abs(x_off) > 20) continue;

                if (-y_off > p_pos[0] or y_off > map.len - 1 - p_pos[0]) continue;
                if (-x_off > p_pos[1] or x_off > map[0].len - 1 - p_pos[1]) continue;
                //if (x_off < p_pos[1] or x_off > map[0].len - 1 - p_pos[1]) continue;
                const c_y: usize = @intCast(@as(i64, @intCast(p_pos[0])) + y_off);
                const c_x: usize = @intCast(@as(i64, @intCast(p_pos[1])) + x_off);

                if (path.get(@Vector(2, usize){ c_y, c_x })) |end_time| {
                    const cheat_cost: u64 = @abs(x_off) + @abs(y_off);
                    if (start_time + cheat_cost > end_time) continue;
                    const savings = end_time - start_time - cheat_cost;
                    //print("Found cheat! Saving {}\n", .{savings});
                    try cheats.append(alloc, savings);
                }
            }
        }
    }

    var total: u64 = 0;
    for (cheats.items) |cheat| {
        if (cheat >= 100) total += 1;
    }
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
