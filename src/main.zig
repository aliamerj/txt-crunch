const std = @import("std");
const f = @import("utils/file.zig");
const huffman = @import("huffman/encoding.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    errdefer arena.deinit();
    var allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) return std.log.err("error: file path is required, please provide file path as in example \n tcrunch -- file path\n", .{});

    const file_content = f.readFile(args[1], &allocator) catch |err| {
        std.log.err("Failed to read file: {}\n", .{err});
        return;
    };

    var content = f.FileContent.init(allocator, file_content);

    var freq_table = try content.calculateFrequency();
    try huffman.encoding(&freq_table, allocator);
}
