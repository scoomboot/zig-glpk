// ╔══════════════════════════════════════ PACK ══════════════════════════════════════╗

const std = @import("std");
const testing = std.testing;
const solver = @import("./solver.zig");

// ╚══════════════════════════════════════════════════════════════════════════════════╝

test "solver.solve returns 100" {
    try testing.expectEqual(@as(i32, 100), solver.solve());
}
