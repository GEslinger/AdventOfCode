const std = @import("std");
const print = std.debug.print;
const fmt = std.fmt;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();
    const contents = try file.readToEndAlloc(alloc, 1_000_000);
    defer alloc.free(contents);

    var lines = std.mem.tokenizeAny(u8, contents, "\n");
    var num_lines: usize = 0;
    while (lines.next()) |_| : (num_lines += 1) {} else lines.reset();
    print("Found {} lines.\n", .{num_lines});

    var seeds = std.ArrayList(struct { usize, usize }).init(alloc);
    defer seeds.deinit();

    var char_matrix: [][]u8 = undefined;
    char_matrix = try alloc.alloc([]u8, num_lines);

    var row: usize = 0;
    while (lines.next()) |line| : (row += 1) {
        char_matrix[row] = try alloc.alloc(u8, line.len);

        for (line, 0..) |char, col| {
            //print("Row: {}, Col: {}, Char: {c}\n", .{ row, col, char });
            char_matrix[row][col] = char;
            if (char == 'A') try seeds.append(.{ row, col });
        }
    }

    defer {
        for (0..char_matrix.len) |r| {
            //print("Freeing {} elements on row index {}\n", .{ char_matrix[r].len, r });
            alloc.free(char_matrix[r]);
        }
        alloc.free(char_matrix);
    }

    var xmas_counter: u64 = 0;
    for (seeds.items) |seed| {
        var counter: u64 = 0;
        counter += exploreForPatternInDirection(seed, char_matrix, "MAS", 1, 1);
        counter += exploreForPatternInDirection(seed, char_matrix, "MAS", 1, -1);
        counter += exploreForPatternInDirection(seed, char_matrix, "MAS", -1, -1);
        counter += exploreForPatternInDirection(seed, char_matrix, "MAS", -1, 1);

        if (counter == 2) {
            xmas_counter += 1;
            print("Found at ({},{})\n", .{ seed.@"0", seed.@"1" });
        }
    }

    print("XMAS count: {}\n", .{xmas_counter});
}

fn exploreForPatternInDirection(seed: struct { usize, usize }, field: [][]u8, pat: []const u8, row_inc: i64, col_inc: i64) u1 {
    const seed_row, const seed_col = seed;

    var step: usize = 0;
    while (step < pat.len) : (step += 1) {
        const st: i64 = @intCast(step);

        var tmp: i64 = @intCast(seed_row);
        tmp += row_inc * (st - 1);
        if (tmp < 0) return 0;
        const check_row: usize = @intCast(tmp);

        tmp = @intCast(seed_col);
        tmp += col_inc * (st - 1);
        if (tmp < 0) return 0;
        const check_col: usize = @intCast(tmp);

        if (check_row >= field.len) return 0;
        if (check_col >= field[check_row].len) return 0;

        //print("checking ({},{})\n", .{ check_row, check_col });
        if (field[check_row][check_col] != pat[step]) return 0;
    }

    return 1;
}
