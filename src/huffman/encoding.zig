const std = @import("std");
const hn = @import("huffman_node.zig");
const ct = @import("code_table.zig");

pub fn encoding(freq_table: *std.AutoHashMap(u8, usize), allocator: std.mem.Allocator) !void {
    var table = ct.CodeTable.init(allocator);
    defer table.deinit();

    const tree = hn.buildHuffmanTree(freq_table, allocator) catch unreachable;
    defer allocator.destroy(tree);

    try ct.generateTable(&table, tree, "");

    table.printTable();
}
