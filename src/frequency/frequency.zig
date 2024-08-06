const std = @import("std");

pub fn calculateFrequency(line: []const u8, allocator: *std.mem.Allocator) !std.hash_map.AutoHashMap(u8, u64) {
    var freq_table = std.AutoHashMap(u8, u64).init(allocator.*);

    for (line) |c| {
        var count = freq_table.get(c) orelse 0;
        count += 1;
        try freq_table.put(c, count);
    }
    return freq_table;
}
