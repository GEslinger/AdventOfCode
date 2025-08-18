const std = @import("std");
const print = std.debug.print;
const StorageType = f64;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var a_btns = std.ArrayList([2]StorageType).init(alloc);
    defer a_btns.deinit();
    var b_btns = std.ArrayList([2]StorageType).init(alloc);
    defer b_btns.deinit();
    var prizes = std.ArrayList([2]StorageType).init(alloc);
    defer prizes.deinit();

    {
        var file = try std.fs.cwd().openFile("input", .{});
        defer file.close();

        const contents = try file.readToEndAlloc(alloc, 1_000_000);
        //print("{s}\n\n", .{contents});

        var lines = std.mem.tokenizeAny(u8, contents, "\r\n");
        while (lines.next()) |line| {
            if (line.len < 5) continue;

            var num_iterator = std.mem.tokenizeAny(u8, line, "BPurtiozne A:XY+,=");
            const x_str = num_iterator.next().?;
            const y_str = num_iterator.next().?;

            //print("Got X:{s}, Y:{s}\n", .{ x_str, y_str });

            const x_val = try std.fmt.parseFloat(StorageType, x_str);
            const y_val = try std.fmt.parseFloat(StorageType, y_str);

            //const x_val = try std.fmt.parseInt(StorageType, x_str, 10);
            //const y_val = try std.fmt.parseInt(StorageType, y_str, 10);

            if (line[7] == 'A') try a_btns.append([2]StorageType{ x_val, y_val });
            if (line[7] == 'B') try b_btns.append([2]StorageType{ x_val, y_val });
            if (line[0] == 'P') try prizes.append([2]StorageType{ x_val, y_val });
        }
    }

    var total: StorageType = 0;
    //for (a_btns.items) |btn| print("{}, {}\n", .{ btn[0], btn[1] });
    for (a_btns.items, b_btns.items, prizes.items) |a, b, p| {
        //print("A: {d}, {d}\tB: {d}, {d}\tP: {d}, {d}\n", .{ a[0], a[1], b[0], b[1], p[0], p[1] });

        const det = a[0] * b[1] - b[0] * a[1];
        if (det < 0.0001) {
            print("REEEE!!!\n", .{});
            continue;
        }

        const xd_0 = p[0] * b[1] - p[1] * b[0];
        const xd_1 = -p[0] * a[1] + p[1] * a[0];

        //const x_0 = @divTrunc(xd_0, det);
        //const x_1 = @divTrunc(xd_1, det);
        const x_0 = xd_0 / det;
        const x_1 = xd_1 / det;

        if (x_0 > 100 or x_1 > 100) continue;
        if (x_0 < 0 or x_1 < 0) continue;

        print("x_0:{d}, x_1:{d}\n", .{ x_0, x_1 });
        total += x_0 * 3 + x_1 * 1;
    }

    print("Total: {d}\n", .{total});
}
