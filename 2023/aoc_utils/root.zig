//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

pub fn isNumeric(char: u8) bool {
    return switch (char) {
        '0'...'9' => true,
        else => false,
    };
}

const N8 = struct { arr: [8][2]usize, len: usize };

/// Assumes a rectangular array
/// TODO: Add a test!
pub fn neighbors8(arr: anytype, coords: [2]usize) N8 {
    var i: usize = 0;
    var result: N8 = undefined;
    const max_i = arr.len - 1;
    const max_j = arr[0].len - 1;

    if (coords[0] < max_i) {
        result.arr[i] = [_]usize{ coords[0] + 1, coords[1] };
        i += 1;
    }
    if (coords[0] < max_i and coords[1] > 0) {
        result.arr[i] = [_]usize{ coords[0] + 1, coords[1] - 1 };
        i += 1;
    }
    if (coords[1] > 0) {
        result.arr[i] = [_]usize{ coords[0], coords[1] - 1 };
        i += 1;
    }
    if (coords[1] > 0 and coords[0] > 0) {
        result.arr[i] = [_]usize{ coords[0] - 1, coords[1] - 1 };
        i += 1;
    }
    if (coords[0] > 0) {
        result.arr[i] = [_]usize{ coords[0] - 1, coords[1] };
        i += 1;
    }
    if (coords[0] > 0 and coords[1] < max_j) {
        result.arr[i] = [_]usize{ coords[0] - 1, coords[1] + 1 };
        i += 1;
    }
    if (coords[1] < max_j) {
        result.arr[i] = [_]usize{ coords[0], coords[1] + 1 };
        i += 1;
    }
    if (coords[1] < max_j and coords[0] < max_i) {
        result.arr[i] = [_]usize{ coords[0] + 1, coords[1] + 1 };
        i += 1;
    }

    //result.slice = result.all[0..i];
    result.len = i;
    return result;
}

/// Assumes a rectangular array
/// TODO: Add a test!
pub fn neighbors4OrNull(arr: anytype, coords: [2]usize) [4]?[2]usize {
    var result: [4]?[2]usize = @splat(null);
    const max_i = arr.len - 1;
    const max_j = arr[0].len - 1;

    if (coords[0] < max_i) {
        result[0] = [_]usize{ coords[0] + 1, coords[1] };
    }
    if (coords[1] > 0) {
        result[1] = [_]usize{ coords[0], coords[1] - 1 };
    }
    if (coords[0] > 0) {
        result[2] = [_]usize{ coords[0] - 1, coords[1] };
    }
    if (coords[1] < max_j) {
        result[3] = [_]usize{ coords[0], coords[1] + 1 };
    }

    return result;
}

const LineIterator = struct {
    const Self = @This();
    contents: []const u8,
    type: enum { split, tokenize },
    internal_iter: std.mem.TokenIterator(u8, .any),
    split_iter: std.mem.SplitIterator(u8, .any),
    alloc: std.mem.Allocator,

    fn init(contents: []const u8, alloc: std.mem.Allocator) Self {
        return Self{
            .contents = contents,
            .type = .tokenize,
            .internal_iter = std.mem.tokenizeAny(u8, contents, "\n"),
            .split_iter = undefined,
            .alloc = alloc,
        };
    }

    fn initSplit(contents: []const u8, alloc: std.mem.Allocator) Self {
        return Self{
            .contents = contents,
            .type = .split,
            .split_iter = std.mem.splitAny(u8, contents, "\n"),
            .internal_iter = undefined,
            .alloc = alloc,
        };
    }

    pub fn next(self: *Self) ?[]const u8 {
        const dirty_line_opt = switch (self.type) {
            .tokenize => self.internal_iter.next(),
            .split => self.split_iter.next(),
        };
        if (dirty_line_opt) |dirty_line| {
            return std.mem.trimEnd(u8, dirty_line, "\r");
        } else {
            return null;
        }
    }
};

pub fn inputLineIterator(alloc: std.mem.Allocator) !LineIterator {
    const contents = try contentsOfFileInArg(alloc);
    return LineIterator.init(contents, alloc);
}

pub fn inputLineIteratorSplit(alloc: std.mem.Allocator) !LineIterator {
    const contents = try contentsOfFileInArg(alloc);
    return LineIterator.initSplit(contents, alloc);
}

pub fn contentsOfFileInArg(alloc: std.mem.Allocator) ![]const u8 {
    var args = try std.process.argsWithAllocator(alloc);
    defer args.deinit();

    // Discard executable path
    _ = args.next().?;

    // Next argument is the file name
    const fname = args.next() orelse @panic("Put filename of input in first argument.");
    var file = try std.fs.cwd().openFile(fname, .{});
    defer file.close();

    return try file.readToEndAlloc(alloc, 1_000_000);
}
