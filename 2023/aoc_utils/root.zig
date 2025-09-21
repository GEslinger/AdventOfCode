//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

const LineIterator = struct {
    const Self = @This();
    contents: []const u8,
    internal_iter: std.mem.TokenIterator(u8, .any),
    alloc: std.mem.Allocator,

    fn init(contents: []const u8, alloc: std.mem.Allocator) Self {
        return Self{
            .contents = contents,
            .internal_iter = std.mem.tokenizeAny(u8, contents, "\n"),
            .alloc = alloc,
        };
    }

    pub fn next(self: *Self) ?[]const u8 {
        const dirty_line_opt = self.internal_iter.next();
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

pub fn contentsOfFileInArg(alloc: std.mem.Allocator) ![]const u8 {
    var args = try std.process.argsWithAllocator(alloc);
    defer args.deinit();

    const path = args.next().?;
    std.debug.print("{s}\n", .{path});

    // Next argument is the file name
    const fname = args.next() orelse @panic("Put filename of input in first argument.");
    var file = try std.fs.cwd().openFile(fname, .{});
    defer file.close();

    return try file.readToEndAlloc(alloc, 1_000_000);
}
