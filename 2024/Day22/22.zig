const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var starts: std.ArrayList(u64) = .empty;
    {
        var file = try std.fs.cwd().openFile("input", .{});
        defer file.close();
        const contents = try file.readToEndAlloc(alloc, 1_000_000);

        var line_iter = std.mem.tokenizeAny(u8, contents, "\r\n");
        var line_count: usize = 0;
        while (line_iter.next()) |line| {
            const start_num = try std.fmt.parseInt(u64, line, 10);
            try starts.append(alloc, start_num);
            line_count += 1;
        }
        print("{} lines.\n", .{line_count});
    }

    // NOTE: Part 1.

    //var total: u64 = 0;
    //for (starts.items) |start| {
    //    var x = start;
    //    for (0..2000) |_| {
    //        x = next(x);
    //    }
    //    //print("{}: {}\n", .{ start, x });
    //    total += x;
    //}
    //print("Total: {}\n", .{total});

    var earnings_map = std.AutoHashMap([4]i8, u32).init(alloc);
    var exclusion_map = std.AutoHashMap([4]i8, void).init(alloc);

    for (starts.items) |start| {
        var x = start;

        var seq = [4]i8{ 0, 0, 0, 0 };
        for (0..2000) |i| {
            const new = next(x);
            const x_last: i8 = @intCast(x % 10);
            const new_last: i8 = @intCast(new % 10);

            seq[0] = seq[1];
            seq[1] = seq[2];
            seq[2] = seq[3];
            seq[3] = new_last - x_last;

            //print("i: {}, seq:{any}\n", .{ i, seq });

            if (i >= 3 and !exclusion_map.contains(seq)) {
                const entry = try earnings_map.getOrPut(seq);
                if (entry.found_existing) {
                    entry.value_ptr.* += @as(u32, @intCast(new_last));
                } else {
                    entry.value_ptr.* = @as(u32, @intCast(new_last));
                }

                //print("New value for {any}: {}\n", .{ entry.key_ptr.*, entry.value_ptr.* });

                try exclusion_map.put(seq, {});
            } else {
                //print("Excluded.\n", .{});
            }

            x = new;
        }

        exclusion_map.clearRetainingCapacity();
    }

    var earnings_iter = earnings_map.iterator();
    var highest_earnings: u32 = 0;
    var best_seq: [4]i8 = undefined;
    while (earnings_iter.next()) |earnings_entry| {
        const seq = earnings_entry.key_ptr.*;
        const earnings = earnings_entry.value_ptr.*;

        if (earnings > highest_earnings) {
            highest_earnings = earnings;
            best_seq = seq;
        }
    }

    print("Best seq: {any} making {}\n", .{ best_seq, highest_earnings });
}

test "next" {
    const expect = [_]u64{ 15887950, 16495136, 527345, 704524, 1553684, 12683156, 11100544, 12249484, 7753432, 5908254 };

    var x: u64 = 123;
    for (0..9) |i| {
        x = next(x);
        try std.testing.expect(x == expect[i]);
    }
}

fn next(x: u64) u64 {
    const a = (x ^ (x << 6)) % 16777216;
    const b = (a ^ (a / 32)) % 16777216;
    const c = (b ^ (b << 11)) % 16777216;

    //print("In: {}, Out: {}\n", .{ x, c });
    return c;
}
