# Issue #017: Add MIP-specific solution retrieval methods

## Priority
🟡 Medium

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#43-mip-solver-implementation)
- [Issue #016](016_issue.md) - MIPSolver

## Description
Add methods to the Problem struct for retrieving MIP solution values after solving a mixed integer programming problem. These methods are specific to integer solutions and differ from the LP solution retrieval methods.

## Requirements

### File Location
- Add to `lib/core/utils/problem/problem.zig`

### MIP Solution Status Methods
```zig
/// Get the MIP solution status
pub fn getMIPStatus(self: *const Problem) types.SolutionStatus {
    const status = glpk.c.glp_mip_status(self.ptr);
    return types.SolutionStatus.fromGLPKMIP(status);
}

/// Check if MIP solution is optimal
pub fn isMIPOptimal(self: *const Problem) bool {
    return self.getMIPStatus() == .optimal;
}

/// Check if MIP solution is feasible (but not necessarily optimal)
pub fn isMIPFeasible(self: *const Problem) bool {
    const status = self.getMIPStatus();
    return status == .optimal or status == .feasible;
}

/// Get the MIP gap (relative difference from best bound)
pub fn getMIPGap(self: *const Problem) f64 {
    // Calculate gap between integer solution and best bound
    const mip_obj = self.getMIPObjectiveValue();
    const lp_obj = self.getObjectiveValue(); // LP relaxation bound
    
    if (@abs(mip_obj) < 1e-10) {
        return @abs(lp_obj - mip_obj);
    }
    return @abs(lp_obj - mip_obj) / @abs(mip_obj);
}
```

### MIP Objective Value Methods
```zig
/// Get the MIP objective value
pub fn getMIPObjectiveValue(self: *const Problem) f64 {
    return glpk.c.glp_mip_obj_val(self.ptr);
}

/// Compare MIP objective with LP relaxation
pub fn getMIPRelaxationGap(self: *const Problem) f64 {
    const mip_val = self.getMIPObjectiveValue();
    const lp_val = self.getObjectiveValue();
    return @abs(mip_val - lp_val);
}
```

### MIP Variable Value Methods
```zig
/// Get the MIP value of a column (integer solution)
pub fn getMIPColumnValue(self: *const Problem, col: usize) f64 {
    return glpk.c.glp_mip_col_val(self.ptr, @intCast(col));
}

/// Get all MIP column values
pub fn getMIPColumnValues(self: *const Problem, allocator: std.mem.Allocator) ![]f64 {
    const n_cols = self.getColumnCount();
    var values = try allocator.alloc(f64, n_cols);
    for (1..n_cols + 1) |i| {
        values[i - 1] = self.getMIPColumnValue(i);
    }
    return values;
}

/// Get the MIP value of a row (constraint activity)
pub fn getMIPRowValue(self: *const Problem, row: usize) f64 {
    return glpk.c.glp_mip_row_val(self.ptr, @intCast(row));
}

/// Get all MIP row values
pub fn getMIPRowValues(self: *const Problem, allocator: std.mem.Allocator) ![]f64 {
    const n_rows = self.getRowCount();
    var values = try allocator.alloc(f64, n_rows);
    for (1..n_rows + 1) |i| {
        values[i - 1] = self.getMIPRowValue(i);
    }
    return values;
}
```

### Integer Variable Specific Methods
```zig
/// Get only integer variable values
pub fn getMIPIntegerValues(self: *const Problem, allocator: std.mem.Allocator) !IntegerValues {
    var indices = std.ArrayList(usize).init(allocator);
    var values = std.ArrayList(f64).init(allocator);
    
    const n_cols = self.getColumnCount();
    for (1..n_cols + 1) |i| {
        const kind = try self.getColumnKind(i);
        if (kind != .continuous) {
            try indices.append(i);
            try values.append(self.getMIPColumnValue(i));
        }
    }
    
    return IntegerValues{
        .indices = try indices.toOwnedSlice(),
        .values = try values.toOwnedSlice(),
        .allocator = allocator,
    };
}

pub const IntegerValues = struct {
    indices: []usize,
    values: []f64,
    allocator: std.mem.Allocator,
    
    pub fn deinit(self: *IntegerValues) void {
        self.allocator.free(self.indices);
        self.allocator.free(self.values);
    }
};

/// Get only binary variable values
pub fn getMIPBinaryValues(self: *const Problem, allocator: std.mem.Allocator) !BinaryValues {
    var indices = std.ArrayList(usize).init(allocator);
    var values = std.ArrayList(bool).init(allocator);
    
    const n_cols = self.getColumnCount();
    for (1..n_cols + 1) |i| {
        const kind = try self.getColumnKind(i);
        if (kind == .binary) {
            try indices.append(i);
            const val = self.getMIPColumnValue(i);
            try values.append(val > 0.5); // Round to boolean
        }
    }
    
    return BinaryValues{
        .indices = try indices.toOwnedSlice(),
        .values = try values.toOwnedSlice(),
        .allocator = allocator,
    };
}

pub const BinaryValues = struct {
    indices: []usize,
    values: []bool,
    allocator: std.mem.Allocator,
    
    pub fn deinit(self: *BinaryValues) void {
        self.allocator.free(self.indices);
        self.allocator.free(self.values);
    }
};
```

### MIP Solution Validation
```zig
/// Check if current MIP solution satisfies integrality constraints
pub fn isMIPSolutionInteger(self: *const Problem) bool {
    const n_cols = self.getColumnCount();
    
    for (1..n_cols + 1) |i| {
        const kind = self.getColumnKind(i) catch continue;
        if (kind != .continuous) {
            const val = self.getMIPColumnValue(i);
            const rounded = @round(val);
            if (@abs(val - rounded) > 1e-9) {
                return false;
            }
        }
    }
    return true;
}

/// Validate that MIP solution satisfies all constraints
pub fn validateMIPSolution(self: *const Problem) !ValidationResult {
    var violations = std.ArrayList(ConstraintViolation).init(self.allocator);
    defer violations.deinit();
    
    const n_rows = self.getRowCount();
    for (1..n_rows + 1) |i| {
        const activity = self.getMIPRowValue(i);
        const bounds = try self.getRowBounds(i);
        
        var violated = false;
        var violation_amount: f64 = 0;
        
        switch (bounds.type) {
            .lower => {
                if (activity < bounds.lower - 1e-9) {
                    violated = true;
                    violation_amount = bounds.lower - activity;
                }
            },
            .upper => {
                if (activity > bounds.upper + 1e-9) {
                    violated = true;
                    violation_amount = activity - bounds.upper;
                }
            },
            .double => {
                if (activity < bounds.lower - 1e-9) {
                    violated = true;
                    violation_amount = bounds.lower - activity;
                } else if (activity > bounds.upper + 1e-9) {
                    violated = true;
                    violation_amount = activity - bounds.upper;
                }
            },
            .fixed => {
                if (@abs(activity - bounds.lower) > 1e-9) {
                    violated = true;
                    violation_amount = @abs(activity - bounds.lower);
                }
            },
            .free => {},
        }
        
        if (violated) {
            try violations.append(.{
                .row = i,
                .activity = activity,
                .bounds = bounds,
                .violation = violation_amount,
            });
        }
    }
    
    return ValidationResult{
        .is_valid = violations.items.len == 0,
        .violations = try violations.toOwnedSlice(),
        .allocator = self.allocator,
    };
}

pub const ConstraintViolation = struct {
    row: usize,
    activity: f64,
    bounds: RowBounds,
    violation: f64,
};

pub const ValidationResult = struct {
    is_valid: bool,
    violations: []ConstraintViolation,
    allocator: std.mem.Allocator,
    
    pub fn deinit(self: *ValidationResult) void {
        self.allocator.free(self.violations);
    }
};
```

### Complete MIP Solution Structure
```zig
/// Complete MIP solution information
pub const MIPSolution = struct {
    status: types.SolutionStatus,
    objective_value: f64,
    column_values: []f64,
    row_values: []f64,
    gap: f64,
    is_integer_feasible: bool,
    allocator: std.mem.Allocator,
    
    pub fn deinit(self: *MIPSolution) void {
        self.allocator.free(self.column_values);
        self.allocator.free(self.row_values);
    }
    
    /// Create from problem
    pub fn fromProblem(problem: *const Problem, allocator: std.mem.Allocator) !MIPSolution {
        return .{
            .status = problem.getMIPStatus(),
            .objective_value = problem.getMIPObjectiveValue(),
            .column_values = try problem.getMIPColumnValues(allocator),
            .row_values = try problem.getMIPRowValues(allocator),
            .gap = problem.getMIPGap(),
            .is_integer_feasible = problem.isMIPSolutionInteger(),
            .allocator = allocator,
        };
    }
    
    /// Print solution summary
    pub fn print(self: *const MIPSolution, writer: anytype) !void {
        try writer.print("MIP Solution:\n", .{});
        try writer.print("  Status: {s}\n", .{@tagName(self.status)});
        try writer.print("  Objective: {d:.6}\n", .{self.objective_value});
        try writer.print("  Gap: {d:.2%}\n", .{self.gap});
        try writer.print("  Integer feasible: {}\n", .{self.is_integer_feasible});
        
        // Print non-zero integer variables
        try writer.print("  Integer variables:\n", .{});
        for (self.column_values, 1..) |val, i| {
            if (val != 0 and @abs(val - @round(val)) < 1e-9) {
                try writer.print("    x[{}] = {d:.0}\n", .{ i, val });
            }
        }
    }
};

/// Get complete MIP solution
pub fn getMIPSolution(self: *const Problem, allocator: std.mem.Allocator) !MIPSolution {
    return MIPSolution.fromProblem(self, allocator);
}
```

## Implementation Notes
- MIP solutions should have integer values for integer variables
- Floating point comparisons need tolerance for integrality checks
- MIP gap is important for solution quality assessment
- Solution validation helps debug model issues
- Consider rounding display of integer values

## Testing Requirements
- Test MIP solution retrieval after solve
- Test integer value extraction
- Test binary value extraction
- Test solution validation
- Test gap calculation
- Test with fractional solutions (should not happen)
- Verify integrality checking
- Test with various MIP problem types

## Dependencies
- [#016](016_issue.md) - MIPSolver must solve first

## Acceptance Criteria
- [ ] MIP status retrieval works
- [ ] MIP objective value retrieval works
- [ ] MIP column values retrieved correctly
- [ ] MIP row values retrieved correctly
- [ ] Integer-only value extraction works
- [ ] Binary value extraction works
- [ ] Solution validation implemented
- [ ] Gap calculation correct
- [ ] Integrality checking works
- [ ] Complete MIP solution structure works
- [ ] Tests verify correctness

## Status
🟡 Not Started