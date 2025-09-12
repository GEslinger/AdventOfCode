const std = @import("std");
const print = std.debug.print;

const numpad = [4][3]u8{
    [3]u8{ 7, 8, 9 },
    [3]u8{ 4, 5, 6 },
    [3]u8{ 1, 2, 3 },
    [3]u8{ 'X', 0, 'A' },
};

const keypad = [2][3]u8{
    [3]u8{ 'X', '^', 'A' },
    [3]u8{ '<', 'v', '>' },
};

pub fn main() !void {
    printPad(numpad);
    print("\n", .{});
    printPad(keypad);

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var alloc = arena.allocator();

    _ = &alloc;
}

fn getPadFromTo(pad: anytype, from: u8, to: u8, dirs: *std.ArrayList(u8), alloc: *std.mem.Allocator) !void {
    const L = struct {
        pos: @Vector(2, usize),
        node: std.DoublyLinkedList.Node = .{},
    };

    var start = try alloc.create(L);

    for (pad, 0..) |row, y| {
        for (row, 0..) |val, x| {
            if (val == from) start.pos = @Vector(2, usize){ y, x };
        }
    }

    var search_ll: std.DoublyLinkedList = .{};
    search_ll.append(&start.node);

    while (search_ll.popFirst()) |node| {
        const l_ptr: *L = @fieldParentPtr("node", node);

        for (neighbors(pad, l_ptr.pos)) |n_opt| {
            if (n_opt) |n| {
                if (pad[n[0]][n[1]] == 'X') continue;
                var new_node = try alloc.create(L);
                new_node.pos = n;
                search_ll.append(&new_node.node);
            }
        }
    }
}

fn neighbors(map: anytype, coords: @Vector(2, usize)) [4]?@Vector(2, usize) {
    const y, const x = coords;
    var out = [_]?@Vector(2, usize){ null, null, null, null };
    if (x > 0) out[0] = @Vector(2, usize){ y, x - 1 };
    if (y > 0) out[1] = @Vector(2, usize){ y - 1, x };
    if (x < map[y].len - 1) out[2] = @Vector(2, usize){ y, x + 1 };
    if (y < map.len - 1) out[3] = @Vector(2, usize){ y + 1, x };

    return out;
}

fn printPad(pad: anytype) void {
    for (pad) |row| {
        for (row) |val| {
            defer print("\t", .{});
            if (val == 'X') continue;
            print("{}", .{val});
        }
        print("\n", .{});
    }
}
