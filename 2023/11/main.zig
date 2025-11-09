const std = @import("std");
const print = std.debug.print;
const aoc = @import("aoc");

/// For part 1, = 2
/// For part 2, = 1_000_000
const EXPAND_FACTOR = 1_000_000;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var lines = try aoc.inputLineIterator(alloc);
    defer alloc.free(lines.contents);

    var galaxies: std.ArrayList([2]usize) = .empty;
    defer galaxies.deinit(alloc);

    // Eyeballed that 500 is big enuf
    var row_offsets: [500]isize = undefined;
    row_offsets[0] = 0;
    var col_offsets: [500]isize = undefined;
    col_offsets[0] = 0;

    // Input parsing
    {
        var potential_double_cols: std.ArrayList(bool) = .empty;
        defer potential_double_cols.deinit(alloc);

        var row: usize = 0;
        while (lines.next()) |line| : (row += 1) {
            // Init double col structure.
            if (row == 0) {
                try potential_double_cols.appendNTimes(alloc, true, line.len);
            } else {
                row_offsets[row] = row_offsets[row - 1] + 1;
            }

            //print("{s}\n", .{line});

            var double_row = true;
            for (line, 0..) |char, col| {
                if (char == '#') {
                    try galaxies.append(alloc, [2]usize{ row, col });
                    double_row = false;
                    potential_double_cols.items[col] = false;
                }
            }

            if (double_row) row_offsets[row] += EXPAND_FACTOR - 1;
        }

        for (potential_double_cols.items, 0..) |double, col| {
            if (col > 0) col_offsets[col] = col_offsets[col - 1] + 1;
            if (double) col_offsets[col] += EXPAND_FACTOR - 1;
        }
    }

    var dist_sum: usize = 0;
    var total_pairs: usize = 0;
    for (galaxies.items, 1..) |galaxy_a, pair_offset| {
        for (galaxies.items[pair_offset..]) |galaxy_b| {
            total_pairs += 1;
            //print("\n{any} -> {any}\n", .{ galaxy_a, galaxy_b });

            const row_dist = @abs(row_offsets[galaxy_a[0]] - row_offsets[galaxy_b[0]]);
            const col_dist = @abs(col_offsets[galaxy_a[1]] - col_offsets[galaxy_b[1]]);

            //print("Row dist {}, col dist {}\n", .{ row_dist, col_dist });
            dist_sum += row_dist + col_dist;
        }
    }

    print("Total pairs: {}\n", .{total_pairs});
    print("Expansion factor: {}\n", .{EXPAND_FACTOR});
    print("Sum: {}\n", .{dist_sum});
}
