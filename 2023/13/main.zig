const std = @import("std");
const print = std.debug.print;
const aoc = @import("aoc");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var lines = try aoc.inputLineIteratorSplit(alloc);
    defer alloc.free(lines.contents);

    var pattern: std.ArrayList([]const u8) = .empty;
    defer pattern.deinit(alloc);

    var totalRows: usize = 0;
    var totalCols: usize = 0;

    var line_num: isize = 0;
    while (lines.next()) |line| : (line_num += 1) {
        print("{s}\n", .{line});

        if (line.len <= 1) {
            addToRunningResult(pattern.items, &totalRows, &totalCols);
            print("\n\nNEXT!\n", .{});
            pattern.clearRetainingCapacity();
            line_num = -1;
            continue;
        }

        try pattern.append(alloc, line);
    } else {
        addToRunningResult(pattern.items, &totalRows, &totalCols);
    }

    const result = totalRows * 100 + totalCols;
    print("Final result: {}\n", .{result});
}

fn addToRunningResult(pattern: [][]const u8, r: *usize, c: *usize) void {
    const note = patternNote(pattern);
    print("Got r: {}, c: {}\n", .{ note.rows_above, note.cols_left });
    r.* += note.rows_above;
    c.* += note.cols_left;
}

fn patternNote(pattern: [][]const u8) struct {
    cols_left: usize = 0,
    rows_above: usize = 0,
} {
    // NOTE: vertical symmetry, will return > 0 for rows_above
    var last_line: []const u8 = undefined;
    for (pattern, 0..) |line, row| {
        //print("{s}\n", .{line});

        // Make sure we get rid of the 'undefined' value in the slice
        if (row == 0) {
            last_line = line;
            continue;
        }

        if (!std.mem.eql(u8, line, last_line)) {
            last_line = line;
            continue;
        }

        print("Same as above, potential mirror line\n", .{});
        // TIME TO VERIFY!
        var check_offset: usize = 0;
        while (check_offset + row < pattern.len - 1 and row - check_offset - 1 >= 1) {
            // Do the actual work
            check_offset += 1;
            if (!std.mem.eql(
                u8,
                pattern[row + check_offset],
                pattern[row - check_offset - 1],
            )) {
                print("Failed!\n", .{});
                break;
            }
        } else {
            print("Got it.\n", .{});
            return .{ .rows_above = row };
        }

        last_line = line;
    }

    // NOTE: Horizontal symmetry
    //
    // ....

    // FIXME: should be unreachable
    return .{};
}
