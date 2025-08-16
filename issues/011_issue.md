# Issue #011: Implement SimplexSolver with solve method

## Priority
🔴 Critical

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#32-lp-solver-implementation)
- [Issue #006](006_issue.md) - Problem struct
- [Issue #010](010_issue.md) - SimplexOptions

## Description
Implement the SimplexSolver struct that uses GLPK's simplex method to solve linear programming problems. This is the core solver interface that users will interact with to find optimal solutions.

## Requirements

### File Location
- Continue in `lib/core/utils/solver/solver.zig`

### SimplexSolver Implementation
```zig
/// Linear Programming solver using the Simplex method
pub const SimplexSolver = struct {
    options: SimplexOptions,
    stats: ?SolverStats = null,
    
    /// Create a new solver with given options
    pub fn init(options: SimplexOptions) SimplexSolver {
        return .{
            .options = options,
            .stats = null,
        };
    }
    
    /// Create a solver with default options
    pub fn initDefault() SimplexSolver {
        return init(SimplexOptions.default());
    }
    
    /// Solve the given problem
    pub fn solve(self: *SimplexSolver, problem: *Problem) !SolutionStatus {
        // Validate options
        try self.options.validate();
        
        // Convert options to GLPK format
        var params = self.options.toGLPK();
        
        // Call GLPK simplex solver
        const ret = glpk.c.glp_simplex(problem.ptr, &params);
        
        // Handle return codes
        switch (ret) {
            0 => {}, // Success
            glpk.GLP_EBADB => return error.InvalidBasis,
            glpk.GLP_ESING => return error.SingularMatrix,
            glpk.GLP_ECOND => return error.IllConditioned,
            glpk.GLP_EBOUND => return error.InvalidBounds,
            glpk.GLP_EFAIL => return error.SolverFailed,
            glpk.GLP_EOBJLL => return error.ObjectiveLowerLimit,
            glpk.GLP_EOBJUL => return error.ObjectiveUpperLimit,
            glpk.GLP_EITLIM => return error.IterationLimit,
            glpk.GLP_ETMLIM => return error.TimeLimit,
            glpk.GLP_ENOPFS => return error.NoPrimalFeasible,
            glpk.GLP_ENODFS => return error.NoDualFeasible,
            else => return error.UnknownError,
        }
        
        // Get solution status
        const status = glpk.c.glp_get_status(problem.ptr);
        const solution_status = types.SolutionStatus.fromGLPK(status);
        
        // Collect statistics
        self.stats = SolverStats{
            .iterations = @intCast(glpk.c.glp_get_it_cnt(problem.ptr)),
            .solve_time = 0, // TODO: Get actual time
            .status = solution_status,
        };
        
        return solution_status;
    }
    
    /// Get solver statistics from last solve
    pub fn getStats(self: *const SimplexSolver) ?SolverStats {
        return self.stats;
    }
    
    /// Check if last solve was successful
    pub fn isOptimal(self: *const SimplexSolver) bool {
        if (self.stats) |stats| {
            return stats.status == .optimal;
        }
        return false;
    }
};
```

### Solver Statistics
```zig
/// Statistics from a solver run
pub const SolverStats = struct {
    iterations: usize,
    solve_time: f64, // seconds
    status: types.SolutionStatus,
    
    pub fn print(self: SolverStats, writer: anytype) !void {
        try writer.print("Solver Statistics:\n", .{});
        try writer.print("  Status: {s}\n", .{@tagName(self.status)});
        try writer.print("  Iterations: {}\n", .{self.iterations});
        try writer.print("  Time: {d:.3}s\n", .{self.solve_time});
    }
};
```

### Advanced Solver Methods
```zig
impl SimplexSolver {
    /// Warm start from a previous solution
    pub fn solveWarmStart(self: *SimplexSolver, problem: *Problem) !SolutionStatus {
        // Use existing basis if available
        var params = self.options.toGLPK();
        params.presolve = glpk.GLP_OFF; // Disable presolve for warm start
        
        const ret = glpk.c.glp_simplex(problem.ptr, &params);
        // ... handle as in solve()
    }
    
    /// Solve with basis provided
    pub fn solveWithBasis(self: *SimplexSolver, problem: *Problem, basis: Basis) !SolutionStatus {
        // Load basis
        try basis.loadInto(problem);
        // Solve with warm start
        return self.solveWarmStart(problem);
    }
    
    /// Get current basis from problem
    pub fn getBasis(self: *SimplexSolver, problem: *Problem, allocator: std.mem.Allocator) !Basis {
        // Extract basis status for rows and columns
        // Return Basis struct
    }
}
```

### Basis Management
```zig
/// Basis information for warm starting
pub const Basis = struct {
    row_status: []BasisStatus,
    col_status: []BasisStatus,
    allocator: std.mem.Allocator,
    
    pub fn deinit(self: *Basis) void {
        self.allocator.free(self.row_status);
        self.allocator.free(self.col_status);
    }
    
    pub fn loadInto(self: *const Basis, problem: *Problem) !void {
        // Set basis status for each row and column
    }
};

pub const BasisStatus = enum {
    basic,
    non_basic_lower,
    non_basic_upper,
    non_basic_free,
    non_basic_fixed,
    
    pub fn toGLPK(self: @This()) c_int {
        // Convert to GLP_BS_* constants
    }
    
    pub fn fromGLPK(value: c_int) BasisStatus {
        // Convert from GLP_BS_* constants
    }
};
```

### Error Handling
```zig
/// Detailed error information
pub const SolverError = struct {
    code: ErrorCode,
    message: []const u8,
    
    pub const ErrorCode = enum {
        invalid_basis,
        singular_matrix,
        ill_conditioned,
        invalid_bounds,
        iteration_limit,
        time_limit,
        no_feasible,
        unknown,
    };
};
```

## Implementation Notes
- The solver modifies the problem's internal state
- Multiple solves on the same problem are allowed
- Warm starting can significantly improve performance
- Consider thread safety - GLPK may not be thread-safe
- Stats should be updated after each solve
- Handle all GLPK return codes properly

## Testing Requirements
- Test solving simple LP problems
- Test infeasible problems
- Test unbounded problems
- Test time and iteration limits
- Test warm starting
- Test basis extraction and loading
- Test solver statistics collection
- Test error handling for various failure modes
- Benchmark performance on standard problems

## Dependencies
- [#006](006_issue.md) - Problem struct needed
- [#010](010_issue.md) - SimplexOptions needed

## Acceptance Criteria
- [ ] SimplexSolver struct implemented
- [ ] solve() method works for basic LP
- [ ] All GLPK error codes handled
- [ ] Solution status correctly determined
- [ ] Solver statistics collected
- [ ] Warm start functionality works
- [ ] Basis management implemented
- [ ] Tests cover various problem types
- [ ] Performance acceptable for test problems
- [ ] Documentation explains usage

## Status
🔴 Not Started