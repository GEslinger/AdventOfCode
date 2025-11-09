const std = @import("std");
const print = std.debug.print;
const aoc = @import("aoc");

const card_order_1 = "AKQJT98765432";
const card_order_2 = "AKQT98765432J";

const Hand = struct { cards: []const u8, bid: u64 };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var hands: std.ArrayList(Hand) = .empty;
    defer hands.deinit(alloc);

    var lines = try aoc.inputLineIterator(alloc);
    defer alloc.free(lines.contents);
    while (lines.next()) |line| {
        var part_iter = std.mem.tokenizeAny(u8, line, " ");

        try hands.append(
            alloc,
            Hand{
                .cards = part_iter.next().?,
                .bid = try std.fmt.parseInt(u64, part_iter.next().?, 10),
            },
        );
    }

    // Part 1 sorting
    std.mem.sort(Hand, hands.items, {}, lessThanPart1);
    var answer_1: u64 = 0;
    for (hands.items, 1..) |hand, rank| {
        answer_1 += hand.bid * rank;
    }

    print("Answer part 1: {}\n", .{answer_1});

    // Part 2 sorting
    std.mem.sort(Hand, hands.items, {}, lessThanPart2);
    var answer_2: u64 = 0;
    for (hands.items, 1..) |hand, rank| {
        //print("{s} : {any}, {}\n", .{
        //    hand.cards,                                 rank_card(hand.cards),
        //    std.mem.count(u8, hand.cards, &[_]u8{'J'}),
        //});
        answer_2 += hand.bid * rank;
    }

    print("Answer part 2: {}\n", .{answer_2});
}

fn lessThanPart1(_: void, a_hand: Hand, b_hand: Hand) bool {
    const a = a_hand.cards;
    const b = b_hand.cards;

    var count_a: [13]u4 = @splat(0);
    for (a) |val| {
        count_a[std.mem.indexOf(u8, card_order_1, &[_]u8{val}).?] += 1;
    }
    const max_count_a = std.mem.max(u4, &count_a);

    var count_b: [13]u4 = @splat(0);
    for (b) |val| {
        count_b[std.mem.indexOf(u8, card_order_1, &[_]u8{val}).?] += 1;
    }
    const max_count_b = std.mem.max(u4, &count_b);
    //print("{s}/{s}\n{any}\n{any}\n\n", .{ a, b, count_a, count_b });

    if (max_count_b > max_count_a) return true;
    if (max_count_a > max_count_b) return false;

    // At this point A and B must have the same "level"
    // Must distinguish full house vs three-of-a-kind, and two pair vs one pair
    const pairs_a = std.mem.count(u4, &count_a, &[_]u4{2});
    const pairs_b = std.mem.count(u4, &count_b, &[_]u4{2});
    if (pairs_b > pairs_a) return true;
    if (pairs_a > pairs_b) return false;

    // Finally we have to do the comparison
    for (a, b) |a_card, b_card| {
        const rank_a = std.mem.indexOf(u8, card_order_1, &[_]u8{a_card}).?;
        const rank_b = std.mem.indexOf(u8, card_order_1, &[_]u8{b_card}).?;

        if (rank_b < rank_a) return true;
        if (rank_a < rank_b) return false;
    }

    unreachable;
}

fn lessThanPart2(_: void, a_hand: Hand, b_hand: Hand) bool {
    const a_type = @intFromEnum(rank_card(a_hand.cards));
    const b_type = @intFromEnum(rank_card(b_hand.cards));

    if (a_type < b_type) return false;
    if (a_type > b_type) return true;

    for (a_hand.cards, b_hand.cards) |a_card, b_card| {
        const rank_a = std.mem.indexOf(u8, card_order_2, &[_]u8{a_card}).?;
        const rank_b = std.mem.indexOf(u8, card_order_2, &[_]u8{b_card}).?;

        if (rank_b < rank_a) return true;
        if (rank_a < rank_b) return false;
    }

    unreachable;
}

fn rank_card(cards: []const u8) HandType {
    var wilds: u4 = 0;
    var count: [13]u4 = @splat(0);
    for (cards) |card| {
        if (card == 'J') {
            wilds += 1;
            continue;
        }
        count[std.mem.indexOf(u8, card_order_2, &[_]u8{card}).?] += 1;
    }
    const max_count = std.mem.max(u4, &count) + wilds;

    if (max_count == 5) return .five;
    if (max_count == 4) return .four;

    const pairs = std.mem.count(u4, &count, &[_]u4{2});
    if (max_count == 3 and pairs == 2 and wilds == 1) return .full;
    if (max_count == 3 and pairs == 1 and wilds == 0) return .full;
    if (max_count == 3) return .three;

    if (pairs == 2) return .two_p;
    if (pairs == 1 or max_count == 2) return .one_p;

    return .high;
}

const HandType = enum {
    five,
    four,
    full,
    three,
    two_p,
    one_p,
    high,
};
