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

                map[line_num] = try alloc.alloc(Space, line.len);

                for (line, 0..) |space, col| {
                    //print("{c}", .{space});

                    map[line_num][col] = switch (space) {
                        '#' => Space.wall,
                        '.' => Space.empty,
                        'O' => Space.box,
                        '@' => blk: {
                            robot = @Vector(2, usize){ line_num, col };
                            break :blk Space.empty;
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

    for (moves.items) |move| {
        const new_pos = move.offset(robot);

        const ahead = map[new_pos[0]][new_pos[1]];
        switch (ahead) {
            .empty => robot = new_pos,
            .box => {
                var search_pos = new_pos;
                var next_pos = move.offset(search_pos);
                var search_space = map[search_pos[0]][search_pos[1]];

                while (search_space != Space.empty) {
                    search_pos = next_pos;
                    search_space = map[search_pos[0]][search_pos[1]];

                    if (search_space == Space.wall) {
                        break;
                    }

                    next_pos = move.offset(search_pos);
                } else {
                    map[new_pos[0]][new_pos[1]] = Space.empty;
                    map[search_pos[0]][search_pos[1]] = Space.box;
                    robot = new_pos;
                }
            },
            .wall => {
                //print("BONK!\n", .{});
            },
        }
    }

    printMap(map);
    print("{any}\n\n", .{robot});

    var sum: u64 = 0;
    for (map, 0..) |row, y| {
        for (row, 0..) |space, x| {
            if (space == .box) sum += 100 * y + x;
        }
    }

    print("Sum: {}\n", .{sum});
}

const Space = enum { wall, empty, box };

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

fn printMap(map: [][]Space) void {
    for (map) |row| {
        for (row) |space| {
            const char: u8 = switch (space) {
                .box => 'O',
                .wall => '#',
                .empty => '.'
            };
            print("{c}", .{char});
        }
        print("\n", .{});
    }
}
