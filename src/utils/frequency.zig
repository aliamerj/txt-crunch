const std = @import("std");

pub fn calculateFrequency(line: []const u8, allocator: std.mem.Allocator) !std.hash_map.AutoHashMap(u8, usize) {
    var freq_table = std.AutoHashMap(u8, usize).init(allocator);

    for (line) |c| {
        var count = freq_table.get(c) orelse 0;
        count += 1;
        try freq_table.put(c, count);
    }
    return freq_table;
}

test "calculate frequency" {
    const content = "4aaabbc r4";
    const freq_table = try calculateFrequency(content);

    try std.testing.expect(freq_table.get('a') == 3);
    try std.testing.expect(freq_table.get('b') == 2);
    try std.testing.expect(freq_table.get('c') == 1);
    try std.testing.expect(freq_table.get(' ') == 1);
    try std.testing.expect(freq_table.get('4') == 2);
}
