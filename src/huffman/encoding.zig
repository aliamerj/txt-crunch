const std = @import("std");
const hn = @import("huffman_node.zig");

const PQlt = std.PriorityQueue(hn.Huffman_node, void, lessThan);

pub fn encoding(freq_table: *std.AutoHashMap(u8, usize), allocator: std.mem.Allocator) !void {
    var tree = buildHuffmanTree(freq_table, allocator) catch unreachable;
    printTree(&tree, 0, 'X');
}

fn buildHuffmanTree(freq_table: *std.AutoHashMap(u8, usize), allocator: std.mem.Allocator) !hn.Huffman_node {
    // Create a priority queue that stores Huffman_node
    var queue = PQlt.init(allocator, {});
    defer queue.deinit();

    var iterator = freq_table.iterator();
    while (iterator.next()) |entry| {
        const node = hn.nodeCreate(allocator, entry.key_ptr.*, entry.value_ptr.*) catch unreachable;
        try queue.add(node.*);
    }

    // Build the Huffman tree
    while (queue.count() > 1) {
        var left = queue.remove();
        var right = queue.remove();

        const joined = hn.nodeJoin(allocator, &left, &right) catch unreachable;
        try queue.add(joined.*);
    }
    return queue.remove();
}

fn lessThan(context: void, a: hn.Huffman_node, b: hn.Huffman_node) std.math.Order {
    _ = context;
    return std.math.order(a.frequency, b.frequency);
}

pub fn printTree(node: ?*hn.Huffman_node, indent: usize, place: u8) void {
    if (node == null) return;

    var indentStr: [256]u8 = undefined; // Adjust the size as needed
    var index: usize = 0;
    while (index < indent and index < indentStr.len) : (index += 1) {
        indentStr[index] = ' ';
    }
    const indentSlice = indentStr[0..index];

    std.debug.print("{s}C:{?c}, F:{any} p:{c}\n", .{ indentSlice, node.?.symbol, node.?.frequency, place });

    printTree(node.?.left, indent + 4, 'L');
    printTree(node.?.right, indent + 5, 'R');
}

const expect = std.testing.expect;

test "buildHuffmanTree with single entry" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var freq_table = std.AutoHashMap(u8, usize).init(allocator);
    defer freq_table.deinit();

    try freq_table.put('a', 5);

    const root = buildHuffmanTree(&freq_table, allocator) catch unreachable;

    // Check if the root's frequency is correct
    try expect(root.frequency == 5);
    try expect(root.symbol == 'a');
    try expect(root.left == null);
    try expect(root.right == null);
}

test "buildHuffmanTree" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var freq_table = std.AutoHashMap(u8, usize).init(allocator);
    defer freq_table.deinit();
    // mer

    try freq_table.put('m', 1);
    try freq_table.put('e', 1);
    try freq_table.put('r', 1);
    try freq_table.put('i', 2);
    try freq_table.put('l', 2);
    try freq_table.put('a', 3);

    const root = buildHuffmanTree(&freq_table, allocator) catch unreachable;

    // Check if the root's frequency is correct
    try expect(root.frequency == 10); // root

    try expect(root.left.?.frequency == 4); // i+ (e + m)
    try expect(root.left.?.left.?.frequency == 2); // i
    try expect(root.left.?.right.?.frequency == 2); // (e + m)
    try expect(root.left.?.right.?.right.?.frequency == 1); // e
    try expect(root.left.?.right.?.left.?.frequency == 1); // m

    try expect(root.right.?.frequency == 6); // a + (l + r)
    try expect(root.right.?.left.?.frequency == 3); // a
    try expect(root.right.?.right.?.frequency == 3); // (l + r)
    try expect(root.right.?.right.?.right.?.frequency == 1); // r
    try expect(root.right.?.right.?.left.?.frequency == 2); // l

}
