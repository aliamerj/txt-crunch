const std = @import("std");
const file = @import("file.zig");
const freq = @import("frequency/frequency.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) return std.log.err("error: file path is required, please provide file path as in example \n tcrunch -- file path\n", .{});

    const file_content = file.readFile(args[1], &allocator) catch |err| {
        std.log.err("Failed to read file: {}\n", .{err});
        return;
    };

    var freq_table = try freq.calculateFrequency(file_content, &allocator);
    var iterator = freq_table.iterator();

    while (iterator.next()) |entry| {
        std.debug.print("{c}: {}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }
}
