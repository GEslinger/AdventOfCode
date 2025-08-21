const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    //var robot: @Vector(2, usize) = undefined;
    var map: [][]u8 = undefined;
    var start_pos: @Vector(2, usize) = undefined;
    var end_pos: @Vector(2, usize) = undefined;

    {
        //var arg_iter = try std.process.argsWithAllocator(alloc);
        //_ = arg_iter.next();
        //const file_name = arg_iter.next() orelse {
        //    print("No filename provided.\n", .{});
        //    return;
        //};
        //print("Trying file {s}\n", .{file_name});
        var file = try std.fs.cwd().openFile("mini", .{});
        defer file.close();

        const contents = try file.readToEndAlloc(alloc, 1_000_000);

        var lines = std.mem.splitAny(u8, contents, "\n");
        {
            var line_count: usize = 0;
            while (lines.next()) |_| line_count += 1;
            map = try alloc.alloc([]u8, line_count);
            lines.reset();
        }

        var line_num: usize = 0;
        while (lines.next()) |dirty_line| : (line_num += 1) {
            const line = std.mem.trim(u8, dirty_line, "\r");
            map[line_num] = try alloc.alloc(u8, line.len);
            for (line, 0..) |char, col| {
                if (char == 'S') start_pos = @Vector(2, usize){ line_num, col };
                if (char == 'E') end_pos = @Vector(2, usize){ line_num, col };
            }
        }
        print("Start {}, End {}\n", .{ start_pos, end_pos });
    }

    var traverse_tree = std.ArrayList(Node).init(alloc);
    var tree_idx: usize = 0;

    try traverse_tree.append(Node{ .parent = null, .cost = 0, .pos = start_pos, .facing = 0 });

    while (tree_idx < traverse_tree.items.len) : (tree_idx += 1) {
        const current_node = traverse_tree.items[tree_idx];
        print("At {}\n", .{current_node.pos});

        inline for (std.meta.fields(Move)) |move_field| {
            print("Trying {s}\n", .{move_field.name});
            const move: Move = @enumFromInt(move_field.value);
            const potential_next = current_node.considerMove(move);

            //TODO: Check if the move is already in the tree
            switch (map[potential_next.pos[0]][potential_next.pos[1]]) {
                //TODO: Append move if '.', do something special if 'E'
            }
        }
    }
}

const Move = enum { forward, right, left };

const Node = struct {
    parent: ?*Node,
    cost: u64,
    pos: @Vector(2, usize),
    facing: u2, // East, North, West, South

    fn considerMove(self: Node, move: Move) Node {
        var new_cost = self.cost;
        var new_pos = self.pos;
        var new_facing = self.facing;

        switch (move) {
            .forward => {
                new_cost += 1;
                new_pos = switch (self.facing) {
                    0 => new_pos + @Vector(2, usize){ 0, 1 },
                    1 => new_pos - @Vector(2, usize){ 1, 0 },
                    2 => new_pos - @Vector(2, usize){ 0, 1 },
                    3 => new_pos + @Vector(2, usize){ 1, 0 },
                    else => unreachable,
                };
            },
            .right => {
                new_cost += 1000;
                new_facing -%= 1;
            },
            .left => {
                new_cost += 1000;
                new_facing +%= 1;
            },
        }

        return Node{
            .parent = &self,
            .cost = new_cost,
            .pos = new_pos,
            .facing = new_facing,
        };
    }
};
