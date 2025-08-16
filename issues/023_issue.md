# Issue #023: Implement custom error handling

## Priority
🔴 Critical

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#61-error-handling)
- [Issue #004](004_issue.md) - C bindings
- [Issue #006](006_issue.md) - Problem struct

## Description
Create a comprehensive error handling system that maps GLPK error codes to meaningful Zig errors, provides helpful error messages, and ensures graceful failure handling throughout the wrapper.

## Requirements

### Error Set Definition
Create `lib/core/utils/error/error.zig`:
```zig
//! Error handling for GLPK wrapper
//! Maps GLPK error codes to Zig errors with context

const std = @import("std");

/// Main error set for GLPK operations
pub const GLPKError = error{
    // Memory errors
    OutOfMemory,
    AllocationFailed,
    
    // Problem structure errors
    InvalidRowIndex,
    InvalidColumnIndex,
    InvalidMatrixEntry,
    EmptyProblem,
    ProblemTooLarge,
    
    // Bounds and constraint errors
    InvalidBounds,
    InconsistentBounds,
    InvalidConstraint,
    
    // Solver errors
    InvalidBasis,
    SingularMatrix,
    IllConditioned,
    NumericalInstability,
    
    // LP solver specific
    NoPrimalFeasible,
    NoDualFeasible,
    LPRelaxationFailed,
    LPRelaxationInfeasible,
    
    // MIP solver specific
    NotMIPProblem,
    NoIntegerFeasible,
    InvalidMIPGap,
    InvalidIntegerTolerance,
    
    // Solution status
    Infeasible,
    Unbounded,
    Undefined,
    
    // Limits exceeded
    IterationLimit,
    TimeLimit,
    MemoryLimit,
    
    // File I/O errors
    FileNotFound,
    InvalidFileFormat,
    WriteError,
    
    // Configuration errors
    InvalidOption,
    InvalidParameter,
    InvalidTolerance,
    
    // API usage errors
    InvalidOperation,
    OperationNotSupported,
    SolverNotRun,
    
    // Unknown/generic
    UnknownError,
    GLPKInternalError,
};

/// Extended error information
pub const ErrorContext = struct {
    code: GLPKError,
    glpk_code: ?c_int,
    message: []const u8,
    suggestion: ?[]const u8,
    location: ?Location,
    
    pub const Location = struct {
        file: []const u8,
        function: []const u8,
        line: u32,
    };
    
    pub fn format(
        self: ErrorContext,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        
        try writer.print("GLPK Error: {s}\n", .{@errorName(self.code)});
        try writer.print("  Message: {s}\n", .{self.message});
        
        if (self.suggestion) |sugg| {
            try writer.print("  Suggestion: {s}\n", .{sugg});
        }
        
        if (self.glpk_code) |code| {
            try writer.print("  GLPK Code: {}\n", .{code});
        }
        
        if (self.location) |loc| {
            try writer.print("  Location: {s}:{s}:{}\n", .{ loc.file, loc.function, loc.line });
        }
    }
};
```

### Error Mapping Functions
```zig
/// Map GLPK return codes to Zig errors
pub fn mapGLPKError(glpk_code: c_int) GLPKError {
    return switch (glpk_code) {
        // Memory errors
        glpk.GLP_ENOMEM => error.OutOfMemory,
        glpk.GLP_ENOFEAS => error.NoIntegerFeasible,
        
        // Basis errors
        glpk.GLP_EBADB => error.InvalidBasis,
        glpk.GLP_ESING => error.SingularMatrix,
        glpk.GLP_ECOND => error.IllConditioned,
        
        // Bounds errors
        glpk.GLP_EBOUND => error.InvalidBounds,
        glpk.GLP_EROOT => error.LPRelaxationInfeasible,
        
        // Solver failures
        glpk.GLP_EFAIL => error.GLPKInternalError,
        glpk.GLP_EOBJLL => error.Unbounded,
        glpk.GLP_EOBJUL => error.Unbounded,
        
        // Limit errors
        glpk.GLP_EITLIM => error.IterationLimit,
        glpk.GLP_ETMLIM => error.TimeLimit,
        
        // Feasibility errors
        glpk.GLP_ENOPFS => error.NoPrimalFeasible,
        glpk.GLP_ENODFS => error.NoDualFeasible,
        
        // MIP specific
        glpk.GLP_EMIPGAP => error.InvalidMIPGap,
        glpk.GLP_EINSTAB => error.NumericalInstability,
        glpk.GLP_ENOCVG => error.IllConditioned,
        
        else => error.UnknownError,
    };
}

/// Get descriptive message for error
pub fn getErrorMessage(err: GLPKError) []const u8 {
    return switch (err) {
        error.OutOfMemory => "Insufficient memory to complete operation",
        error.InvalidRowIndex => "Row index is out of valid range",
        error.InvalidColumnIndex => "Column index is out of valid range",
        error.InvalidBounds => "Lower bound exceeds upper bound",
        error.InvalidBasis => "Basis is invalid or singular",
        error.SingularMatrix => "Constraint matrix is singular or near-singular",
        error.IllConditioned => "Problem is numerically ill-conditioned",
        error.NoPrimalFeasible => "Problem has no primal feasible solution",
        error.NoDualFeasible => "Problem has no dual feasible solution",
        error.Infeasible => "Problem has no feasible solution",
        error.Unbounded => "Problem has unbounded objective",
        error.IterationLimit => "Iteration limit exceeded",
        error.TimeLimit => "Time limit exceeded",
        error.NotMIPProblem => "Problem has no integer variables",
        error.NoIntegerFeasible => "No integer feasible solution exists",
        else => "Unknown error occurred",
    };
}

/// Get suggestion for fixing error
pub fn getErrorSuggestion(err: GLPKError) ?[]const u8 {
    return switch (err) {
        error.InvalidBounds => "Check that lower bound <= upper bound for all variables and constraints",
        error.SingularMatrix => "Check for linearly dependent constraints or remove redundant rows",
        error.IllConditioned => "Try scaling the problem or adjusting tolerances",
        error.NoPrimalFeasible => "Relax constraints or check for conflicting requirements",
        error.Unbounded => "Add bounds to variables or additional constraints",
        error.IterationLimit => "Increase iteration limit or simplify the problem",
        error.TimeLimit => "Increase time limit or use a faster solver configuration",
        error.OutOfMemory => "Reduce problem size or increase available memory",
        error.NotMIPProblem => "Set at least one variable to integer or binary type",
        else => null,
    };
}
```

### Error Handler Integration
```zig
/// Error handler that can be installed in Problem struct
pub const ErrorHandler = struct {
    context_stack: std.ArrayList(ErrorContext),
    allocator: std.mem.Allocator,
    verbose: bool,
    
    pub fn init(allocator: std.mem.Allocator) ErrorHandler {
        return .{
            .context_stack = std.ArrayList(ErrorContext).init(allocator),
            .allocator = allocator,
            .verbose = false,
        };
    }
    
    pub fn deinit(self: *ErrorHandler) void {
        self.context_stack.deinit();
    }
    
    pub fn pushContext(self: *ErrorHandler, context: ErrorContext) !void {
        try self.context_stack.append(context);
    }
    
    pub fn popContext(self: *ErrorHandler) ?ErrorContext {
        return self.context_stack.popOrNull();
    }
    
    pub fn handleError(self: *ErrorHandler, err: GLPKError, glpk_code: ?c_int) !void {
        const context = ErrorContext{
            .code = err,
            .glpk_code = glpk_code,
            .message = getErrorMessage(err),
            .suggestion = getErrorSuggestion(err),
            .location = null,
        };
        
        if (self.verbose) {
            std.debug.print("{}\n", .{context});
        }
        
        try self.pushContext(context);
        return err;
    }
    
    pub fn getLastError(self: *const ErrorHandler) ?ErrorContext {
        if (self.context_stack.items.len > 0) {
            return self.context_stack.items[self.context_stack.items.len - 1];
        }
        return null;
    }
    
    pub fn clearErrors(self: *ErrorHandler) void {
        self.context_stack.clearRetainingCapacity();
    }
};
```

### Problem Struct Integration
Update `Problem` struct to use error handler:
```zig
pub const Problem = struct {
    ptr: *glpk.c.glp_prob,
    allocator: std.mem.Allocator,
    error_handler: ?*ErrorHandler,
    
    pub fn init(allocator: std.mem.Allocator) !Problem {
        const ptr = glpk.c.glp_create_prob();
        if (ptr == null) {
            return error.OutOfMemory;
        }
        
        return Problem{
            .ptr = ptr,
            .allocator = allocator,
            .error_handler = null,
        };
    }
    
    pub fn setErrorHandler(self: *Problem, handler: *ErrorHandler) void {
        self.error_handler = handler;
    }
    
    pub fn addRows(self: *Problem, count: usize) !void {
        const first_row = glpk.c.glp_add_rows(self.ptr, @intCast(count));
        if (first_row == 0) {
            const err = error.AllocationFailed;
            if (self.error_handler) |handler| {
                try handler.handleError(err, null);
            }
            return err;
        }
    }
    
    // Update other methods similarly...
};
```

### GLPK Callback Error Handling
```zig
/// Install GLPK error hook
pub fn installGLPKErrorHook() void {
    // GLPK provides glp_error_hook for catching internal errors
    // This would need C interop to set up properly
}

/// Custom panic handler for GLPK assertions
pub fn glpkPanicHandler(msg: [*c]const u8) callconv(.C) void {
    std.debug.panic("GLPK Internal Error: {s}\n", .{msg});
}
```

### Validation Functions
```zig
/// Validate problem before solving
pub fn validateProblem(problem: *const Problem) !void {
    const rows = problem.getRowCount();
    const cols = problem.getColumnCount();
    
    if (rows == 0 or cols == 0) {
        return error.EmptyProblem;
    }
    
    // Check for valid bounds
    for (1..rows + 1) |i| {
        const bounds = try problem.getRowBounds(i);
        if (bounds.type == .double or bounds.type == .fixed) {
            if (bounds.lower > bounds.upper) {
                return error.InconsistentBounds;
            }
        }
    }
    
    for (1..cols + 1) |i| {
        const bounds = try problem.getColumnBounds(i);
        if (bounds.type == .double or bounds.type == .fixed) {
            if (bounds.lower > bounds.upper) {
                return error.InconsistentBounds;
            }
        }
    }
}

/// Validate solver options
pub fn validateSimplexOptions(options: *const SimplexOptions) !void {
    if (options.feasibility_tolerance <= 0 or options.feasibility_tolerance >= 1) {
        return error.InvalidTolerance;
    }
    if (options.optimality_tolerance <= 0 or options.optimality_tolerance >= 1) {
        return error.InvalidTolerance;
    }
    if (options.time_limit) |limit| {
        if (limit <= 0) return error.InvalidParameter;
    }
}
```

### Error Recovery Strategies
```zig
/// Try to recover from numerical issues
pub fn attemptRecovery(problem: *Problem, err: GLPKError) !void {
    switch (err) {
        error.IllConditioned => {
            // Try rescaling
            glpk.c.glp_scale_prob(problem.ptr, glpk.GLP_SF_AUTO);
        },
        error.InvalidBasis => {
            // Construct trivial basis
            glpk.c.glp_std_basis(problem.ptr);
        },
        error.NumericalInstability => {
            // Increase tolerances
            // Would need to store and modify solver options
        },
        else => return err,
    }
}
```

## Implementation Notes
- Map all GLPK error codes comprehensively
- Provide actionable error messages
- Include recovery suggestions where applicable
- Track error context for debugging
- Consider thread-local error storage
- Allow both throwing and non-throwing error handling

## Testing Requirements
- Test all error mappings
- Verify error messages are helpful
- Test error handler integration
- Test recovery strategies
- Verify no memory leaks in error paths
- Test with problematic inputs

## Dependencies
- [#004](004_issue.md) - GLPK constants needed
- [#006](006_issue.md) - Problem struct integration

## Acceptance Criteria
- [ ] Error set covers all GLPK errors
- [ ] Error mapping function complete
- [ ] Descriptive messages for all errors
- [ ] Suggestions provided where applicable
- [ ] Error handler integrated with Problem
- [ ] Validation functions implemented
- [ ] Recovery strategies available
- [ ] Tests cover error paths
- [ ] Documentation explains error handling
- [ ] No memory leaks in error handling

## Status
🔴 Not Started