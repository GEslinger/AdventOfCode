const std = @import("std");
const print = std.debug.print;
const num_type = u64;
const Stone = struct { val: num_type, lvl: u8 };
const Idx = struct { pos: usize, explored: bool = false };
const Idx2 = struct { val: usize, explored: bool = false };

pub fn main() !void {
    print("Hello, world!\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    var alloc = gpa.allocator();
    defer _ = gpa.deinit();

    const file = try std.fs.cwd().openFile("zero", .{});
    defer file.close();
    const contents = try file.readToEndAlloc(alloc, 1_000_000);
    defer alloc.free(contents);

    print("Contents:\n{s}\n", .{contents});

    var stones = std.ArrayList(Stone).init(alloc);
    defer stones.deinit();

    {
        var first_stones_strings = std.mem.tokenizeAny(u8, contents, " \n");
        while (first_stones_strings.next()) |stone_string| {
            const new_stone = Stone{ .lvl = 0, .val = std.fmt.parseInt(num_type, stone_string, 10) catch break };
            try stones.append(new_stone);
        }
    }

    var seen_idx = std.ArrayList(Idx2).init(alloc);
    defer seen_idx.deinit();

    // Dictionary of keys to construct sparse matrix
    var dok_stones = std.AutoHashMap([2]usize, num_type).init(alloc);
    defer dok_stones.deinit();

    var fmt_buf: [1_000]u8 = undefined;
    var counter: u128 = 0;
    const limit = 25;
    while (stones.pop()) |stone| {
        if (stone.lvl == limit) {
            counter += 1;
            //print("bottomed out!\n", .{});
            continue;
        }
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
            try seen_idx.append(Idx2{ .val = stone.val, .explored = false });
        }
        if (!explored) {
            //print("Exploring {}\n", .{stone.val});
            const seen_idx_pos = indexOf(stone.val, seen_idx).?;
            //print("This is at index {}\n", .{seen_idx_pos});
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

            print("{} --> ", .{stone.val});
            for (new_stones) |n_stone_opt| {
                if (n_stone_opt) |new_stone| {
                    print("{} ", .{new_stone.val});
                    //try seen_stones_idx.put(new_stone.val, Idx{ .pos = seen_stones_idx.count() });
                    if (indexOf(new_stone.val, seen_idx) == null) try seen_idx.append(Idx2{ .val = new_stone.val });
                    //const maybe_entry = try dok_stones.getOrPutValue([2]usize{ seen_stones_idx.get(stone.val).?.pos, seen_stones_idx.get(new_stone.val).?.pos }, 0);
                    const maybe_entry = try dok_stones.getOrPutValue([2]usize{ indexOf(stone.val, seen_idx).?, indexOf(new_stone.val, seen_idx).? }, 0);
                    maybe_entry.value_ptr.* += 1;
                    try stones.append(new_stone);
                }
            }
            print("\n", .{});
        }
    }

    for (seen_idx.items, 0..) |entry, idx| {
        print("Number: {}, Index: {}\n", .{ entry.val, idx });
    }

    // Initialize compressed sparse row matrix
    var csr = CSR.init(alloc);
    defer csr.deinit();
    try csr.rows.appendNTimes(0, seen_idx.items.len + 1);

    var dok_iter = dok_stones.iterator();
    while (dok_iter.next()) |dok_entry| {
        print("\n\n{any}\n{any}\n{any}\n", .{ csr.data.items, csr.cols.items, csr.rows.items });
        const coords = dok_entry.key_ptr.*;
        const dok_val = dok_entry.value_ptr.*;

        const row_start = csr.rows.items[coords[0]];
        var row_end = csr.rows.items[coords[0] + 1];
        if (row_start == row_end) {
            for ((coords[0] + 1)..csr.rows.items.len) |change_index| {
                csr.rows.items[change_index] += 1;
            }
            row_end = csr.rows.items[coords[0] + 1];
            try csr.data.insert(row_start, dok_val);
            try csr.cols.insert(row_start, coords[1]);
            print("Looking at {}, pos {any}\nCSR range is {} .. {}\n", .{ dok_val, coords, row_start, row_end });
            continue;
        }
        print("Looking at {}, pos {any}\nCSR range is {} .. {}\n", .{ dok_val, coords, row_start, row_end });

        for (row_start..row_end) |csr_index| {
            if (coords[1] < csr.cols.items[csr_index]) {
                print("Please don't overflow {} + 1 and {}\n", .{ csr_index, csr.rows.items.len });
                for ((csr_index + 1)..csr.rows.items.len) |change_index| {
                    csr.rows.items[change_index] += 1;
                }
                try csr.data.insert(csr_index, dok_val);
                try csr.cols.insert(csr_index, coords[1]);
            }
        }

        //print("{} --> {} recorded {} times\n", .{ seen_idx.items[coords[0]].val, seen_idx.items[coords[1]].val, dok_val });
    }
}

fn indexOf(num: num_type, a_list: std.ArrayList(Idx2)) ?usize {
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
