// ╔══════════════════════════════════════ PACK ══════════════════════════════════════╗

pub const utils = .{
    .glpk = @import("./utils/glpk/glpk.zig"),
};

// ╚══════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ TEST ══════════════════════════════════════╗

test {
    // utils - import both unit tests (inline) and integration tests (external)
    _ = @import("./utils/glpk/glpk.zig");       // Unit tests
    _ = @import("./utils/glpk/glpk.test.zig");  // Integration and stress tests
}

// ╚══════════════════════════════════════════════════════════════════════════════════╝
