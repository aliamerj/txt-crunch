const std = @import("std");

pub fn readFile(file_path: []const u8, allocator: *std.mem.Allocator) ![]u8 {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const buffer = try allocator.alloc(u8, file_size);

    const bytes_read = try file.readAll(buffer);

    if (file_size != bytes_read) return error.ReadError;

    return buffer;
}
