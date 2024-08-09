const std = @import("std");
const hn = @import("huffman_node.zig");

const Allocator = std.mem.Allocator;
const Hash_map = std.AutoHashMap(u8, []const u8);

pub const CodeTable = struct {
    table: Hash_map, // Maps ASCII values (u8) to Huffman codes
    allocator: Allocator,

    pub fn init(allocator: Allocator) CodeTable {
        return CodeTable{
            .table = Hash_map.init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *CodeTable) void {
        var it = self.table.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.value_ptr.*);
        }
        self.table.deinit();
    }

    pub fn insert(self: *CodeTable, symbol: u8, code: []const u8) !void {
        const codeCopy = try self.allocator.alloc(u8, code.len);
        std.mem.copyForwards(u8, codeCopy, code);
        try self.table.put(symbol, codeCopy);
    }

    pub fn get(self: *CodeTable) Hash_map {
        return self.*.table;
    }

    pub fn printTable(self: *CodeTable) void {
        var it = self.table.iterator();
        while (it.next()) |entry| {
            const code = entry.value_ptr.*;
            std.debug.print("Symbol: '{c}', Code: ", .{entry.key_ptr.*});
            for (code) |bit| {
                std.debug.print("{d}", .{bit});
            }
            std.debug.print("\n", .{});
        }
    }
};

pub fn generateTable(
    table: *CodeTable,
    node: ?*hn.Huffman_node,
    prefix: []const u8,
) !void {
    if (node == null) return;

    const currentNode = node.?;
    if (currentNode.left == null and currentNode.right == null) {
        // Leaf node, store the code
        try table.insert(currentNode.*.symbol.?, prefix);
    } else {
        // Internal node, recurse with additional bits for left and right
        var leftPrefix = try table.allocator.alloc(u8, prefix.len + 1);
        std.mem.copyForwards(u8, leftPrefix, prefix);
        leftPrefix[prefix.len] = 0; // Append 0 for left

        var rightPrefix = try table.allocator.alloc(u8, prefix.len + 1);
        std.mem.copyForwards(u8, rightPrefix, prefix);
        rightPrefix[prefix.len] = 1; // Append 1 for right

        try generateTable(table, currentNode.left, leftPrefix);
        try generateTable(table, currentNode.right, rightPrefix);

        table.allocator.free(leftPrefix);
        table.allocator.free(rightPrefix);
    }
}

const expect = std.testing.expect;
const expectStrings = std.testing.expectEqualStrings;

test "generateTable" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var freq_table = std.AutoHashMap(u8, usize).init(allocator);
    defer freq_table.deinit();

    var table = CodeTable.init(allocator);
    defer table.deinit();

    try freq_table.put('m', 1);
    try freq_table.put('e', 1);
    try freq_table.put('r', 1);
    try freq_table.put('i', 2);
    try freq_table.put('l', 2);
    try freq_table.put('a', 3);

    const root = hn.buildHuffmanTree(&freq_table, allocator) catch unreachable;
    try expect(root.frequency == 10); // root

    generateTable(&table, root, "") catch unreachable;
    const encodedTable = table.get();

    try expectStrings(encodedTable.get('r').?, &[3]u8{ 0, 0, 0 });
    try expectStrings(encodedTable.get('e').?, &[3]u8{ 0, 0, 1 });
    try expectStrings(encodedTable.get('m').?, &[3]u8{ 1, 1, 0 });
    try expectStrings(encodedTable.get('i').?, &[3]u8{ 1, 1, 1 });
    try expectStrings(encodedTable.get('a').?, &[2]u8{ 1, 0 });
    try expectStrings(encodedTable.get('l').?, &[2]u8{ 0, 1 });
}
