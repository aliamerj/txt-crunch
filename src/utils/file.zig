const std = @import("std");

const Allocator = std.mem.Allocator;
const Hash_map = std.hash_map.AutoHashMap(u8, usize);

pub const FileContent = struct {
    allocator: Allocator,
    data: []const u8,

    pub fn init(allocator: Allocator, data: []const u8) FileContent {
        return FileContent{
            .allocator = allocator,
            .data = data,
        };
    }

    pub fn getFileData(self: *FileContent) []const u8 {
        return self.data;
    }

    pub fn calculateFrequency(self: *FileContent) !Hash_map {
        var freq_table = Hash_map.init(self.*.allocator);

        for (self.*.data) |c| {
            var count = freq_table.get(c) orelse 0;
            count += 1;
            try freq_table.put(c, count);
        }
        return freq_table;
    }
};

pub fn readFile(file_path: []const u8, allocator: *std.mem.Allocator) ![]u8 {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const buffer = try allocator.alloc(u8, file_size);

    const bytes_read = try file.readAll(buffer);

    if (file_size != bytes_read) return error.ReadError;

    return buffer;
}

const expect = std.testing.expect;

test "calculate frequency and get data" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const data = "4aaabbc 4";

    var content = FileContent.init(allocator, data);
    var freq_table = content.calculateFrequency() catch unreachable;
    defer freq_table.deinit();

    try std.testing.expectEqualStrings(content.getFileData(), data);
    try expect(freq_table.get('a') == 3);
    try expect(freq_table.get('b') == 2);
    try expect(freq_table.get('c') == 1);
    try expect(freq_table.get(' ') == 1);
    try expect(freq_table.get('4') == 2);
}
