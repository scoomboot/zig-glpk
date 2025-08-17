// solver.test.zig — Test suite for solver interfaces and implementations
//
// repo   : https://github.com/emoessner/zig-glpk
// docs   : https://github.com/emoessner/zig-glpk/blob/main/lib/core/solver
// author : https://github.com/emoessner
//
// This module contains comprehensive tests for the solver functionality,
// including unit tests, integration tests, and performance benchmarks.

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