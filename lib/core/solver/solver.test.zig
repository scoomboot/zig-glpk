// solver.test.zig — Test suite for solver interfaces and implementations
//
// repo   : https://github.com/scoomboot/zig-glpk
// docs   : https://scoomboot.github.io/zig-glpk/lib/core/solver
// author : https://github.com/scoomboot
//
// Vibe coded by Scoom.

// ╔══════════════════════════════════════ PACK ══════════════════════════════════════╗

    const std = @import("std");
    const testing = std.testing;
    const solver = @import("./solver.zig");

// ╚══════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ TEST ══════════════════════════════════════╗

    test "unit: Solver: solve returns expected value" {
        try testing.expectEqual(@as(i32, 100), solver.solve());
    }

// ╚══════════════════════════════════════════════════════════════════════════════════╝