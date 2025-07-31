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

    const pattern = "mul(\\d+,\\d+)";
    _ = pattern;

    var enables = std.ArrayList(usize).init(alloc);
    defer enables.deinit();
    try enables.append(0);

    var finder = Tokenizer.init(contents);
    while (finder.grabCharSeq("do(")) |do_pos| {
        print("do at: {}\n", .{do_pos});
        try enables.append(do_pos);
    }

    finder.reset();

    var disables = std.ArrayList(usize).init(alloc);
    defer disables.deinit();

    while (finder.grabCharSeq("don")) |do_pos| {
        try disables.append(do_pos);
    }

    finder.reset();
    var added_muls: u64 = 0;
    var count: u64 = 0;
    var enabled = true;
    while (finder.grabCharSeq("mul(")) |num_1_start| {
        //print("mul at {}, last enable {} last disable {}\n", .{ num_1_start, enables.items[0], disables.items[0] });
        if (disables.items.len > 0) {
            if (disables.items[0] < num_1_start) {
                enabled = false;
                _ = disables.orderedRemove(0);
                continue;
            }
        }
        if (enables.items.len > 0) {
            if (enables.items[0] < num_1_start) {
                enabled = true;
                _ = enables.orderedRemove(0);
            }
        }

        if (!enabled) continue;
        var d: u64 = 0;
        const num_1: u64 = for (0..3) |digits| {
            d = 3 - digits;
            break std.fmt.parseInt(u64, contents[num_1_start .. num_1_start + (3 - digits)], 10) catch continue;
        } else continue;

        var num_2_start: usize = undefined;
        if (contents[num_1_start + d] == ',') {
            num_2_start = num_1_start + d + 1;
        } else continue;

        const num_2: u64 = for (0..3) |digits| {
            d = 3 - digits;
            break std.fmt.parseInt(u64, contents[num_2_start .. num_2_start + (3 - digits)], 10) catch continue;
        } else continue;

        var num_2_end: usize = undefined;
        if (contents[num_2_start + d] == ')') {
            num_2_end = num_2_start + d;
        } else continue;

        added_muls += @mulWithOverflow(num_1, num_2)[0];
        count += 1;
    }

    print("Count:{}\nAdded muls: {}\n", .{ count, added_muls });
}

const Tokenizer = struct {
    contents: []const u8,
    pos: usize,

    fn grabCharSeq(self: *Tokenizer, seq: []const u8) ?usize {
        while (true) {
            if (self.pos + seq.len + 1 >= self.contents.len) return null;

            var match_pos: usize = 0;
            while (seq[match_pos] == self.contents[self.pos + match_pos]) {
                match_pos += 1;
                if (match_pos >= seq.len) {
                    self.pos += seq.len;
                    return self.pos;
                }
            }

            self.pos += 1;
            //Fallback
            //return null;
        }
    }

    fn reset(self: *Tokenizer) void {
        self.pos = 0;
    }

    fn init(input: []const u8) Tokenizer {
        return .{
            .contents = input,
            .pos = 0,
        };
    }
};

const E = error{AllDone};
