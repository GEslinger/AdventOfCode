const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var input = try std.fs.cwd().openFile("input", .{});
    defer input.close();

    const contents = try input.readToEndAlloc(alloc, 1_000_000);
    defer alloc.free(contents);
    var lines = std.mem.tokenizeAny(u8, contents, "\n");
    const c = std.mem.count(u8, contents, "\n");

    std.debug.print("{} lines.\n", .{c});

    var safe_reports: i64 = 0;
    while (lines.next()) |line| {
        var state = Checker.begin;
        var value: ?i64 = null;
        var num_bad: i64 = 0;

        var num_strings = std.mem.tokenizeAny(u8, line, " ");
        while (num_strings.next()) |num_string| {
            const new_value = try std.fmt.parseInt(i64, num_string, 10);

            switch (state) {
                Checker.begin => {
                    value = new_value;
                    state = Checker.first;
                },
                Checker.first => {
                    const diff = new_value - value.?;
                    switch (diff) {
                        1...3 => state = Checker.inc,
                        -3...-1 => state = Checker.dec,
                        else => num_bad += 1,
                    }
                },
                Checker.inc => {
                    const diff = new_value - value.?;
                    switch (diff) {
                        1...3 => {},
                        else => num_bad += 1,
                    }
                },
                Checker.dec => {
                    const diff = new_value - value.?;
                    switch (diff) {
                        -3...-1 => {},
                        else => num_bad += 1,
                    }
                },
            }
            value = new_value;
        }

        if (num_bad <= 1) safe_reports += 1;
    }

    std.debug.print("Safe reports: {}\n", .{safe_reports});
}

const Checker = enum { begin, first, inc, dec };
