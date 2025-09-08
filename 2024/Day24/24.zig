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

    print("Initialized with:\n", .{});
    var val_iter = vals.iterator();
    while (val_iter.next()) |entry| {
        print("{s}: {any}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }

    print("\n", .{});
    for (ops.items) |op| print("{s} {any} {s} -> {s}\n", .{ op.a, op.op, op.b, op.c });

    for (0..45) |input_bit| {
        var try_vals = try vals.clone();

        for (0..45) |reset_bit| {
            var buf: [3]u8 = undefined;
            var reset = try std.fmt.bufPrint(&buf, "y{d:0>2}", .{reset_bit});
            if (try_vals.getPtr(buf)) |val_ptr| val_ptr.* = 0;
            reset = try std.fmt.bufPrint(&buf, "x{d:0>2}", .{reset_bit});
            if (try_vals.getPtr(buf)) |val_ptr| val_ptr.* = 0;
        }
    }
<<<<<<< HEAD

        _ = input_bit;

        var done = false;
        while (!done) {
            for (ops.items) |op| {
                if (try_vals.get(op.a).? == null or try_vals.get(op.b).? == null) continue;
                const a = try_vals.get(op.a).?.?;
                const b = try_vals.get(op.b).?.?;

                const c_value = try_vals.getEntry(op.c).?.value_ptr;
                c_value.* = switch (op.op) {
                    .XOR => a ^ b,
                    .AND => a & b,
                    .OR => a | b,
                };
            }

            // Check if all z.. gates are not null
            var check_done_iter = try_vals.iterator();
            done = while (check_done_iter.next()) |entry| {
                if (entry.key_ptr.*[0] == 'z' and entry.value_ptr.* == null) break false;
            } else true;
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
}

const Operation = struct {
    a: [3]u8,
    b: [3]u8,
    op: Gate,
    c: [3]u8,
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
