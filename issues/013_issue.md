# Issue #013: Implement Interior Point Solver (optional)

## Priority
🟢 Low

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#33-interior-point-solver-optional)
- [Issue #011](011_issue.md) - SimplexSolver
- [Issue #012](012_issue.md) - Solution retrieval

## Description
Implement an Interior Point solver as an alternative to the Simplex method. Interior point methods can be more efficient for certain types of large-scale LP problems and provide a different algorithmic approach.

## Requirements

### File Location
- Continue in `lib/core/utils/solver/solver.zig`

### InteriorPointOptions Structure
```zig
/// Configuration options for the Interior Point LP solver
pub const InteriorPointOptions = struct {
    /// Ordering algorithm for factorization
    ordering: OrderingAlgorithm = .approximate_minimum_degree,
    
    /// Message level for output
    message_level: MessageLevel = .errors_only,
    
    /// Maximum iterations
    max_iterations: usize = 200,
    
    /// Convergence tolerance
    tolerance: f64 = 1e-8,
    
    /// Convert to GLPK parameter structure
    pub fn toGLPK(self: InteriorPointOptions) glpk.c.glp_iptcp {
        var params: glpk.c.glp_iptcp = undefined;
        glpk.c.glp_init_iptcp(&params);
        
        params.msg_lev = self.message_level.toGLPK();
        params.ord_alg = self.ordering.toGLPK();
        
        return params;
    }
    
    /// Create default options
    pub fn default() InteriorPointOptions {
        return .{};
    }
};

pub const OrderingAlgorithm = enum {
    none,                        // Natural ordering
    quotient_minimum_degree,     // QMD
    approximate_minimum_degree,  // AMD
    approximate_minimum_fill,    // SYMAMD
    
    pub fn toGLPK(self: @This()) c_int {
        return switch (self) {
            .none => glpk.GLP_ORD_NONE,
            .quotient_minimum_degree => glpk.GLP_ORD_QMD,
            .approximate_minimum_degree => glpk.GLP_ORD_AMD,
            .approximate_minimum_fill => glpk.GLP_ORD_SYMAMD,
        };
    }
};
```

### InteriorPointSolver Implementation
```zig
/// Linear Programming solver using Interior Point method
pub const InteriorPointSolver = struct {
    options: InteriorPointOptions,
    stats: ?SolverStats = null,
    
    /// Create a new interior point solver
    pub fn init(options: InteriorPointOptions) InteriorPointSolver {
        return .{
            .options = options,
            .stats = null,
        };
    }
    
    /// Create with default options
    pub fn initDefault() InteriorPointSolver {
        return init(InteriorPointOptions.default());
    }
    
    /// Solve the problem using interior point method
    pub fn solve(self: *InteriorPointSolver, problem: *Problem) !SolutionStatus {
        // Convert options to GLPK format
        var params = self.options.toGLPK();
        
        // Call GLPK interior point solver
        const ret = glpk.c.glp_interior(problem.ptr, &params);
        
        // Handle return codes
        switch (ret) {
            0 => {}, // Success
            glpk.GLP_EFAIL => return error.SolverFailed,
            glpk.GLP_ENOCVG => return error.NoConvergence,
            glpk.GLP_EITLIM => return error.IterationLimit,
            glpk.GLP_EINSTAB => return error.NumericalInstability,
            else => return error.UnknownError,
        }
        
        // Get interior point solution status
        const status = glpk.c.glp_ipt_status(problem.ptr);
        const solution_status = types.SolutionStatus.fromGLPKInterior(status);
        
        // Collect statistics
        self.stats = SolverStats{
            .iterations = 0, // TODO: Get from GLPK if available
            .solve_time = 0, // TODO: Get actual time
            .status = solution_status,
        };
        
        return solution_status;
    }
    
    /// Get solver statistics
    pub fn getStats(self: *const InteriorPointSolver) ?SolverStats {
        return self.stats;
    }
};
```

### Interior Point Solution Retrieval
```zig
// Add these methods to Problem struct

/// Get interior point solution status
pub fn getInteriorStatus(self: *const Problem) types.SolutionStatus {
    const status = glpk.c.glp_ipt_status(self.ptr);
    return types.SolutionStatus.fromGLPKInterior(status);
}

/// Get interior point objective value
pub fn getInteriorObjectiveValue(self: *const Problem) f64 {
    return glpk.c.glp_ipt_obj_val(self.ptr);
}

/// Get interior point column value
pub fn getInteriorColumnPrimal(self: *const Problem, col: usize) f64 {
    return glpk.c.glp_ipt_col_prim(self.ptr, @intCast(col));
}

/// Get interior point row value
pub fn getInteriorRowPrimal(self: *const Problem, row: usize) f64 {
    return glpk.c.glp_ipt_row_prim(self.ptr, @intCast(row));
}

/// Get interior point column dual
pub fn getInteriorColumnDual(self: *const Problem, col: usize) f64 {
    return glpk.c.glp_ipt_col_dual(self.ptr, @intCast(col));
}

/// Get interior point row dual
pub fn getInteriorRowDual(self: *const Problem, row: usize) f64 {
    return glpk.c.glp_ipt_row_dual(self.ptr, @intCast(row));
}

/// Get complete interior point solution
pub fn getInteriorSolution(self: *const Problem, allocator: std.mem.Allocator) !Solution {
    const n_rows = self.getRowCount();
    const n_cols = self.getColumnCount();
    
    var col_primals = try allocator.alloc(f64, n_cols);
    var row_primals = try allocator.alloc(f64, n_rows);
    var col_duals = try allocator.alloc(f64, n_cols);
    var row_duals = try allocator.alloc(f64, n_rows);
    
    for (1..n_cols + 1) |i| {
        col_primals[i - 1] = self.getInteriorColumnPrimal(i);
        col_duals[i - 1] = self.getInteriorColumnDual(i);
    }
    
    for (1..n_rows + 1) |i| {
        row_primals[i - 1] = self.getInteriorRowPrimal(i);
        row_duals[i - 1] = self.getInteriorRowDual(i);
    }
    
    return Solution{
        .status = self.getInteriorStatus(),
        .objective_value = self.getInteriorObjectiveValue(),
        .column_primals = col_primals,
        .row_primals = row_primals,
        .column_duals = col_duals,
        .row_duals = row_duals,
        .allocator = allocator,
    };
}
```

### Comparison with Simplex
```zig
/// Helper to choose between Simplex and Interior Point
pub const SolverChoice = enum {
    simplex,
    interior_point,
    auto, // Choose based on problem characteristics
    
    /// Recommend solver based on problem size
    pub fn recommend(problem: *const Problem) SolverChoice {
        const rows = problem.getRowCount();
        const cols = problem.getColumnCount();
        const nnz = problem.getNonZeroCount();
        
        // Interior point often better for large, sparse problems
        if (rows > 10000 or cols > 10000) {
            const density = @as(f64, @floatFromInt(nnz)) / 
                           @as(f64, @floatFromInt(rows * cols));
            if (density < 0.01) { // Very sparse
                return .interior_point;
            }
        }
        
        return .simplex;
    }
};
```

## Implementation Notes
- Interior point methods work differently from simplex
- They approach optimality from the interior of the feasible region
- No basis information available (interior solutions)
- May be faster for large, sparse problems
- Solution may be slightly interior to constraints
- Generally more numerically stable for ill-conditioned problems

## Testing Requirements
- Test solving with interior point method
- Compare results with simplex solver
- Test on large sparse problems
- Test convergence tolerance settings
- Test different ordering algorithms
- Verify solution retrieval methods
- Benchmark against simplex for various problem types

## Dependencies
- [#011](011_issue.md) - Similar structure to SimplexSolver
- [#012](012_issue.md) - Solution retrieval patterns

## Acceptance Criteria
- [ ] InteriorPointOptions structure defined
- [ ] InteriorPointSolver implemented
- [ ] solve() method works correctly
- [ ] Interior solution retrieval methods work
- [ ] Ordering algorithms configurable
- [ ] Tests compare with simplex results
- [ ] Performance acceptable for large problems
- [ ] Documentation explains when to use
- [ ] Solver choice helper implemented

## Status
🟢 Not Started