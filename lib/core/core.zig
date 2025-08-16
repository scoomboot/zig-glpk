// ╔══════════════════════════════════════ PACK ══════════════════════════════════════╗

pub const utils = .{
    .problem = @import("./utils/problem/problem.zig"),
    .solver = @import("./utils/solver/solver.zig"),
    .types = @import("./utils/types/types.zig"),
};

// ╚══════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ TEST ══════════════════════════════════════╗

test {
    // utils
    _ = @import("./utils/problem/problem.test.zig");
    _ = @import("./utils/solver/solver.test.zig");
    _ = @import("./utils/types/types.zig");  // Tests are inline in the main file
    _ = @import("./utils/types/types.test.zig");  // Comprehensive integration and edge case tests
}

// ╚══════════════════════════════════════════════════════════════════════════════════╝
