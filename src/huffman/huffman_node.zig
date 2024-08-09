const std = @import("std");

const Allocator = std.mem.Allocator;
const Order = std.math.Order;
const PQlt = std.PriorityQueue(*Huffman_node, void, lessThan);

pub const Huffman_node = struct {
    left: ?*Huffman_node,
    right: ?*Huffman_node,
    symbol: ?u8,
    frequency: usize,
};

pub fn nodeCreate(alloc: Allocator, symbol: ?u8, frequency: usize) !*Huffman_node {
    const n = try alloc.create(Huffman_node);
    n.* = .{
        .left = null,
        .right = null,
        .symbol = symbol,
        .frequency = frequency,
    };
    return n;
}

pub fn nodeJoin(alloc: Allocator, left: *Huffman_node, right: *Huffman_node) !*Huffman_node {
    const n = try nodeCreate(alloc, null, left.frequency + right.frequency);
    n.left = left;
    n.right = right;
    return n;
}

pub fn buildHuffmanTree(freq_table: *std.AutoHashMap(u8, usize), allocator: std.mem.Allocator) !*Huffman_node {
    // Create a priority queue that stores Huffman_node
    var queue = PQlt.init(allocator, {});
    defer queue.deinit();

    var iterator = freq_table.iterator();
    while (iterator.next()) |entry| {
        const node = nodeCreate(allocator, entry.key_ptr.*, entry.value_ptr.*) catch unreachable;
        try queue.add(node);
    }

    // Build the Huffman tree
    while (queue.count() > 1) {
        const left = queue.remove();
        const right = queue.remove();

        const joined = nodeJoin(allocator, left, right) catch unreachable;
        try queue.add(joined);
    }
    return queue.remove();
}

fn lessThan(context: void, a: *Huffman_node, b: *Huffman_node) std.math.Order {
    _ = context;
    return std.math.order(a.frequency, b.frequency);
}

const expect = std.testing.expect;

test "nodeJoin with larger tree" {
    const m = try nodeCreate(std.testing.allocator, 'm', 1);
    defer std.testing.allocator.destroy(m);
    const e = try nodeCreate(std.testing.allocator, 'e', 1);
    defer std.testing.allocator.destroy(e);
    const r = try nodeCreate(std.testing.allocator, 'r', 1);
    defer std.testing.allocator.destroy(r);
    const i = try nodeCreate(std.testing.allocator, 'i', 2);
    defer std.testing.allocator.destroy(i);
    const l = try nodeCreate(std.testing.allocator, 'l', 2);
    defer std.testing.allocator.destroy(l);
    const a = try nodeCreate(std.testing.allocator, 'a', 3);
    defer std.testing.allocator.destroy(a);

    // Join m and e
    const joined_me = try nodeJoin(std.testing.allocator, m, e);
    defer std.testing.allocator.destroy(joined_me);

    try expect(std.meta.eql(joined_me.*, .{
        .left = m,
        .right = e,
        .symbol = null,
        .frequency = 2,
    }));

    // Join r and (m , e)
    const joined_r_me = try nodeJoin(std.testing.allocator, r, joined_me);
    defer std.testing.allocator.destroy(joined_r_me);

    try expect(std.meta.eql(joined_r_me.*, .{
        .left = r,
        .right = joined_me,
        .symbol = null,
        .frequency = 3,
    }));

    // Join i and l
    const joined_il = try nodeJoin(std.testing.allocator, i, l);
    defer std.testing.allocator.destroy(joined_il);

    try expect(std.meta.eql(joined_il.*, .{
        .left = i,
        .right = l,
        .symbol = null,
        .frequency = 4,
    }));

    // Join a and joined_r_me
    const joined_a_r_me = try nodeJoin(std.testing.allocator, a, joined_r_me);
    defer std.testing.allocator.destroy(joined_a_r_me);

    try expect(std.meta.eql(joined_a_r_me.*, .{
        .left = a,
        .right = joined_r_me,
        .symbol = null,
        .frequency = 6,
    }));

    // Join the final tree
    const final_tree = try nodeJoin(std.testing.allocator, joined_il, joined_a_r_me);
    defer std.testing.allocator.destroy(final_tree);

    try expect(std.meta.eql(final_tree.*, .{
        .left = joined_il,
        .right = joined_a_r_me,
        .symbol = null,
        .frequency = 10,
    }));

    const root = final_tree.*;

    try expect(root.frequency == 10); // root

    try expect(root.left.?.frequency == 4); // i+l

    try expect(root.left.?.left.?.symbol == 'i');
    try expect(root.left.?.left.?.frequency == 2);

    try expect(root.left.?.right.?.symbol == 'l');
    try expect(root.left.?.right.?.frequency == 2);

    try expect(root.right.?.frequency == 6); // a + (r (m + e))

    try expect(root.right.?.left.?.symbol == 'a');
    try expect(root.right.?.left.?.frequency == 3);

    try expect(root.right.?.right.?.frequency == 3); // (r (m + e))

    try expect(root.right.?.right.?.left.?.symbol == 'r');
    try expect(root.right.?.right.?.left.?.frequency == 1);

    try expect(root.right.?.right.?.right.?.frequency == 2); // m + e

    try expect(root.right.?.right.?.right.?.left.?.symbol == 'm');
    try expect(root.right.?.right.?.right.?.left.?.frequency == 1);

    try expect(root.right.?.right.?.right.?.right.?.symbol == 'e');
    try expect(root.right.?.right.?.right.?.right.?.frequency == 1);
}

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

    try freq_table.put('m', 1);
    try freq_table.put('e', 1);
    try freq_table.put('r', 1);
    try freq_table.put('i', 2);
    try freq_table.put('l', 2);
    try freq_table.put('a', 3);

    const root = buildHuffmanTree(&freq_table, allocator) catch unreachable;

    // Check if the root's frequency is correct

    try expect(root.frequency == 10); // root

    try expect(root.left.?.frequency == 4); // r e - l

    try expect(root.left.?.left.?.frequency == 2); // r e
    try expect(root.left.?.left.?.left.?.symbol == 'r');
    try expect(root.left.?.left.?.left.?.frequency == 1);
    try expect(root.left.?.left.?.right.?.symbol == 'e');
    try expect(root.left.?.left.?.right.?.frequency == 1);

    try expect(root.left.?.right.?.symbol == 'l');
    try expect(root.left.?.right.?.frequency == 2);

    try expect(root.right.?.frequency == 6); // a + (m + i)

    try expect(root.right.?.left.?.symbol == 'a');
    try expect(root.right.?.left.?.frequency == 3);

    try expect(root.right.?.right.?.frequency == 3); // (m + i))

    try expect(root.right.?.right.?.left.?.symbol == 'm');
    try expect(root.right.?.right.?.left.?.frequency == 1);

    try expect(root.right.?.right.?.right.?.symbol == 'i');
    try expect(root.right.?.right.?.right.?.frequency == 2);
}
