const std = @import("std");

const Allocator = std.mem.Allocator;
const Hash_map = std.hash_map.AutoHashMap(u8, usize);

pub const FileContent = struct {
    allocator: Allocator,
    data: []const u8,
    freq_table: Hash_map,

    pub fn init(allocator: Allocator, data: []const u8) FileContent {
        const freq_table = Hash_map.init(allocator);
        return FileContent{
            .allocator = allocator,
            .data = data,
            .freq_table = freq_table,
        };
    }

    pub fn calculateFrequency(self: *FileContent) !void {
        for (self.*.data) |c| {
            var count = self.freq_table.get(c) orelse 0;
            count += 1;
            try self.freq_table.put(c, count);
        }
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
    content.calculateFrequency() catch unreachable;
    defer content.freq_table.deinit();

    try std.testing.expectEqualStrings(content.data, data);
    try expect(content.freq_table.get('a') == 3);
    try expect(content.freq_table.get('b') == 2);
    try expect(content.freq_table.get('c') == 1);
    try expect(content.freq_table.get(' ') == 1);
    try expect(content.freq_table.get('4') == 2);
}
