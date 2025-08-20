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
        var file = try std.fs.cwd().openFile("micro", .{});
        defer file.close();

        const contents = try file.readToEndAlloc(alloc, 1_000_000);
        print("{s}\n\n", .{contents});

        var lines = std.mem.splitAny(u8, contents, "\r\n");
        {
            var line_count: usize = 0;
            while (lines.next()) |_| line_count += 1;
            map = try alloc.alloc([]Space, line_count);
            lines.reset();
        }

        var line_num: usize = 0;
        var mapping = true;
        while (lines.next()) |line| : (line_num += 1) {
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
                        else => unreachable,
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
//TODO: Continue and write function
                if (canMove(new_pos, move))
            }
            else => {
                print("BONK!\n", .{});
            },
        }
    }

    print("{any}\n", .{robot});
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
