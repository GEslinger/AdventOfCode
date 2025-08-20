const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var robot: @Vector(2, usize) = undefined;
    var map: [][]Space = undefined;

    var moves = std.ArrayList(Move).init(alloc);

    {
        var file = try std.fs.cwd().openFile("input", .{});
        defer file.close();

        const contents = try file.readToEndAlloc(alloc, 1_000_000);
        //print("{s}\n\n", .{contents});

        var lines = std.mem.splitAny(u8, contents, "\n");
        {
            var line_count: usize = 0;
            while (lines.next()) |line| {
                if (line.len > 5) {
                    line_count += 1;
                } else {
                    break;
                }
            }
            map = try alloc.alloc([]Space, line_count);
            lines.reset();
        }

        var line_num: usize = 0;
        var mapping = true;
        while (lines.next()) |dirty_line| : (line_num += 1) {
            const line = std.mem.trim(u8, dirty_line, "\r");
            if (mapping) {
                if (line.len < 5) {
                    mapping = false;
                    //print("END MAPPING\n", .{});
                    continue;
                }

                map[line_num] = try alloc.alloc(Space, line.len * 2);

                for (line, 0..) |char, col_half| {
                    const col = col_half * 2;
                    //print("{c}", .{space});
                    var map_slice = map[line_num][col .. col + 2];

                    map_slice[0], map_slice[1] = switch (char) {
                        '#' => .{ Space.wall, Space.wall },
                        '.' => .{ Space.empty, Space.empty },
                        'O' => .{ Space.box_l, Space.box_r },
                        '@' => blk: {
                            robot = @Vector(2, usize){ line_num, col };
                            break :blk .{ Space.empty, Space.empty };
                        },
                        '\r' => continue,
                        else => unreachable,
                    };
                }
            } else {
                for (line) |move| {
                    try moves.append(switch (move) {
                        '^' => Move.up,
                        '>' => Move.right,
                        'v' => Move.down,
                        '<' => Move.left,
                        '\r' => continue,
                        else => continue,
                    });
                }
            }
        }
    }

    //print("{any}\n", .{moves.items});

    var push_tree = std.ArrayList(@Vector(2, usize)).init(alloc); // box_l positions
    var build_tree = std.ArrayList(void).init(alloc); // box_l positions

    move_loop: for (moves.items) |move| {
        //printMap(map, robot);
        //print("{}\n", .{move});
        build_tree.clearAndFree();
        push_tree.clearAndFree(); // Just in case!!!
        const new_pos = move.offset(robot);

        const ahead = map[new_pos[0]][new_pos[1]];
        switch (ahead) {
            .empty => robot = new_pos,
            .box_l, .box_r => {
                if (move == .left or move == .right) {
                    var search_pos = new_pos;
                    var next_pos = move.offset(search_pos);
                    var search_space = map[search_pos[0]][search_pos[1]];

                    while (search_space != Space.empty) {
                        search_pos = next_pos;
                        search_space = map[search_pos[0]][search_pos[1]];

                        if (search_space == Space.wall) {
                            break;
                        }

                        try push_tree.append(search_pos);
                        next_pos = move.offset(search_pos);
                    } else {
                        map[new_pos[0]][new_pos[1]] = Space.empty;
                        robot = new_pos;

                        for (push_tree.items) |swap_pos| {
                            //print("Swapping {}\n", .{swap_pos});
                            map[swap_pos[0]][swap_pos[1]] = map[swap_pos[0]][swap_pos[1]].swap_horizontal(move);
                        }
                    }
                } else {
                    //print("Need to write this lmao\n", .{});
                    //var next_pos = new_pos;

                    if (ahead == .box_l) {
                        try push_tree.append(new_pos);
                    } else {
                        try push_tree.append(new_pos - @Vector(2, usize){ 0, 1 });
                    }
                    try build_tree.append({});

                    var tree_idx: usize = 0;
                    while (tree_idx < push_tree.items.len) : (tree_idx += 1) {
                        const leaf_pos = push_tree.items[tree_idx];
                        const check_pos = move.offset(leaf_pos);
                        const check_right = move.offset(leaf_pos + @Vector(2, usize){ 0, 1 });
                        //print("At {}, build level {}, seeing L:{}\n", .{ leaf_pos, tree_idx, map[check_pos[0]][check_pos[1]] });

                        switch (map[check_pos[0]][check_pos[1]]) {
                            .box_l => {
                                try push_tree.append(check_pos);
                                //try build_tree.append({});
                            },
                            .box_r => {
                                try push_tree.append(check_pos - @Vector(2, usize){ 0, 1 });
                                //try build_tree.append({});
                            },
                            .wall => {
                                //print("Can't push!\n", .{});
                                continue :move_loop;
                            },
                            .empty => {},
                        }
                        switch (map[check_right[0]][check_right[1]]) {
                            .box_l => {
                                try push_tree.append(check_right);
                            },
                            .box_r => {},
                            .wall => {
                                //print("Can't push!\n", .{});
                                continue :move_loop;
                            },
                            .empty => {},
                        }
                    }

                    // We can push!
                    robot = new_pos;
                    //print("{any}\n", .{push_tree.items});
                    while (push_tree.pop()) |box_left_pos| {
                        map[box_left_pos[0]][box_left_pos[1]] = Space.empty;
                        map[box_left_pos[0]][box_left_pos[1] + 1] = Space.empty;

                        const new_box_pos = move.offset(box_left_pos);

                        map[new_box_pos[0]][new_box_pos[1]] = Space.box_l;
                        map[new_box_pos[0]][new_box_pos[1] + 1] = Space.box_r;
                    }
                }
            },
            .wall => {
                //print("BONK!\n", .{});
            },
        }
    }

    printMap(map, robot);
    //print("{any}\n\n", .{robot});

    var sum: u64 = 0;
    for (map, 0..) |row, y| {
        for (row, 0..) |space, x| {
            if (space == .box_l) sum += 100 * y + x;
        }
    }

    print("Sum: {}\n", .{sum});
}

const Space = enum {
    wall,
    empty,
    box_l,
    box_r,
    fn swap_horizontal(self: Space, move: Move) Space {
        return switch (self) {
            .box_l => Space.box_r,
            .box_r => Space.box_l,
            .empty => blk: {
                if (move == .left) break :blk Space.box_l;
                break :blk Space.box_r;
            },
            else => unreachable,
        };
    }
};

const Move = enum {
    up,
    right,
    down,
    left,

    fn offset(self: Move, robot: @Vector(2, usize)) @Vector(2, usize) {
        return switch (self) {
            .up => robot - @Vector(2, usize){ 1, 0 },
            .right => robot + @Vector(2, usize){ 0, 1 },
            .down => robot + @Vector(2, usize){ 1, 0 },
            .left => robot - @Vector(2, usize){ 0, 1 },
        };
    }
};

fn printMap(map: [][]Space, robot: @Vector(2, usize)) void {
    for (map, 0..) |row, y| {
        for (row, 0..) |space, x| {
            if (robot[0] == y and robot[1] == x) {
                print("@", .{});
                continue;
            }
            const char: u8 = switch (space) {
                .box_l => '[',
                .box_r => ']',
                .wall => '#',
                .empty => '.'
            };
            print("{c}", .{char});
        }
        print("\n", .{});
    }
}
