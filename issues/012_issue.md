# Issue #012: Add LP solution retrieval methods

## Priority
🟡 Medium

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#32-lp-solver-implementation)
- [Issue #006](006_issue.md) - Problem struct
- [Issue #011](011_issue.md) - SimplexSolver

## Description
Add methods to the Problem struct for retrieving solution values after solving an LP problem. These methods allow users to extract the optimal variable values, dual values, reduced costs, and other solution information.

## Requirements

### File Location
- Add to `lib/core/utils/problem/problem.zig`

### Solution Status Methods
```zig
/// Get the solution status from the last solve
pub fn getSolutionStatus(self: *const Problem) types.SolutionStatus {
    const status = glpk.c.glp_get_status(self.ptr);
    return types.SolutionStatus.fromGLPK(status);
}

/// Check if the problem has been solved to optimality
pub fn isOptimal(self: *const Problem) bool {
    return self.getSolutionStatus() == .optimal;
}

/// Get the primal status
pub fn getPrimalStatus(self: *const Problem) types.SolutionStatus {
    const status = glpk.c.glp_get_prim_stat(self.ptr);
    return types.SolutionStatus.fromGLPK(status);
}

/// Get the dual status
pub fn getDualStatus(self: *const Problem) types.SolutionStatus {
    const status = glpk.c.glp_get_dual_stat(self.ptr);
    return types.SolutionStatus.fromGLPK(status);
}
```

### Objective Value Methods
```zig
/// Get the optimal objective value
pub fn getObjectiveValue(self: *const Problem) f64 {
    return glpk.c.glp_get_obj_val(self.ptr);
}

/// Get the constant term of the objective
pub fn getObjectiveConstant(self: *const Problem) f64 {
    return glpk.c.glp_get_obj_coef(self.ptr, 0);
}

/// Get the total objective value including constant
pub fn getTotalObjectiveValue(self: *const Problem) f64 {
    return self.getObjectiveValue();
}
```

### Primal Solution Methods
```zig
/// Get the primal value of a column (variable value)
pub fn getColumnPrimal(self: *const Problem, col: usize) f64 {
    return glpk.c.glp_get_col_prim(self.ptr, @intCast(col));
}

/// Get all column primal values
pub fn getColumnPrimals(self: *const Problem, allocator: std.mem.Allocator) ![]f64 {
    const n_cols = self.getColumnCount();
    var values = try allocator.alloc(f64, n_cols);
    for (1..n_cols + 1) |i| {
        values[i - 1] = self.getColumnPrimal(i);
    }
    return values;
}

/// Get the primal value of a row (constraint activity)
pub fn getRowPrimal(self: *const Problem, row: usize) f64 {
    return glpk.c.glp_get_row_prim(self.ptr, @intCast(row));
}

/// Get all row primal values
pub fn getRowPrimals(self: *const Problem, allocator: std.mem.Allocator) ![]f64 {
    const n_rows = self.getRowCount();
    var values = try allocator.alloc(f64, n_rows);
    for (1..n_rows + 1) |i| {
        values[i - 1] = self.getRowPrimal(i);
    }
    return values;
}
```

### Dual Solution Methods
```zig
/// Get the dual value of a column (reduced cost)
pub fn getColumnDual(self: *const Problem, col: usize) f64 {
    return glpk.c.glp_get_col_dual(self.ptr, @intCast(col));
}

/// Get all column dual values (reduced costs)
pub fn getColumnDuals(self: *const Problem, allocator: std.mem.Allocator) ![]f64 {
    const n_cols = self.getColumnCount();
    var values = try allocator.alloc(f64, n_cols);
    for (1..n_cols + 1) |i| {
        values[i - 1] = self.getColumnDual(i);
    }
    return values;
}

/// Get the dual value of a row (shadow price)
pub fn getRowDual(self: *const Problem, row: usize) f64 {
    return glpk.c.glp_get_row_dual(self.ptr, @intCast(row));
}

/// Get all row dual values (shadow prices)
pub fn getRowDuals(self: *const Problem, allocator: std.mem.Allocator) ![]f64 {
    const n_rows = self.getRowCount();
    var values = try allocator.alloc(f64, n_rows);
    for (1..n_rows + 1) |i| {
        values[i - 1] = self.getRowDual(i);
    }
    return values;
}

/// Get shadow price (alias for row dual)
pub fn getShadowPrice(self: *const Problem, row: usize) f64 {
    return self.getRowDual(row);
}

/// Get reduced cost (alias for column dual)
pub fn getReducedCost(self: *const Problem, col: usize) f64 {
    return self.getColumnDual(col);
}
```

### Solution Structure
```zig
/// Complete solution information
pub const Solution = struct {
    status: types.SolutionStatus,
    objective_value: f64,
    column_primals: []f64,
    row_primals: []f64,
    column_duals: []f64,
    row_duals: []f64,
    allocator: std.mem.Allocator,
    
    pub fn deinit(self: *Solution) void {
        self.allocator.free(self.column_primals);
        self.allocator.free(self.row_primals);
        self.allocator.free(self.column_duals);
        self.allocator.free(self.row_duals);
    }
    
    /// Print solution summary
    pub fn print(self: *const Solution, writer: anytype) !void {
        try writer.print("Solution Status: {s}\n", .{@tagName(self.status)});
        try writer.print("Objective Value: {d:.6}\n", .{self.objective_value});
        
        try writer.print("Variable Values:\n", .{});
        for (self.column_primals, 1..) |val, i| {
            if (val != 0) {
                try writer.print("  x[{}] = {d:.6}\n", .{ i, val });
            }
        }
        
        if (self.status == .optimal) {
            try writer.print("Shadow Prices:\n", .{});
            for (self.row_duals, 1..) |val, i| {
                if (val != 0) {
                    try writer.print("  row[{}] = {d:.6}\n", .{ i, val });
                }
            }
        }
    }
};

/// Get complete solution
pub fn getSolution(self: *const Problem, allocator: std.mem.Allocator) !Solution {
    return Solution{
        .status = self.getSolutionStatus(),
        .objective_value = self.getObjectiveValue(),
        .column_primals = try self.getColumnPrimals(allocator),
        .row_primals = try self.getRowPrimals(allocator),
        .column_duals = try self.getColumnDuals(allocator),
        .row_duals = try self.getRowDuals(allocator),
        .allocator = allocator,
    };
}
```

### Basis Information Methods
```zig
/// Get basis status of a column
pub fn getColumnBasisStatus(self: *const Problem, col: usize) BasisStatus {
    const status = glpk.c.glp_get_col_stat(self.ptr, @intCast(col));
    return BasisStatus.fromGLPK(status);
}

/// Get basis status of a row
pub fn getRowBasisStatus(self: *const Problem, row: usize) BasisStatus {
    const status = glpk.c.glp_get_row_stat(self.ptr, @intCast(row));
    return BasisStatus.fromGLPK(status);
}

/// Check if a variable is basic
pub fn isColumnBasic(self: *const Problem, col: usize) bool {
    return self.getColumnBasisStatus(col) == .basic;
}

/// Check if a constraint is basic
pub fn isRowBasic(self: *const Problem, row: usize) bool {
    return self.getRowBasisStatus(row) == .basic;
}
```

### Sensitivity Analysis Methods (Optional)
```zig
/// Get objective coefficient range for maintaining optimality
pub fn getObjectiveCoefficientRange(self: *const Problem, col: usize) !struct { lower: f64, upper: f64 } {
    // Use glp_analyze_coef if available
    // Return range where current basis remains optimal
}

/// Get constraint bound range for maintaining feasibility
pub fn getConstraintBoundRange(self: *const Problem, row: usize) !struct { lower: f64, upper: f64 } {
    // Use glp_analyze_bound if available
    // Return range where current basis remains feasible
}
```

## Implementation Notes
- All indices should be converted from 0-based (Zig) to 1-based (GLPK)
- Solution values are only meaningful after a successful solve
- Consider caching solution values if accessed frequently
- Dual values (shadow prices) indicate constraint importance
- Reduced costs indicate variable optimality

## Testing Requirements
- Test retrieval after successful solve
- Test retrieval with no solution available
- Test all value types (primal, dual, objective)
- Test basis status methods
- Test solution structure creation and cleanup
- Verify correct index conversion
- Test with various problem sizes
- Verify values match expected solutions

## Dependencies
- [#006](006_issue.md) - Problem struct needed
- [#011](011_issue.md) - Need to solve before retrieving

## Acceptance Criteria
- [ ] Solution status methods work
- [ ] Objective value retrieval works
- [ ] Column primal values retrieved correctly
- [ ] Row primal values retrieved correctly
- [ ] Column dual values (reduced costs) work
- [ ] Row dual values (shadow prices) work
- [ ] Complete solution structure works
- [ ] Basis status methods implemented
- [ ] Tests verify correctness
- [ ] Documentation explains dual values

## Status
🟡 Not Started