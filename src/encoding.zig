const std = @import("std");
const hn = @import("huffman/huffman_node.zig");
const ct = @import("huffman/code_table.zig");
const f = @import("utils/file.zig");

pub fn encoding(content: *f.FileContent, allocator: std.mem.Allocator) !void {
    var table = ct.CodeTable.init(allocator);
    defer table.deinit();

    var file = try std.fs.cwd().createFile("output.txt", .{ .read = true });
    defer {
        file.close();
        std.debug.print("Data has been written to output.txt\n", .{});
    }

    var freq_table = content.freq_table;
    defer freq_table.deinit();

    const tree = hn.buildHuffmanTree(&freq_table, allocator) catch unreachable;
    defer allocator.destroy(tree);

    try writeHeader(&freq_table, &file);
    try ct.generateTable(&table, tree, "");
    try packAndWriteBits(&content.data, &table, &file);
}

fn writeHeader(freq_table: *std.AutoHashMap(u8, usize), file: *std.fs.File) !void {
    const writer = file.writer();
    var iterator = freq_table.iterator();
    while (iterator.next()) |entry| {
        try writer.writeByte(entry.key_ptr.*);
        try writer.writeByte(@truncate(entry.value_ptr.*)); // Write frequency as a single byte
    }
    try writer.writeByte(0xFF); // Delimiter
}

fn packAndWriteBits(data: *const []const u8, code_table: *ct.CodeTable, file: *std.fs.File) !void {
    const writer = file.writer();
    var bitBuffer: u8 = 0;
    var bitCount: u8 = 0;

    for (data.*) |char| {
        const code = code_table.table.get(char).?;
        for (code) |bit| {
            bitBuffer |= (bit & 0x1) << @intCast(7 - bitCount); // Accumulate bits into the buffer
            bitCount += 1;

            if (bitCount == 8) {
                try writer.writeByte(bitBuffer);
                bitBuffer = 0;
                bitCount = 0;
            }
        }
    }

    if (bitCount > 0) {
        try writer.writeByte(bitBuffer);
    }
}

test "Test writeHeader" {
    const allocator = std.testing.allocator;
    var freq_table = std.AutoHashMap(u8, usize).init(allocator);
    defer freq_table.deinit();

    try freq_table.put('c', 1);
    try freq_table.put('b', 3);
    try freq_table.put('a', 5);

    var file = try std.fs.cwd().createFile("header_test.txt", .{ .read = true });
    defer {
        file.close();
        std.fs.cwd().deleteFile("header_test.txt") catch {};
    }

    try writeHeader(&freq_table, &file);

    // Seek to the beginning of the file
    try file.seekTo(0);

    var reader = file.reader();
    var buffer: [7]u8 = undefined;
    _ = try reader.readAll(&buffer);

    try std.testing.expectEqualSlices(u8, &[_]u8{ 'b', 3, 'a', 5, 'c', 1, 0xFF }, &buffer);
}
