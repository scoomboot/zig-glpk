// ╔══════════════════════════════════════ PACK ══════════════════════════════════════╗

const std = @import("std");
const testing = std.testing;
const problem = @import("./problem.zig");

// ╚══════════════════════════════════════════════════════════════════════════════════╝

test "problem.createProblem returns true" {
    try testing.expectEqual(true, problem.createProblem());
}
