const std = @import("std");
const print = std.debug.print;

const corner = 70;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var blocked = std.AutoHashMap(@Vector(2, usize), void).init(alloc);
    var path_tree: std.ArrayList(*PathNode) = .empty;

    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();
    const contents = try file.readToEndAlloc(alloc, 1_000_000);

    var i_limit: usize = 0;
    var last_coords: @Vector(2, usize) = undefined;
    while (true) : (i_limit += 1) {
        var coord_iter = std.mem.tokenizeAny(u8, contents, "\r\n,");

        var i: usize = 0;
        while (i < i_limit) : (i += 1) {
            const X = coord_iter.next().?;
            const Y = coord_iter.next().?;
            last_coords = @Vector(2, usize){ try std.fmt.parseInt(usize, X, 10), try std.fmt.parseInt(usize, Y, 10) };
            _ = try blocked.put(last_coords, {});
        }

        {
            const start = try alloc.create(PathNode);
            start.* = PathNode{ .pos = @Vector(2, usize){ 0, 0 } };
            try path_tree.append(alloc, start);
        }

        var idx: usize = 0;
        while (idx < path_tree.items.len) : (idx += 1) {
            const node = path_tree.items[idx];

            if (node.pos[0] > 0) _ = (try tryToGo(node, node.pos - @Vector(2, usize){ 1, 0 }, alloc, &blocked, &path_tree)) orelse break;
            if (node.pos[1] > 0) _ = (try tryToGo(node, node.pos - @Vector(2, usize){ 0, 1 }, alloc, &blocked, &path_tree)) orelse break;
            if (node.pos[0] < corner) _ = (try tryToGo(node, node.pos + @Vector(2, usize){ 1, 0 }, alloc, &blocked, &path_tree)) orelse break;
            if (node.pos[1] < corner) _ = (try tryToGo(node, node.pos + @Vector(2, usize){ 0, 1 }, alloc, &blocked, &path_tree)) orelse break;
        } else {
            print("FAIL\n", .{});
            break;
        }

        print("Found! {}\n", .{path_tree.getLast().length});
        path_tree.clearRetainingCapacity();
        blocked.clearRetainingCapacity();
    }

    print("Blocked by {}\n", .{last_coords});
}

fn tryToGo(prev: *PathNode, new_pos: @Vector(2, usize), alloc: std.mem.Allocator, blocked: anytype, path_tree: anytype) !?void {
    const result = try blocked.getOrPut(new_pos);
    if (result.found_existing) return;
    //print("Trying {}\n", .{new_pos});

    const new_node = try alloc.create(PathNode);
    new_node.* = PathNode{
        .pos = new_pos,
        .length = prev.length + 1,
        .prev = prev,
    };

    try path_tree.append(alloc, new_node);
    if (new_pos[0] == corner and new_pos[1] == corner) return null;
}

const Found = error{Done};

const PathNode = struct {
    pos: @Vector(2, usize),
    length: usize = 0,
    prev: ?*PathNode = null,
};
