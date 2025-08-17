// core.zig — Core module exports for zig-glpk
//
// repo   : https://github.com/scoomboot/zig-glpk
// docs   : https://scoomboot.github.io/zig-glpk/lib/core
// author : https://github.com/scoomboot
//
// Vibe coded by Scoom.

// ╔══════════════════════════════════════ PACK ══════════════════════════════════════╗

    const std = @import("std");

// ╚══════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ CORE ══════════════════════════════════════╗

    // ┌──────────────────────────── Module Exports ────────────────────────────┐
    
        /// Problem definition and management
        pub const problem = @import("./problem/problem.zig");
        
        /// Solver interfaces and implementations
        pub const solver = @import("./solver/solver.zig");
        
        /// Type definitions and conversions
        pub const types = @import("./types/types.zig");
    
    // └──────────────────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ TEST ══════════════════════════════════════╗

    test {
        // Core modules
        _ = @import("./problem/problem.test.zig");
        _ = @import("./solver/solver.test.zig");
        _ = @import("./types/types.zig");  // Tests are inline in the main file
        _ = @import("./types/types.test.zig");  // Comprehensive integration and edge case tests
    }

// ╚══════════════════════════════════════════════════════════════════════════════════╝