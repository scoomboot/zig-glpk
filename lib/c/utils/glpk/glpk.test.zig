// ╔══════════════════════════════════════ PACK ══════════════════════════════════════╗

const std = @import("std");
const testing = std.testing;
const glpk = @import("./glpk.zig");

// ╚══════════════════════════════════════════════════════════════════════════════════╝

test "glpk.getVersion returns expected value" {
    try testing.expectEqual(@as(u32, 42), glpk.getVersion());
}
