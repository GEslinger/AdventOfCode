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

    // Work at sorting into an ordered full-adder sequence
    var ops_sorted: std.ArrayList(Operation) = .empty;
    var bit: usize = 0;

    var swaps: std.ArrayList([3]u8) = .empty;
    {
        var x_in: [3]u8 = undefined;
        var y_in: [3]u8 = undefined;
        var half_add: *Operation = undefined;
        var carry_1: *Operation = undefined;
        var z_out: *Operation = undefined;
        var carry_2: *Operation = undefined;
        var carry_out: *Operation = undefined;

        //var print_buf: [50]u8 = undefined;
        while (bit < 45) {
            // Get inputs
            _ = try std.fmt.bufPrint(&x_in, "x{d:0>2}", .{bit});
            _ = try std.fmt.bufPrint(&y_in, "y{d:0>2}", .{bit});
            print("Bit {}\n", .{bit});

            // Half adder
            half_add = findOrSwap(&ops, &swaps, x_in, y_in, Gate.XOR, alloc);
            carry_1 = findOrSwap(&ops, &swaps, x_in, y_in, Gate.AND, alloc);
            if (bit == 0) {
                z_out = half_add;
                carry_out = carry_1;
            } else {
                // Finish full adder
                z_out = findOrSwap(&ops, &swaps, carry_out.c, half_add.c, Gate.XOR, alloc);
                carry_2 = findOrSwap(&ops, &swaps, carry_out.c, half_add.c, Gate.AND, alloc);
                carry_out = findOrSwap(&ops, &swaps, carry_1.c, carry_2.c, Gate.OR, alloc);
            }

            _ = &ops_sorted;
            bit += 1;
        }
    }

    std.mem.sort([3]u8, swaps.items, {}, lessStr);

    for (swaps.items) |swap| print("{s},", .{swap});
    print("\n", .{});

    // Reference
    var full_adder: std.ArrayList(Operation) = .empty;
    try full_adder.append(alloc, Operation{ .a = "xin".*, .b = "yin".*, .op = Gate.XOR, .c = "haf".* }); // Half add
    try full_adder.append(alloc, Operation{ .a = "xin".*, .b = "yin".*, .op = Gate.AND, .c = "ca1".* }); // Carry 1
    try full_adder.append(alloc, Operation{ .a = "cin".*, .b = "haf".*, .op = Gate.XOR, .c = "zot".* }); // Z out
    try full_adder.append(alloc, Operation{ .a = "cin".*, .b = "haf".*, .op = Gate.AND, .c = "ca2".* }); // Carry 2
    try full_adder.append(alloc, Operation{ .a = "ca1".*, .b = "ca2".*, .op = Gate.OR, .c = "cot".* }); // Carry out
    // NOTE: Compare structure by cleverly sorting each level of full adder, making sure
    // gates are connected in the right way

}

fn lessStr(_: void, a: [3]u8, b: [3]u8) bool {
    for (a, b) |x, y| {
        if (x == y) continue;
        return x < y;
    }
    return false;
}

fn findOrSwap(ops: *std.ArrayList(Operation), swaps: *std.ArrayList([3]u8), a: [3]u8, b: [3]u8, g: Gate, alloc: std.mem.Allocator) *Operation {
    var found = findOp(ops, a, b, g);
    if (found) |out| return out;

    // Othewise we have work to do!
    // We can assume a or b (output of last call) needs to be swapped.
    // So let's try swapping either one for any other? Ops will be modified
    // And we should store a "copy" of the confirmed swap operation
    var buf: [50]u8 = undefined;

    print("DNE: {s} {any} {s} -> ...\n", .{ a, g, b });
    for (ops.items) |*op| {
        if (std.mem.eql(u8, &a, &op.c)) {
            print("Candidate for a: {s}\n", .{op.text(&buf).?});
            const tmp = op.*.c;

            for (ops.items) |*swap_op| {
                // Swap
                op.c = swap_op.c;
                swap_op.c = tmp;

                //print("Now we have:\n\t{s}\n\t", .{op.text(&buf).?});
                //print("{s}\n", .{swap_op.text(&buf).?});

                found = findOp(ops, op.c, b, g);
                if (found) |out| {
                    print("Swapping with {s}\n", .{op.c});
                    swaps.append(alloc, op.c) catch unreachable;
                    swaps.append(alloc, swap_op.c) catch unreachable;
                    return out;
                }

                // Unswap
                swap_op.c = op.c;
                op.c = tmp;
            }
        }

        if (std.mem.eql(u8, &b, &op.c)) {
            print("Candidate for b: {s}\n", .{op.text(&buf).?});
            const tmp = op.*.c;

            for (ops.items) |*swap_op| {
                // Swap
                op.c = swap_op.c;
                swap_op.c = tmp;

                //print("Now we have:\n\t{s}\n\t", .{op.text(&buf).?});
                //print("{s}\n", .{swap_op.text(&buf).?});

                found = findOp(ops, a, op.c, g);
                if (found) |out| {
                    print("Swapping with {s}\n", .{op.c});
                    swaps.append(alloc, op.c) catch unreachable;
                    swaps.append(alloc, swap_op.c) catch unreachable;
                    return out;
                }

                // Unswap
                swap_op.c = op.c;
                op.c = tmp;
            }
        }
    }

    return found.?; // Panics, just to make it compile
}

fn findOp(ops: *std.ArrayList(Operation), a: [3]u8, b: [3]u8, g: Gate) ?*Operation {
    //print("Try to find {s} {any} {s} -> ...\n", .{ a, g, b });
    for (ops.items) |*op| {
        const a_ok = if (std.mem.eql(u8, &a, &op.a) or std.mem.eql(u8, &a, &op.b)) true else false;
        const b_ok = if (std.mem.eql(u8, &b, &op.a) or std.mem.eql(u8, &b, &op.b)) true else false;
        const g_ok = if (op.op == g) true else false;

        if (a_ok and b_ok and g_ok) return op;
    }

    return null;
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

    fn text(self: *Operation, buf: []u8) ?[]u8 {
        return std.fmt.bufPrint(buf, "{s} {any} {s} -> {s}", .{ self.a, self.op, self.b, self.c }) catch null;
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
