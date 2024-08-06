const std = @import("std");
const frequency = @import("./frequency.zig");

test "calculate frequency" {
    const content = "4aaabbc r4";
    const freq_table = try frequency.calculateFrequency(content);

    try std.testing.expect(freq_table.get('a') == 3);
    try std.testing.expect(freq_table.get('b') == 2);
    try std.testing.expect(freq_table.get('c') == 1);
    try std.testing.expect(freq_table.get(' ') == 1);
    try std.testing.expect(freq_table.get('4') == 2);
}
