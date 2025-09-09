const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // Stores names of gates and values (one bit)
    var vals_init = std.AutoArrayHashMap([3]u8, ?u1).init(alloc);
    defer vals_init.deinit();

    var ops: std.ArrayList(Operation) = .empty;
    defer ops.deinit(alloc);

    var suspect_z = std.AutoHashMap([3]u8, void).init(alloc);
    defer suspect_z.deinit();

    {
        var file = try std.fs.cwd().openFile("input", .{});
        defer file.close();
        const contents = try file.readToEndAlloc(alloc, 1_000_000);

        var line_iter = std.mem.splitAny(u8, contents, "\n");
        var line_count: usize = 0;
        var init = true;
        while (line_iter.next()) |dirty_line| : (line_count += 1) {
            const line = std.mem.trimEnd(u8, dirty_line, "\r");

            if (line.len < 3) {
                init = false;
                continue;
            }

            if (init) {
                try vals_init.put(line[0..3].*, try std.fmt.parseInt(u1, line[5..], 10));
            } else {
                var parse_iter = std.mem.tokenizeAny(u8, line, " ->");

                const a = parse_iter.next().?[0..3].*;
                const a_entry = try vals_init.getOrPut(a);
                if (!a_entry.found_existing) a_entry.value_ptr.* = null;

                const op = Gate.fromU8(parse_iter.next().?[0]);

                const b = parse_iter.next().?[0..3].*;
                const b_entry = try vals_init.getOrPut(b);
                if (!b_entry.found_existing) b_entry.value_ptr.* = null;

                const c = parse_iter.next().?[0..3].*;
                const c_entry = try vals_init.getOrPut(c);
                if (!c_entry.found_existing) c_entry.value_ptr.* = null;

                try ops.append(alloc, Operation{ .a = a, .b = b, .op = op, .c = c });
            }
        }
    }

    print("Initialized with:\n", .{});
    var val_iter = vals_init.iterator();
    while (val_iter.next()) |entry| {
        print("{s}: {any}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }

    print("\n", .{});
    for (ops.items) |op| print("{s} {any} {s} -> {s}\n", .{ op.a, op.op, op.b, op.c });

    var swaps: std.ArrayList([2]*const [3]u8) = .empty;
    _ = swaps.pop();
    try swaps.append(alloc, [2]*const [3]u8{ "z10", "tdj" });
    try swaps.append(alloc, [2]*const [3]u8{ "jtg", "ghp" });
    try swaps.append(alloc, [2]*const [3]u8{ "cpm", "krs" });
    try swaps.append(alloc, [2]*const [3]u8{ "nks", "z21" });

    // cpm,ghp,jtg,krs,nks,tdj,z10,z21

    {
        var a: *Operation = undefined;
        var b: *Operation = undefined;
        for (swaps.items) |swap| {
            for (ops.items) |*op| {
                if (std.mem.eql(u8, swap[0], &op.c)) a = op;
                if (std.mem.eql(u8, swap[1], &op.c)) b = op;
            }
            a.swap(b);
        }
    }

    for (0..45) |input_bit| {
        var x_key: [3]u8 = undefined;
        _ = try std.fmt.bufPrint(&x_key, "x{d:0>2}", .{input_bit});
        var y_key: [3]u8 = undefined;
        _ = try std.fmt.bufPrint(&y_key, "y{d:0>2}", .{input_bit});
        var z_upper_key: [3]u8 = undefined;
        _ = try std.fmt.bufPrint(&z_upper_key, "z{d:0>2}", .{input_bit + 1});
        var z_lower_key: [3]u8 = undefined;
        _ = try std.fmt.bufPrint(&z_lower_key, "z{d:0>2}", .{input_bit});

        print("Will change {s} and {s} monitoring {s} and {s}\n", .{ x_key, y_key, z_lower_key, z_upper_key });

        var vals: std.AutoArrayHashMap([3]u8, ?u1) = undefined;
        for (0..4) |i| {
            const t_0 = i & 1;
            const t_1 = i >> 1;

            vals = try vals_init.clone();
            try resetVals(&vals);
            if (t_0 == 1) vals.getPtr(x_key).?.* = 1;
            if (t_1 == 1) vals.getPtr(y_key).?.* = 1;
            runPrg(ops.items, &vals);
            {
                const z_0 = vals.get(z_lower_key).?.?;
                const z_1 = vals.get(z_upper_key).?.?;
                if (z_0 != (t_0 ^ t_1)) {
                    print("Failed with x:{} y:{} z:{}{}\n", .{ t_0, t_1, z_1, z_0 });
                    try suspect_z.put(z_lower_key, {});
                }
                if (z_1 != (t_0 & t_1)) {
                    print("Failed with x:{} y:{} z:{}{}\n", .{ t_0, t_1, z_1, z_0 });
                    try suspect_z.put(z_upper_key, {});
                }
            }
        }
    }

    var suspect_ops = std.AutoHashMap(*Operation, [3]u8).init(alloc);
    defer suspect_ops.deinit();

    var sus_z_iter = suspect_z.iterator();
    while (sus_z_iter.next()) |z| {
        var sus_search: std.ArrayList(struct { *Operation, [3]u8 }) = .empty;
        for (ops.items) |*op| {
            if (std.mem.eql(u8, &op.c, z.key_ptr)) {
                try sus_search.append(alloc, .{ op, op.c });
                print("{any}\n", .{op.*});
            }
        }

        while (sus_search.pop()) |sus_op| {
            try suspect_ops.put(sus_op.@"0", sus_op.@"1");

            for (ops.items) |*op| {
                if (std.mem.eql(u8, &sus_op.@"0".a, &op.c) or
                    std.mem.eql(u8, &sus_op.@"0".b, &op.c))
                {
                    try suspect_ops.put(op, sus_op.@"1");
                }
            }
        }
    }
    print("\n", .{});

    var sus_op_iter = suspect_ops.iterator();
    while (sus_op_iter.next()) |entry| {
        const op = entry.key_ptr.*;
        print("Tracked to {s} - {s} {any} {s} -> {s}\n", .{ entry.value_ptr.*, op.a, op.op, op.b, op.c });
    }
    print("total sus ops: {}\n", .{suspect_ops.count()});

    {
        return;
    }

    // Time to find the right swaps
    //    var swaps: std.ArrayList(struct { [2]*Operation, bool }) = .empty;
    //    var ops_swapped: std.ArrayList(Operation) = undefined;
    //    var focus_bit: ?usize = null;
    //    swap: while (true) {
    //        var vals: std.AutoArrayHashMap([3]u8, ?u1) = undefined;
    //
    //        if (focus_bit) |f| {
    //            //print("Focus {}\n", .{f});
    //            sus_op_iter = suspect_ops.iterator();
    //            while (sus_op_iter.next()) |entry| {
    //                const op = entry.key_ptr.*;
    //                const relevant = entry.value_ptr.*;
    //                const z_lower_bit = std.fmt.parseInt(usize, relevant[1..], 10) catch 99;
    //                //print("Comparing {} and {} (+1)\n", .{ z_lower_bit, f });
    //
    //                if (f == z_lower_bit or f + 1 == z_lower_bit) {
    //                    const what = sus_op_iter.next().?.key_ptr.*;
    //                    print("gonna try swapping {any} and {any}\n", .{ op.*, what.* });
    //                    try swaps.append(alloc, .{ [2]*Operation{ op, what }, true });
    //                }
    //            }
    //            focus_bit = null;
    //        }
    //
    //        ops_swapped = try ops.clone(alloc);
    //        for (swaps.items) |swap| {
    //            if (!swap.@"1") continue;
    //            swap.@"0"[0].swap(swap.@"0"[1]);
    //        }
    //
    //        // Test - could just do the suspect ones to speed up?
    //        for (0..45) |input_bit| {
    //            var x_key: [3]u8 = undefined;
    //            _ = try std.fmt.bufPrint(&x_key, "x{d:0>2}", .{input_bit});
    //            var y_key: [3]u8 = undefined;
    //            _ = try std.fmt.bufPrint(&y_key, "y{d:0>2}", .{input_bit});
    //            var z_upper_key: [3]u8 = undefined;
    //            _ = try std.fmt.bufPrint(&z_upper_key, "z{d:0>2}", .{input_bit + 1});
    //            var z_lower_key: [3]u8 = undefined;
    //            _ = try std.fmt.bufPrint(&z_lower_key, "z{d:0>2}", .{input_bit});
    //
    //            print("Checking if OK {}\n", .{input_bit});
    //
    //            for (0..4) |i| {
    //                const t_0 = i & 1;
    //                const t_1 = i >> 1;
    //
    //                vals = try vals_init.clone();
    //                try resetVals(&vals);
    //                if (t_0 == 1) vals.getPtr(x_key).?.* = 1;
    //                if (t_1 == 1) vals.getPtr(y_key).?.* = 1;
    //                runPrg(ops.items, &vals);
    //                {
    //                    const z_0 = vals.get(z_lower_key).?.?;
    //                    const z_1 = vals.get(z_upper_key).?.?;
    //                    if (z_0 != (t_0 ^ t_1) or z_1 != (t_0 & t_1)) {
    //                        print("Failed with x:{} y:{} z:{}{}\n", .{ t_0, t_1, z_1, z_0 });
    //                        if (focus_bit) |_| {
    //                            swaps.items[swaps.items.len - 1].@"1" = false;
    //                        }
    //                        focus_bit = input_bit;
    //
    //                        continue :swap;
    //                    }
    //                }
    //            }
    //        }
    //
    //        // Break the loop if not continued.
    //        break;
    //    }
}

fn resetVals(vals: *std.AutoArrayHashMap([3]u8, ?u1)) !void {
    for (0..45) |reset_bit| {
        var buf: [3]u8 = undefined;
        var reset = try std.fmt.bufPrint(&buf, "y{d:0>2}", .{reset_bit});
        if (vals.getPtr(buf)) |val_ptr| val_ptr.* = 0;
        reset = try std.fmt.bufPrint(&buf, "x{d:0>2}", .{reset_bit});
        if (vals.getPtr(buf)) |val_ptr| val_ptr.* = 0;
    }
}

fn runPrg(ops: []Operation, vals: *std.AutoArrayHashMap([3]u8, ?u1)) void {
    var done = false;
    while (!done) {
        for (ops) |op| {
            if (vals.get(op.a).? == null or vals.get(op.b).? == null) continue;
            const a = vals.get(op.a).?.?;
            const b = vals.get(op.b).?.?;

            const c_value = vals.getEntry(op.c).?.value_ptr;
            c_value.* = switch (op.op) {
                .XOR => a ^ b,
                .AND => a & b,
                .OR => a | b,
            };
        }

        // Check if all z.. gates are not null
        var check_done_iter = vals.iterator();
        done = while (check_done_iter.next()) |entry| {
            if (entry.key_ptr.*[0] == 'z' and entry.value_ptr.* == null) break false;
        } else true;
    }
}

const Operation = struct {
    a: [3]u8,
    b: [3]u8,
    op: Gate,
    c: [3]u8,

    fn swap(self: *Operation, other: *Operation) void {
        std.mem.swap([3]u8, &self.c, &other.c);
    }
};

const Gate = enum {
    AND,
    XOR,
    OR,

    fn fromU8(char: u8) Gate {
        return switch (char) {
            'A' => Gate.AND,
            'X' => Gate.XOR,
            'O' => Gate.OR,
            else => unreachable,
        };
    }
};
