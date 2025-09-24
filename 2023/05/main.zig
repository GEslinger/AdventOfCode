const std = @import("std");
const print = std.debug.print;
const aoc = @import("aoc");

const MapEntry = struct {
    dest: u64,
    src: u64,
    len: u64,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var map_idx: ?usize = null;
    // Part 1 seeds are individuals
    var seeds_1: std.ArrayList(u64) = .empty;
    defer seeds_1.deinit(alloc);

    // Part 2 seeds are pairs with start pos & length
    var seed_pairs: std.ArrayList([2]u64) = .empty;
    defer seed_pairs.deinit(alloc);

    var maps: std.ArrayList(std.ArrayList(MapEntry)) = .empty;
    defer {
        for (maps.items) |*map| map.deinit(alloc);
        maps.deinit(alloc);
    }

    var lines = try aoc.inputLineIterator(alloc);
    defer alloc.free(lines.contents);
    while (lines.next()) |line| {
        // Increase map index on empty line
        if (line.len == 0) {
            map_idx.? += 1;
            try maps.append(alloc, std.ArrayList(MapEntry).empty);
            _ = lines.next(); // Discard "title" line
            continue;
        }

        // Reading seed line
        if (map_idx == null) {
            // Part 1 stuff
            var seed_read_iter = std.mem.tokenizeAny(u8, line, "seeds: ");
            while (seed_read_iter.next()) |seed_str| {
                const seed = try std.fmt.parseInt(u64, seed_str, 10);
                try seeds_1.append(alloc, seed);
            }

            // Part 2
            seed_read_iter.reset();
            while (seed_read_iter.next()) |seed_str| {
                const seed_start = try std.fmt.parseInt(u64, seed_str, 10);
                const seed_end = try std.fmt.parseInt(u64, seed_read_iter.next().?, 10);
                try seed_pairs.append(alloc, [2]u64{ seed_start, seed_end });
            }

            _ = lines.next();
            _ = lines.next();
            map_idx = 0;
            try maps.append(alloc, std.ArrayList(MapEntry).empty);
            continue;
        }

        // Adding to the map position map_idx
        var map_content_iter = std.mem.tokenizeAny(u8, line, " ");
        const dest = try std.fmt.parseInt(u64, map_content_iter.next().?, 10);
        const src = try std.fmt.parseInt(u64, map_content_iter.next().?, 10);
        const len = try std.fmt.parseInt(u64, map_content_iter.next().?, 10);

        const new_entry = MapEntry{
            .dest = dest,
            .src = src,
            .len = len,
        };

        try maps.items[map_idx.?].append(alloc, new_entry);
    }

    // Part 1
    var min_last_value_1: u64 = std.math.maxInt(u64);
    for (seeds_1.items) |seed| {
        //print("Seed begins {}\n", .{seed});

        var value = seed;
        for (maps.items, 1..) |map, level| {
            //print("Level {} ", .{level});

            const found = for (map.items) |rule| {
                if (value >= rule.src and value < rule.src + rule.len) {
                    value = rule.dest + (value - rule.src);
                    break true;
                }
            } else false;

            _ = found;
            _ = level;
            //print("found: {} new val {}\n", .{ found, value });
        } else {
            if (value < min_last_value_1) min_last_value_1 = value;
        }
    }

    print("Minimum last (part 1): {}\n", .{min_last_value_1});
    var remainder: std.ArrayList([2]u64) = .empty;
    defer remainder.deinit(alloc);

    // Part 2
    for (maps.items, 1..) |map, level| {
        _ = level;

        var new_seeds: std.ArrayList([2]u64) = .empty;
        defer new_seeds.deinit(alloc);

        for (seed_pairs.items) |pair| {
            try remainder.append(alloc, pair);

            rem: while (remainder.pop()) |rem| {
                //print("Start {} len {}\n", .{ rem[0], rem[1] });
                for (map.items) |*rule| {
                    //print("Rule s{} l{} d{}\n", .{ rule.src, rule.len, rule.dest });
                    var lhs = false;
                    var rhs = false;
                    if (rem[0] >= rule.src and rem[0] < rule.src + rule.len) {
                        //print("LHS inside!\n", .{});
                        lhs = true;
                    }

                    if (rem[0] + rem[1] - 1 >= rule.src and
                        rem[0] + rem[1] - 1 < rule.src + rule.len)
                    {
                        //print("RHS inside!\n", .{});
                        rhs = true;
                    }

                    const surround = (rem[0] < rule.src and
                        rem[0] + rem[1] >= rule.src + rule.len);

                    // NOTE: Finally Validated!
                    if (lhs and rhs) {
                        // S ----- 0 -- 1 -- S+L
                        // This is OK assuming no overlapping rules
                        try new_seeds.append(alloc, [2]u64{ rule.dest + rem[0] - rule.src, rem[1] });
                        continue :rem;
                    } else if (lhs) {
                        // S ---------- 0 -- S+L --- 1
                        const offset = rem[0] - rule.src;
                        try new_seeds.append(alloc, [2]u64{ rule.dest + offset, rule.len - offset });
                        try remainder.append(alloc, [2]u64{ rule.src + rule.len, rem[1] + offset - rule.len });
                        continue :rem;
                    } else if (rhs) {
                        // -- 0 ---- S --- 1 ---- S+L
                        const offset = rule.src - rem[0];
                        try remainder.append(alloc, [2]u64{ rem[0], offset });
                        try new_seeds.append(alloc, [2]u64{ rule.dest, rem[1] - offset });
                        continue :rem;
                    } else if (surround) {
                        // - 0 --- S --- S+L ---- 1
                        //print("Surround!\n", .{});
                        const offset = rule.src - rem[0];
                        try remainder.append(alloc, [2]u64{ rem[0], offset });
                        try new_seeds.append(alloc, [2]u64{ rule.dest, rule.len });
                        try remainder.append(alloc, [2]u64{ rule.src + rule.len, rem[1] - offset - rule.len });
                        continue :rem;
                    } else {}
                }

                try new_seeds.append(alloc, rem);
            }

            remainder.clearRetainingCapacity();
        }

        //for (new_seeds.items) |item| print("{any}\n", .{item});
        seed_pairs.clearAndFree(alloc);
        seed_pairs = try new_seeds.clone(alloc);
    }

    var min_part2: u64 = std.math.maxInt(u64);
    for (seed_pairs.items) |pair| {
        if (pair[0] < min_part2) min_part2 = pair[0];
    }

    print("Min part 2: {}\n", .{min_part2});
}
