const std = @import("std");
const print = std.debug.print;
const max_size = 50_000;
const Block = struct {
    size: u32,
    id: ?usize = null, // Null for empty block
    moved: bool = false,
    node: std.DoublyLinkedList.Node = .{},
};

pub fn main() void {
    print("Hello, world!\n", .{});

    var block_store: [max_size]Block = undefined;
    var store_idx: usize = 0;
    var filesystem: std.DoublyLinkedList = .{};

    {
        var file = std.fs.cwd().openFile("input", .{}) catch return panic("Open file");
        defer file.close();

        var contents: [max_size]u8 = @splat(0);
        var file_reader = file.reader(&contents);
        std.debug.assert((file_reader.getSize() catch unreachable) <= max_size);

        _ = file_reader.read(&contents) catch return panic("Read file");

        //print("{s}\n", .{contents});

        for (contents, 0..) |char, idx| {
            if (char == '\r' or char == '\n') break;
            const char_slice = [_]u8{char};

            block_store[store_idx] = Block{
                .size = std.fmt.parseInt(u8, char_slice[0..], 10) catch return panic("Parse number"),
                .id = if (idx % 2 == 0) @divTrunc(idx, 2) else null,
            };

            filesystem.append(&block_store[store_idx].node);

            store_idx += 1;
        }
    }

    var reverse_file_iterator: struct {
        const Self = @This();
        current: *std.DoublyLinkedList.Node,

        fn next(self: *Self) ?*std.DoublyLinkedList.Node {
            if (self.current.prev == null) return null;

            var block: *Block = @fieldParentPtr("node", self.current);
            while (block.id == null) {
                self.current = self.current.prev orelse return null;
                block = @fieldParentPtr("node", self.current);
            }

            defer self.current = self.current.prev orelse self.current;
            return self.current;
        }
    } = .{ .current = filesystem.last.? };

    _ = &reverse_file_iterator;

    var count: usize = 0;
    defrag: while (reverse_file_iterator.next()) |file_node| {
        const file_block: *Block = @fieldParentPtr("node", file_node);
        if (file_block.moved) continue;
        file_block.moved = true;

        {
            //print("\nCurrent State:\n", .{});
            //var print_iter = filesystem.first;
            //while (print_iter) |node| : (print_iter = print_iter.?.next) {
            //    const print_block: *Block = @fieldParentPtr("node", node);
            //    for (0..print_block.size) |_| {
            //        if (print_block.id) |id| {
            //            print("{}", .{id});
            //        } else {
            //            print(".", .{});
            //        }
            //    }
            //    print("|", .{});
            //}
            //print("\n\n", .{});
            //if (count >= 0) break;
            count += 1;
        }

        //print("Size: {}, ID: {any}\n", .{ file_block.size, file_block.id });

        // Moving stuff
        var space_search_node = filesystem.first;
        space: while (space_search_node) |space_node| : (space_search_node = space_search_node.?.next) {
            if (space_search_node == file_node) continue :defrag;
            const space_block: *Block = @fieldParentPtr("node", space_node);
            if (space_block.id) |_| continue;

            //print("Found space {}\n", .{space_block.size});

            if (file_block.size <= space_block.size) {
                // Make new space
                block_store[store_idx] = Block{ .size = file_block.size };
                filesystem.insertBefore(file_node, &block_store[store_idx].node);
                store_idx += 1;

                // Move the file into the space
                filesystem.remove(file_node);
                filesystem.insertBefore(space_node, file_node);

                // Reduce space (may go to 0!)
                space_block.size -= file_block.size;
                //print("Inserting with new space {}\n", .{space_block.size});
                break :space;
            } else {
                //print("not enough!\n", .{});
            }
        }

        // Clean-up 0 and merge contiguous space
        space_search_node = filesystem.first;
        while (space_search_node) |space_node| {
            const space_block: *Block = @fieldParentPtr("node", space_node);
            if (space_block.id) |_| {
                space_search_node = space_node.next;
                continue;
            }

            if (space_node.next) |next_node| {
                const next_block: *Block = @fieldParentPtr("node", next_node);
                if (next_block.id == null) {
                    //print("combining spaces!\n", .{});
                    space_block.size += next_block.size;
                    filesystem.remove(next_node);
                    continue;
                }
            }

            defer {
                if (space_block.size == 0) {
                    filesystem.remove(space_node);
                    //print("Removing 0 space!\n", .{});
                }
            }

            space_search_node = space_node.next;
        }
    }

    var checksum: u128 = 0;
    var idx: usize = 0;
    count = 0;
    print("\nCurrent State:\n", .{});
    var iter = filesystem.first;
    while (iter) |node| : (iter = iter.?.next) {
        const block: *Block = @fieldParentPtr("node", node);

        // Printing

        for (0..block.size) |_| {
            if (block.id) |id| {
                if (count <= 20) print("{}-", .{id});
                checksum += id * idx;
            } else {
                if (count <= 20) print(".", .{});
            }
            idx += 1;
        }
        if (count <= 20) print("|", .{});
        count += 1;
    }
    print("...\n\n", .{});

    print("Checksum: {}\n", .{checksum});
}

fn panic(msg: []const u8) void {
    std.debug.print("Panicked! {s}\n", .{msg});
}
