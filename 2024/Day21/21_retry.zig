const std = @import("std");
const print = std.debug.print;

const numpad = [4][3]u8{
    [3]u8{ '7', '8', '9' },
    [3]u8{ '4', '5', '6' },
    [3]u8{ '1', '2', '3' },
    [3]u8{ 'X', '0', 'A' },
};

const keypad = [2][3]u8{
    [3]u8{ 'X', '^', 'A' },
    [3]u8{ '<', 'v', '>' },
};

const Key = struct {
    seq: []u8,
    level: usize,
};

const Dir = enum {
    u,
    d,
    l,
    r,
    fn toChar(self: Dir) u8 {
        return switch (self) {
            .u => '^',
            .d => 'v',
            .l => '<',
            .r => '>',
        };
    }
};

fn arrBoundsOk(arr: anytype, x: usize, y: usize, dir: Dir) bool {
    return switch (dir) {
        .u => y > 0,
        .d => y < arr.len - 1,
        .l => x > 0,
        .r => x < arr[0].len - 1,
    };
}

fn offsetXY(arr: anytype, x: *usize, y: *usize, dir: Dir) bool {
    const bounds_ok = switch (dir) {
        .u => y.* > 0,
        .d => y.* < arr.len - 1,
        .l => x.* > 0,
        .r => x.* < arr[0].len - 1,
    };

    if (!bounds_ok) return false;

    switch (dir) {
        .u => y.* -= 1,
        .d => y.* += 1,
        .l => x.* -= 1,
        .r => x.* += 1,
    }

    return true;
}

fn min(arr: anytype) @TypeOf(arr[0]) {
    var min_value: ?@TypeOf(arr[0]) = null;
    for (arr) |value| {
        if (value <= (min_value orelse value)) min_value = value;
    }

    return min_value.?;
}

var list_buffer: [500]L = undefined;
const L = struct {
    x: usize = 0,
    y: usize = 0,
    len: usize = 0,
    path: [5]?u8 = @splat(null),
    node: std.DoublyLinkedList.Node = .{},
};

fn pathsAToB(arr: anytype, a: u8, b: u8, alloc: std.mem.Allocator) !std.ArrayList(std.ArrayList(u8)) {
    list_buffer[0] = start: for (arr, 0..) |row, y| {
        for (row, 0..) |value, x| {
            if (value == a) break :start L{
                .x = x,
                .y = y,
            };
        }
    } else unreachable;

    var search_tree: std.DoublyLinkedList = .{};
    search_tree.append(&list_buffer[0].node);
    var buffer_index: usize = 1;

    var paths: std.ArrayList(std.ArrayList(u8)) = .empty;
    var best_length: usize = 5;
    while (search_tree.popFirst()) |node| {
        const leaf: *L = @fieldParentPtr("node", node);
        if (arr[leaf.y][leaf.x] == b) {
            best_length = leaf.len;
            var new_list: std.ArrayList(u8) = .empty;
            for (leaf.path) |value| try new_list.append(alloc, value orelse break);
            try paths.append(alloc, new_list);
            continue;
        }
        if (arr[leaf.y][leaf.x] == 'X' or leaf.len >= best_length) continue;

        inline for (@typeInfo(Dir).@"enum".fields) |dir_field| {
            const dir: Dir = @enumFromInt(dir_field.value);
            var new_node = L{
                .len = leaf.len + 1,
                .path = leaf.path,
                .x = leaf.x,
                .y = leaf.y,
            };
            if (offsetXY(arr, &new_node.x, &new_node.y, dir)) {
                new_node.path[leaf.len] = dir.toChar();

                list_buffer[buffer_index] = new_node;
                search_tree.append(&list_buffer[buffer_index].node);
                buffer_index += 1;
            }
        }
    }

    return paths;
}

fn seqLengthMemo(
    pad: anytype,
    seq: *std.ArrayList(u8),
    remaining: usize,
    alloc: std.mem.Allocator,
    memo: anytype,
) usize {
    const memo_entry = memo.getOrPut(Key{ .seq = seq.items, .level = remaining }) catch unreachable;
    if (!memo_entry.found_existing) {
        memo_entry.value_ptr.* = sequenceLength(pad, seq, remaining, alloc, memo) catch unreachable;
    } else {
        //print("Found hashed value!\n", .{});
    }

    return memo_entry.value_ptr.*;
}

fn sequenceLength(
    pad: anytype,
    seq: *std.ArrayList(u8),
    remaining: usize,
    alloc: std.mem.Allocator,
    memo: anytype,
) !usize {
    if (remaining == 0) {
        return seq.items.len;
    }

    //print("Check {s}\n", .{seq.items});
    try seq.insert(alloc, 0, 'A');

    var len: usize = 0;
    for (seq.items[0 .. seq.items.len - 1], seq.items[1..seq.items.len]) |from, to| {
        const paths = try pathsAToB(pad, from, to, alloc);

        var m: usize = std.math.maxInt(usize);
        for (paths.items) |path| {
            var new_seq = try path.clone(alloc);
            try new_seq.append(alloc, 'A');
            //print("Consider {s}\n", .{new_seq.items});
            const path_len = seqLengthMemo(keypad, &new_seq, remaining - 1, alloc, memo);
            if (path_len < m) m = path_len;
        }

        len += m;
        //print("Then ", .{});
    }

    //print("Level {}, Min length path: {}\n", .{ remaining, len });

    return len;
}

pub fn main() !void {
    print("Hello, world!\n", .{});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const KeyCtx = struct {
        pub fn hash(_: @This(), k: Key) u64 {
            var hasher = std.hash.Fnv1a_64.init();
            hasher.update(k.seq);
            const level_u8 = [_]u8{@intCast(k.level)};
            hasher.update(level_u8[0..]);
            return hasher.final();
        }

        pub fn eql(_: @This(), a: Key, b: Key) bool {
            return std.mem.eql(u8, a.seq, b.seq) and a.level == b.level;
        }
    };

    var memo = std.HashMap(Key, usize, KeyCtx, std.hash_map.default_max_load_percentage).init(alloc);
    defer memo.deinit();

    var seq = "029A";
    var seq_arr: std.ArrayList(u8) = .empty;
    try seq_arr.appendSlice(alloc, seq[0..]);
    const shortest = seqLengthMemo(numpad, &seq_arr, 10, alloc, &memo);

    print("Shortest: {}\n", .{shortest});
}
