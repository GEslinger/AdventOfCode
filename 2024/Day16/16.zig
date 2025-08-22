const std = @import("std");
const print = std.debug.print;

// TODO: Breadth first search + cut off branches with higher cost than lowest-cost found end

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
        var file = try std.fs.cwd().openFile("input", .{});
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
                map[line_num][col] = char;
            }
        }
        print("Start {}, End {}\n", .{ start_pos, end_pos });
    }

    var traverse_tree: std.ArrayList(*Node) = .empty;
    var ends: std.ArrayList(*Node) = .empty;
    var tree_idx: usize = 0;

    {
        const allocated_node = try alloc.create(Node);
        allocated_node.* = Node{ .parent = null, .cost = 0, .pos = start_pos, .facing = 0 };
        try traverse_tree.append(alloc, allocated_node);
    }

    while (tree_idx < traverse_tree.items.len) : (tree_idx += 1) {
        const current_node = traverse_tree.items[tree_idx];
        //if (current_node.parent) |p| print("Parent pos {} cost {}\n", .{ p.pos, p.cost });
        //print("At {} facing {}\n", .{ current_node.pos, current_node.facing });

        const moves = [_]Move{ Move.forward, Move.right, Move.left };
        move_loop: for (moves) |move| {
            //print("Trying {any}\n", .{move});
            const potential_next = current_node.considerMove(move);

            //print("Seeing {c}", .{map[potential_next.pos[0]][potential_next.pos[1]]});
            switch (map[potential_next.pos[0]][potential_next.pos[1]]) {
                '#' => {
                    //print("BONK!\n", .{});
                    continue :move_loop;
                },
                'E' => {
                    print("Found end! {}\n", .{potential_next.cost});
                    const allocated_node = try alloc.create(Node);
                    allocated_node.* = potential_next;

                    try ends.append(alloc, allocated_node);
                    //break :search_loop;
                },
                else => {},
            }

            for (traverse_tree.items) |node| {
                if (@reduce(.And, node.pos == potential_next.pos) and node.facing == potential_next.facing and node.cost < potential_next.cost) {
                    //print("Seen it before at lower cost!\n", .{});
                    continue :move_loop;
                }
            }
            const allocated_node = try alloc.create(Node);
            allocated_node.* = potential_next;

            //print("Trying {any}\n", .{move});
            try traverse_tree.append(alloc, allocated_node);
        }
    }

    var best_tiles = std.AutoHashMap(@Vector(2, usize), void).init(alloc);
    var min_cost: u64 = std.math.maxInt(u64);

    for (ends.items) |end_node| {
        if (end_node.cost < min_cost) min_cost = end_node.cost;
    }

    print("Minimum cost: {}\n", .{min_cost});

    var path: std.ArrayList(*const Node) = .empty;
    for (ends.items) |end_node| {
        var end_iter: ?*const Node = end_node;
        //if (end_node.cost == min_cost) print("INCLUDE\n", .{});

        while (end_iter) |path_node| {
            //print("appending to path {}\n", .{path_node.pos});
            try path.append(alloc, path_node);
            if (end_node.cost == min_cost) _ = try best_tiles.getOrPut(path_node.pos);
            end_iter = path_node.parent;
        }

        for (map, 0..) |line, row| {
            for (line, 0..) |char, col| {
                var p_char = char;
                for (path.items) |path_node| {
                    if (path_node.pos[0] == row and path_node.pos[1] == col) {
                        p_char = path_node.arrow();
                    }
                }

                //print("{c}", .{p_char});
            }

            //print("\n", .{});
        }

        //print("\n\n", .{});
        path.clearAndFree(alloc);
    }

    print("Number of best tiles: {}\n", .{best_tiles.count()});
}

const Move = enum { forward, right, left };

const Node = struct {
    parent: ?*const Node,
    cost: u64,
    pos: @Vector(2, usize),
    facing: u2, // East, North, West, South

    fn arrow(self: Node) u8 {
        return switch (self.facing) {
            0 => '>',
            1 => '^',
            2 => '<',
            3 => 'v',
        };
    }

    fn considerMove(self: *Node, move: Move) Node {
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
            .parent = self,
            .cost = new_cost,
            .pos = new_pos,
            .facing = new_facing,
        };
    }
};
