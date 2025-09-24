const std = @import("std");
const print = std.debug.print;
const aoc = @import("aoc");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    // For part 1
    var wins = std.AutoHashMap(u64, void).init(alloc);
    defer wins.deinit();

    // For part 2
    var card_copies = std.AutoHashMap(u64, u64).init(alloc);
    defer card_copies.deinit();

    var total_points: u64 = 0;
    var total_cards: u64 = 0;
    var lines = try aoc.inputLineIterator(alloc);
    defer alloc.free(lines.contents);
    while (lines.next()) |line| {
        //print("{s}\n", .{line});
        var game_part_iter = std.mem.tokenizeAny(u8, line, ":|");

        // Get card ID
        const id: usize = blk: {
            var read_id = std.mem.tokenizeAny(u8, game_part_iter.next().?, "Card ");
            break :blk try std.fmt.parseInt(u8, read_id.next().?, 10);
        };

        // Winning numbers
        var win_num_strs = std.mem.tokenizeAny(u8, game_part_iter.next().?, " ");
        while (win_num_strs.next()) |win_num_str| {
            const win_num = try std.fmt.parseInt(u64, win_num_str, 10);
            try wins.put(win_num, {});
        }

        // Numbers I have
        var game_points: u64 = 0;
        var wins_this_game: u64 = 0;
        var has_num_strs = std.mem.tokenizeAny(u8, game_part_iter.next().?, " ");
        while (has_num_strs.next()) |has_num_str| {
            const has_num = try std.fmt.parseInt(u64, has_num_str, 10);
            if (wins.contains(has_num)) {
                wins_this_game += 1;
                if (game_points == 0) {
                    game_points = 1;
                } else {
                    game_points *= 2;
                }
            }
        }
        total_points += game_points;
        wins.clearRetainingCapacity();

        // Part 2 stuff
        // Add this actual card (line of input)
        (try card_copies.getOrPutValue(id, 0)).value_ptr.* += 1;

        // Then add copies of other cards for each game won
        for ((id + 1)..(id + wins_this_game + 1)) |copy| {
            const to_add = card_copies.get(id).?;
            const result = try card_copies.getOrPutValue(copy, 0);
            result.value_ptr.* += to_add;
        }
        total_cards += card_copies.get(id) orelse 0;
    }

    print("Total points Part 1: {}\n", .{total_points});
    print("Total cards Part 2: {}\n", .{total_cards});
}
