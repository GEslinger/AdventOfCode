const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var a: u64 = undefined;
    var b: u64 = undefined;
    var c: u64 = undefined;

    var program: std.ArrayList(u3) = .empty;

    {
        var file = try std.fs.cwd().openFile("input", .{});
        defer file.close();

        const contents = try file.readToEndAlloc(alloc, 1_000_000);

        var lines = std.mem.tokenizeAny(u8, contents, "\r\n");

        a = try std.fmt.parseInt(u64, (lines.next().?)[12..], 10);
        b = try std.fmt.parseInt(u64, (lines.next().?)[12..], 10);
        c = try std.fmt.parseInt(u64, (lines.next().?)[12..], 10);

        var pgm_iter = std.mem.tokenizeAny(u8, lines.next().?[9..], ",");
        while (pgm_iter.next()) |pgm_value| try program.append(alloc, try std.fmt.parseInt(u3, pgm_value, 10));
    }

    print("A: {}\nB: {}\nC: {}\n", .{ a, b, c });
    print("Program: {any}\n", .{program.items});

    a = 0;
    const b_orig = b;
    const c_orig = c;

    var output_array: std.ArrayList(u64) = .empty;

    var try_a: u64 = 0;
    var inc: u64 = 1;
    var jej: usize = 0;
    var level_tries: u64 = 0;
    var last_spot: u64 = 0;
    while (jej < 1000) {
        a = try_a;
        b = b_orig;
        c = c_orig;
        try runProgram(program.items, &a, &b, &c, alloc, &output_array);

        print("A: {}, Output: {any}\n", .{ try_a, output_array.items });
        if (output_array.items.len == program.items.len) break;

        const done_ok: bool = for (output_array.items, 0..) |out_val, i| {
            if (i >= program.items.len) break false;
            if (out_val != program.items[i]) break false;
        } else blk: {
            break :blk true;
        };

        if (done_ok) {
            level_tries = 0;
            last_spot = try_a;
            inc <<= 1;
        } else if (level_tries > 256) {
            level_tries = 0;
            inc >>= 1;
            try_a = last_spot;
        }

        try_a += inc;
        level_tries += 1;
        output_array.clearRetainingCapacity();
        jej += 1;
    }
}

fn runProgram(pgm: []u3, a: *u64, b: *u64, c: *u64, alloc: ?std.mem.Allocator, out_array: ?*std.ArrayList(u64)) !void {
    var instr_ptr: u64 = 0;

    //print("Program: {any}\n", .{pgm});

    while (instr_ptr < pgm.len - 1) {
        const opts = [2]u3{ pgm[instr_ptr], pgm[instr_ptr + 1] };
        //print("I_ptr: {}, Step begins A: {} B:{} C:{}, opts: {any}\n", .{ instr_ptr, a.*, b.*, c.*, opts });

        const result = step(opts, a.*, b.*, c.*);
        a.*, b.*, c.* = .{ result.a, result.b, result.c };
        //print("Step ends A: {} B:{} C:{}, out: {any}\n", .{ a.*, b.*, c.*, result.out });

        if (result.out) |out| {
            //if (out_array.?.items.len >= pgm.len) return ProgramError.NotRight;
            //if (out != pgm[out_array.?.items.len]) return ProgramError.NotRight;
            try out_array.?.append(alloc.?, out);
        }
        if (result.jump) |new_instr_ptr| {
            instr_ptr = new_instr_ptr;
        } else {
            instr_ptr += 2;
        }
    }
}

const ProgramError = error{NotRight};

test "1" {
    const o = step([_]u3{ 2, 6 }, 0, 0, 9);
    try std.testing.expect(o.b == 1);
}

test "2" {
    const alloc = std.testing.allocator;
    var pgm = [_]u3{ 5, 0, 5, 1, 5, 4 };
    var output_array: std.ArrayList(u64) = .empty;
    defer output_array.deinit(alloc);

    var a: u64 = 10;
    var b: u64 = 0;
    var c: u64 = 0;

    try runProgram(pgm[0..], &a, &b, &c, alloc, &output_array);

    const expect_output = [_]u64{ 0, 1, 2 };
    for (output_array.items, 0..) |out, i| try std.testing.expect(out == expect_output[i]);
}

test "3" {
    const alloc = std.testing.allocator;
    var pgm = [_]u3{ 0, 1, 5, 4, 3, 0 };
    var output_array: std.ArrayList(u64) = .empty;
    defer output_array.deinit(alloc);

    var a: u64 = 2024;
    var b: u64 = 0;
    var c: u64 = 0;

    try runProgram(pgm[0..], &a, &b, &c, alloc, &output_array);

    const expect_output = [_]u64{ 4, 2, 5, 6, 7, 7, 7, 7, 3, 1, 0 };
    for (output_array.items, 0..) |out, i| try std.testing.expect(out == expect_output[i]);
    try std.testing.expect(a == 0);
}

test "4" {
    const o = step([_]u3{ 1, 7 }, 0, 29, 0);
    try std.testing.expect(o.b == 26);
}

test "5" {
    const o = step([_]u3{ 4, 0 }, 0, 2024, 43690);
    try std.testing.expect(o.b == 44354);
}

fn step(ops: [2]u3, a: u64, b: u64, c: u64) StepOutput {
    var output = StepOutput{
        .a = a,
        .b = b,
        .c = c,
        .out = null,
        .jump = null,
    };

    const operator: Instruction = @enumFromInt(ops[0]);
    const lit_operand: u64 = @intCast(ops[1]);
    const combo_operand: ?u64 = switch (ops[1]) {
        0...3 => @intCast(ops[1]),
        4 => a,
        5 => b,
        6 => c,
        7 => null,
    };

    switch (operator) {
        .adv => output.a >>= @intCast(combo_operand.?), //@divTrunc(a, std.math.pow(u64, 2, combo_operand.?)),
        .bxl => output.b ^= lit_operand,
        .bst => output.b = combo_operand.? % 8,
        .jnz => {
            if (a != 0) output.jump = lit_operand;
        },
        .bxc => output.b = b ^ c,
        .out => output.out = combo_operand.? % 8,
        .bdv => output.b = a >> @intCast(combo_operand.?), //@divTrunc(a, std.math.pow(u64, 2, combo_operand.?)),
        .cdv => output.c = a >> @intCast(combo_operand.?), //@divTrunc(a, std.math.pow(u64, 2, combo_operand.?)),
    }

    return output;
}

const StepOutput = struct { a: u64, b: u64, c: u64, out: ?u64, jump: ?u64 };

const Instruction = enum(u3) { adv, bxl, bst, jnz, bxc, out, bdv, cdv };
