const std = @import("std");
const assert = std.debug.assert;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var input = try std.fs.cwd().openFile("input", .{});
    defer input.close();

    const contents = try input.readToEndAlloc(alloc, 1_000_000);
    defer alloc.free(contents);
    var lines = std.mem.tokenizeAny(u8, contents, "\n");
    const c = std.mem.count(u8, contents, "\n");

    std.debug.print("{} lines.\n", .{c});

    var list_1 = try alloc.alloc(i64, c);
    defer alloc.free(list_1);
    var list_2 = try alloc.alloc(i64, c);
    defer alloc.free(list_2);

    var list2_occurences = std.AutoHashMap(i64, i64).init(alloc);
    defer list2_occurences.deinit();

    var i: usize = 0;
    while (lines.next()) |line| : (i += 1) {
        var tokens = std.mem.tokenizeAny(u8, line, " ");
        list_1[i] = try std.fmt.parseInt(i64, tokens.next().?, 10);
        list_2[i] = try std.fmt.parseInt(i64, tokens.next().?, 10);

        const result = (try list2_occurences.getOrPut(list_2[i]));
        if (result.found_existing) {
            result.value_ptr.* += 1;
        } else {
            result.value_ptr.* = 1;
        }
        // std.debug.print("1:{}\t2:{}\n", .{ list_1[i], list_2[i] });
    }

    bubbleSort(list_1);
    bubbleSort(list_2);

    var list_diff: u64 = 0;
    for (list_1, list_2) |num1, num2| {
        //std.debug.print("{}\t{}\n", .{ num1, num2 });
        list_diff += @abs((num1 - num2));
    }

    std.debug.print("Result: {}\n", .{list_diff});

    // Part 2
    //var iter = list2_occurences.iterator();
    //while (iter.next()) |entry| {
    //   std.debug.print("Number:{} Occurrence:{}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    //}

    var similarity: i64 = 0;
    for (list_1) |num1| {
        similarity += num1 * (list2_occurences.get(num1) orelse 0);
    }

    std.debug.print("Similarity score is:{}\n", .{similarity});
}

fn bubbleSort(data: []i64) void {
    assert(data.len >= 1);

    var tmp: i64 = undefined;
    var sorted: bool = false;

    while (!sorted) {
        sorted = true;
        for (0..data.len - 1, 1..data.len) |a, b| {
            //std.debug.print("a:{}, b:{}\n", .{ a, b });
            if (data[a] > data[b]) {
                tmp = data[a];
                data[a] = data[b];
                data[b] = tmp;
                sorted = false;
            }
        }
    }
}
