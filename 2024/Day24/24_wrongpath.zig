const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // Stores names of gates and values (one bit)
    var vals = std.AutoArrayHashMap([3]u8, ?u1).init(alloc);
    defer vals.deinit();

    var ops: std.ArrayList(Operation) = .empty;
    defer ops.deinit(alloc);

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
                try vals.put(line[0..3].*, try std.fmt.parseInt(u1, line[5..], 10));
            } else {
                var parse_iter = std.mem.tokenizeAny(u8, line, " ->");

                const a = parse_iter.next().?[0..3].*;
                const a_entry = try vals.getOrPut(a);
                if (!a_entry.found_existing) a_entry.value_ptr.* = null;

                const op = Gate.fromU8(parse_iter.next().?[0]);

                const b = parse_iter.next().?[0..3].*;
                const b_entry = try vals.getOrPut(b);
                if (!b_entry.found_existing) b_entry.value_ptr.* = null;

                const c = parse_iter.next().?[0..3].*;
                const c_entry = try vals.getOrPut(c);
                if (!c_entry.found_existing) c_entry.value_ptr.* = null;

                try ops.append(alloc, Operation{ .a = a, .b = b, .op = op, .c = c });
            }
        }
    }

    //print("Initialized with:\n", .{});
    var val_iter = vals.iterator();
    //while (val_iter.next()) |entry| {
    //    print("{s}: {any}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    //}

    //print("\n", .{});
    //for (ops.items) |op| print("{s} {any} {s} -> {s}\n", .{ op.a, op.op, op.b, op.c });

    // Sort so the calculation can be done in one pass.
    {
        var i: usize = 0;
        var seen = std.AutoHashMap([3]u8, void).init(alloc);

        val_iter = vals.iterator();
        while (val_iter.next()) |entry| {
            if (entry.value_ptr.* != null) try seen.put(entry.key_ptr.*, {});
        }

        while (i < ops.items.len) {
            const op = ops.items[i];
            if (seen.contains(op.a) and seen.contains(op.b)) {
                //print("{any} is good at idx {}!\n", .{ op, i });
                try seen.put(op.c, {});
            } else {
                //print("{any} not found at idx {}, rotating.\n", .{ op, i });
                for (i..ops.items.len - 1) |j| {
                    ops.items[j] = ops.items[j + 1];
                }
                ops.items[ops.items.len - 1] = op;
                continue;
            }

            i += 1;
        }
    }

    // With swapping, we still need to do the done check since the sort is being compromised.
    var done = false;
    while (!done) {
        print("Run.\n", .{});
        for (ops.items) |op| {
            if (vals.get(op.a).? == null or vals.get(op.b).? == null) {
                continue;
            }
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

    val_iter = vals.iterator();

    // Delete all non-z
    while (val_iter.next()) |entry| {
        if (entry.key_ptr.*[0] != 'z') {
            if (vals.swapRemove(entry.key_ptr.*)) val_iter = vals.iterator();
        }
    }

    // Sort function
    const C = struct {
        keys: [][3]u8,

        pub fn lessThan(ctx: @This(), a_index: usize, b_index: usize) bool {
            const val_a = std.fmt.parseInt(u8, ctx.keys[a_index][1..3], 10) catch 0;
            const val_b = std.fmt.parseInt(u8, ctx.keys[b_index][1..3], 10) catch 0;
            return val_a > val_b;
        }
    };

    vals.sort(C{ .keys = vals.keys() });

    // Run through sorted list and construct final number
    val_iter = vals.iterator();
    var num: u64 = 0;
    while (val_iter.next()) |entry| {
        print("{s}: {any}\n", .{ entry.key_ptr.*, entry.value_ptr.*.? });
        num <<= 1;
        num |= entry.value_ptr.*.?;
    }

    print("Final: {}\n", .{num});

    print("{} Operations.\n", .{ops.items.len});
}

const Operation = struct {
    a: [3]u8,
    b: [3]u8,
    op: Gate,
    c: [3]u8,

    fn lessThan(_: @TypeOf(.{}), lhs: Operation, rhs: Operation) bool {
        const a_match: bool = for (lhs.a, rhs.c) |a, c| {
            if (a != c) break false;
        } else true;

        const b_match: bool = for (lhs.b, rhs.c) |b, c| {
            if (b != c) break false;
        } else true;

        return !(a_match or b_match);
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
