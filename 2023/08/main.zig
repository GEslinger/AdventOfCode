const std = @import("std");
const print = std.debug.print;
const aoc = @import("aoc");

const Node = struct {
    l: []const u8,
    r: []const u8,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var nodes = std.StringHashMap(Node).init(alloc);
    defer nodes.deinit();

    var a_starts: std.ArrayList([]const u8) = .empty;
    defer a_starts.deinit(alloc);

    var lines = try aoc.inputLineIterator(alloc);
    defer alloc.free(lines.contents);

    const dirs: []const u8 = lines.next().?;

    // Discard empty line
    _ = lines.next();

    while (lines.next()) |line| {
        var part = std.mem.tokenizeAny(u8, line, " =(,)");
        const key = part.next().?;
        try nodes.put(key, Node{ .l = part.next().?, .r = part.next().? });
        if (key[2] == 'A') try a_starts.append(alloc, key);
    }

    //var current: []const u8 = "AAA";
    //var dir_idx: usize = 0;
    //var steps: u64 = 0;
    //while (!std.mem.eql(u8, current, "ZZZ")) : (dir_idx += 1) {
    //    if (dir_idx >= dirs.len) dir_idx = 0;
    //    const branches = nodes.get(current).?;
    //    current = if (dirs[dir_idx] == 'R') branches.r else branches.l;
    //    steps += 1;
    //}

    //print("Answer part 1: {}\n", .{steps});

    var mul: u128 = 1;
    var denom: u128 = 0;
    for (a_starts.items) |start| {
        var current: []const u8 = start;
        var dir_idx: usize = 0;
        var steps: u64 = 0;
        while (current[2] != 'Z') : (dir_idx += 1) {
            if (dir_idx >= dirs.len) dir_idx = 0;
            const branches = nodes.get(current).?;
            current = if (dirs[dir_idx] == 'R') branches.r else branches.l;
            steps += 1;
            if (current[2] == 'Z') print("Steps for {s} to reach {s} : {}\n", .{ start, current, steps });
        }

        mul *= steps;
        denom = gcd(u128, steps, denom);
    }

    print("{} / {}\n", .{ mul, gcd(u128, mul, denom) });
    print("{}\n", .{mul / denom});
}

fn gcd(comptime T: type, a: T, b: T) T {
    if (b == 0) return a;
    return gcd(T, b, a % b);
}
