const std = @import("std");
const print = std.debug.print;
const StorageType = f128;

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
        var file = try std.fs.cwd().openFile("mini", .{});
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
    for (a_btns.items, b_btns.items, prizes.items) |a_btn, b_btn, p_orig| {
        const p = p_orig;
        //const p = [2]StorageType{ p_orig[0] + 10000000000000, p_orig[1] + 10000000000000 };
        //print("A: {d}, {d}\tB: {d}, {d}\tP: {d}, {d}\n", .{ a[0], a[1], b[0], b[1], p[0], p[1] });

        const det = a_btn[0] * b_btn[1] - b_btn[0] * a_btn[1];

        if (@abs(det) < 0.0001) {
            print("SINGULAR!!!\n", .{});
            continue;
        }

        const xd_0 = p[0] * b_btn[1] - p[1] * b_btn[0];
        const xd_1 = -p[0] * a_btn[1] + p[1] * a_btn[0];

        //NOTE: Characteristic Equation to see if eigenvalues are rational?
        const a = 1;
        const b = (-a_btn[0] - b_btn[1]);
        const c = a_btn[0] * b_btn[1] - a_btn[1] * b_btn[0];
        const discriminant: StorageType = b * b - 4 * a * c;

        print("Disc: {d}\n", .{discriminant});

        if (discriminant < 0) continue;

        const root: StorageType = @sqrt(discriminant);
        print("Root: {d}\n", .{root});

        const root1 = (-a_btn[0] - b_btn[0]) + root;
        _ = root1;

        if (root - @floor(root) > 0.001) {
            print("NOT RATIONAL!\n", .{});
            //continue;
        }

        //const x_0 = @divTrunc(xd_0, det);
        //const x_1 = @divTrunc(xd_1, det);
        const x_0 = xd_0 / det;
        const x_1 = xd_1 / det;

        //if (x_0 > 100 or x_1 > 100) continue;
        if (x_0 < 0 or x_1 < 0) continue;
        //if (x_0 - std.math.floor(x_0) > 0.001 or x_1 - std.math.floor(x_0) > 0.001) {
        //    print("AAAAAAAAAAAAAAAAAAAAAAAAAAAA\n", .{});
        //    continue;
        //}

        print("x_0:{d}, x_1:{d}\n", .{ x_0, x_1 });
        total += x_0 * 3 + x_1 * 1;
    }

    print("Total: {d}\n", .{total});
}
