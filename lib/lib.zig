// lib.zig — Central entry point for I/O library.

// ╔══════════════════════════════════════ PACK ══════════════════════════════════════╗

/// Provides utilities for string manipulation and operations.
pub const core = @import("./core/core.zig");
pub const c = @import("./c/c.zig");

// ╚══════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ TEST ══════════════════════════════════════╗

test {
    _ = @import("./core/core.zig");
    _ = @import("./c/c.zig");
}

// ╚══════════════════════════════════════════════════════════════════════════════════╝
