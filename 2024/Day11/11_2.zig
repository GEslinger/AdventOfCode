const std = @import("std");
const print = std.debug.print;
const num_type = u64;
const Stone = struct { val: num_type, lvl: u32 };
const Idx = struct { val: num_type, explored: bool = false };

pub fn main() !void {
    print("Hello, world!\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    var alloc = gpa.allocator();
    defer _ = gpa.deinit();

    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();
    const contents = try file.readToEndAlloc(alloc, 1_000_000);
    defer alloc.free(contents);

    print("Contents:\n{s}\n", .{contents});

    var stones: std.ArrayList(Stone) = .empty;
    defer stones.deinit(alloc);

    {
        var first_stones_strings = std.mem.tokenizeAny(u8, contents, " \r\n");
        while (first_stones_strings.next()) |stone_string| {
            const new_stone = Stone{ .lvl = 0, .val = std.fmt.parseInt(num_type, stone_string, 10) catch break };
            try stones.append(alloc, new_stone);
        }
    }

    var first_stones = try stones.clone(alloc);
    defer first_stones.deinit(alloc);

    var seen_idx: std.ArrayList(Idx) = .empty;
    defer seen_idx.deinit(alloc);

    // Dictionary of keys to construct sparse matrix
    var dok_stones = std.AutoHashMap([2]usize, num_type).init(alloc);
    defer dok_stones.deinit();

    var fmt_buf: [1_000]u8 = undefined;
    const limit = 75;
    while (stones.pop()) |stone| {

        // NOTE: From part 1

        //if (stone.lvl == limit) {
        //    counter += 1;
        //    //print("bottomed out on {}\n", .{stone.val});
        //}
        //const found = try seen_stones_idx.getOrPut(stone.val);
        //print("\n\n\n{any}\n\n\n", .{seen_idx.items});

        var found = false;
        var explored = false;
        for (seen_idx.items) |check_stone| {
            if (stone.val == check_stone.val) {
                found = true;
                explored = check_stone.explored;
                continue;
            }
        }

        if (!found) {
            try seen_idx.append(alloc, Idx{ .val = stone.val, .explored = false });
        }
        if (!explored) {
            //print("Exploring {}\n", .{stone.val});
            const seen_idx_pos = indexOf(stone.val, seen_idx).?;
            //print("This is at index {}\n", .{seen_idx_pos});
            //if (stone.lvl == limit)
            seen_idx.items[seen_idx_pos].explored = true;

            var new_stones: [2]?Stone = [_]?Stone{ undefined, null };

            const val_string = try std.fmt.bufPrint(&fmt_buf, "{}", .{stone.val});
            if (stone.val == 0) {
                new_stones[0] = Stone{ .lvl = stone.lvl + 1, .val = 1 };
            } else if (val_string.len % 2 == 0) { // Even number of digits
                const first_half_str = val_string[0 .. val_string.len / 2];
                const second_half_str = val_string[val_string.len / 2 .. val_string.len];

                const first_half = try std.fmt.parseInt(num_type, first_half_str, 10);
                const second_half = try std.fmt.parseInt(num_type, second_half_str, 10);

                new_stones[0] = Stone{ .lvl = stone.lvl + 1, .val = first_half };
                new_stones[1] = Stone{ .lvl = stone.lvl + 1, .val = second_half };
            } else { // falback rule
                new_stones[0] = Stone{ .lvl = stone.lvl + 1, .val = stone.val * 2024 };
            }

            //print("{} --> ", .{stone.val});
            for (new_stones) |n_stone_opt| {
                if (n_stone_opt) |new_stone| {
                    //print("{} ", .{new_stone.val});
                    //try seen_stones_idx.put(new_stone.val, Idx{ .pos = seen_stones_idx.count() });
                    if (indexOf(new_stone.val, seen_idx) == null) {
                        try seen_idx.append(alloc, Idx{ .val = new_stone.val });
                    }
                    //const maybe_entry = try dok_stones.getOrPutValue([2]usize{ seen_stones_idx.get(stone.val).?.pos, seen_stones_idx.get(new_stone.val).?.pos }, 0);
                    const maybe_entry = try dok_stones.getOrPutValue([2]usize{ indexOf(new_stone.val, seen_idx).?, indexOf(stone.val, seen_idx).? }, 0);
                    maybe_entry.value_ptr.* += 1;
                    try stones.append(alloc, new_stone);
                }
            }
            //print("\n", .{});
        }
    }

    //for (seen_idx.items, 0..) |entry, idx| {
    //    print("Number: {}, Index: {}\n", .{ entry.val, idx });
    //}

    //var dok_iter = dok_stones.iterator();
    //while (dok_iter.next()) |entry| {
    //    const to, const from = entry.key_ptr.*;
    //    const val = entry.value_ptr.*;
    //    print("{} -> {} x {}\n", .{ seen_idx.items[from].val, seen_idx.items[to].val, val });
    //}

    // Define compressed sparse row
    var csr: struct {
        data: std.ArrayList(num_type) = .empty,
        cols: std.ArrayList(usize) = .empty,
        rows: std.ArrayList(usize) = .empty,
    } = .{};
    defer csr.data.deinit(alloc);
    defer csr.cols.deinit(alloc);
    defer csr.rows.deinit(alloc);
    try csr.rows.append(alloc, 0);

    // Populate CSR NOTE: The slowest part!
    for (0..seen_idx.items.len) |row| {
        for (0..seen_idx.items.len) |col| {
            if (dok_stones.get([2]usize{ row, col })) |val| {
                //print("{} ", .{val});
                try csr.data.append(alloc, val);
                try csr.cols.append(alloc, col);
            } else {
                //print("0 ", .{});
            }
        }
        try csr.rows.append(alloc, csr.data.items.len);
        //print("\n", .{});
    }

    print("Total matrix non-zero: {}\n", .{dok_stones.count()});

    //print("{any}\n{any}\n{any}\n", .{ csr.data.items, csr.cols.items, csr.rows.items });

    // Define vector for multiplication
    var input_vec: std.ArrayList(num_type) = .empty;
    defer input_vec.deinit(alloc);
    try input_vec.appendNTimes(alloc, 0, seen_idx.items.len);

    // Define result vector
    var result_vec = try input_vec.clone(alloc);
    defer result_vec.deinit(alloc);

    // Populate input vector
    for (0..seen_idx.items.len) |row| {
        for (first_stones.items) |stone| {
            if (stone.val == seen_idx.items[row].val) {
                input_vec.items[row] += 1;
                //print("{}\n", .{stone.val});
            }
        }
    }

    //print("Input vector:\n{any}\nRun:\n", .{input_vec.items});

    for (0..limit) |level| {
        for (csr.rows.items[0 .. csr.rows.items.len - 1], csr.rows.items[1..], 0..) |from, to, row| {
            //if (from == to) continue;
            //print("From: {} To: {} Row: {}\n", .{ from, to, row });

            var result: num_type = 0;
            for (csr.data.items[from..to], csr.cols.items[from..to]) |val, col| {
                result += val * input_vec.items[col];
            }

            result_vec.items[row] = result;
        }

        _ = level;
        //print("{any}\n", .{result_vec.items});
        //var total: u64 = 0;
        //for (result_vec.items) |v| total += v;
        //print("\nLevel {}\nTotal: {}\n", .{ level + 1, total });
        //for (result_vec.items, seen_idx.items) |value, idx| {
        //    print("{}\t{}\n", .{ idx.val, value });
        //}

        @memcpy(input_vec.items, result_vec.items);
    }

    //print("Result:\n{any}\n", .{result_vec.items});
    //for (result_vec.items, seen_idx.items) |value, idx| {
    //    print("Value {} ----- Count {}\n", .{ idx.val, value });
    //}

    var sum_stones: num_type = 0;
    for (result_vec.items) |num| sum_stones += num;

    print("Total stones at level {}: {}\n", .{ limit, sum_stones });
}

fn indexOf(num: num_type, a_list: std.ArrayList(Idx)) ?usize {
    for (a_list.items, 0..) |item, idx| {
        if (item.val == num) {
            return idx;
        }
    }
    return null;
}

const CSR = struct {
    data: std.ArrayList(num_type),
    cols: std.ArrayList(usize),
    rows: std.ArrayList(usize),

    const Self = @This();

    fn init(alloc: std.mem.Allocator) Self {
        return Self{
            .data = std.ArrayList(num_type).init(alloc),
            .cols = std.ArrayList(usize).init(alloc),
            .rows = std.ArrayList(usize).init(alloc),
        };
    }

    fn deinit(self: Self) void {
        self.data.deinit();
        self.cols.deinit();
        self.rows.deinit();
    }
};
