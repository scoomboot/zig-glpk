# Issue #014: Add MIP extensions to Problem struct

## Priority
🟡 Medium

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#41-mip-extensions-to-problem)
- [Issue #006](006_issue.md) - Problem struct
- [Issue #008](008_issue.md) - Column management

## Description
Extend the Problem struct with Mixed Integer Programming (MIP) specific functionality. This includes setting variable types (continuous, integer, binary) and managing MIP-specific problem attributes.

## Requirements

### File Location
- Add to `lib/core/utils/problem/problem.zig`

### Variable Type Management
```zig
/// Set the kind of a column (continuous, integer, or binary)
pub fn setColumnKind(self: *Problem, col: usize, kind: types.VariableKind) !void {
    if (col == 0 or col > self.getColumnCount()) {
        return error.InvalidColumnIndex;
    }
    
    const glpk_kind = kind.toGLPK();
    glpk.c.glp_set_col_kind(self.ptr, @intCast(col), glpk_kind);
    
    // For binary variables, also set bounds
    if (kind == .binary) {
        try self.setColumnRangeBounds(col, 0, 1);
    }
}

/// Get the kind of a column
pub fn getColumnKind(self: *const Problem, col: usize) !types.VariableKind {
    if (col == 0 or col > self.getColumnCount()) {
        return error.InvalidColumnIndex;
    }
    
    const kind = glpk.c.glp_get_col_kind(self.ptr, @intCast(col));
    return types.VariableKind.fromGLPK(kind);
}

/// Set multiple columns to integer
pub fn setColumnsInteger(self: *Problem, cols: []const usize) !void {
    for (cols) |col| {
        try self.setColumnKind(col, .integer);
    }
}

/// Set multiple columns to binary
pub fn setColumnsBinary(self: *Problem, cols: []const usize) !void {
    for (cols) |col| {
        try self.setColumnKind(col, .binary);
    }
}

/// Set all columns to integer
pub fn setAllColumnsInteger(self: *Problem) !void {
    const n_cols = self.getColumnCount();
    for (1..n_cols + 1) |col| {
        try self.setColumnKind(col, .integer);
    }
}
```

### MIP Problem Information
```zig
/// Check if the problem has integer variables
pub fn hasIntegerVariables(self: *const Problem) bool {
    const n_cols = self.getColumnCount();
    for (1..n_cols + 1) |col| {
        const kind = self.getColumnKind(col) catch continue;
        if (kind != .continuous) {
            return true;
        }
    }
    return false;
}

/// Get the number of integer variables
pub fn getIntegerVariableCount(self: *const Problem) usize {
    return @intCast(glpk.c.glp_get_num_int(self.ptr));
}

/// Get the number of binary variables
pub fn getBinaryVariableCount(self: *const Problem) usize {
    return @intCast(glpk.c.glp_get_num_bin(self.ptr));
}

/// Get MIP problem class
pub fn getMIPClass(self: *const Problem) MIPClass {
    const n_int = self.getIntegerVariableCount();
    const n_bin = self.getBinaryVariableCount();
    const n_cols = self.getColumnCount();
    
    if (n_int == 0 and n_bin == 0) {
        return .pure_lp;
    } else if (n_int + n_bin == n_cols) {
        if (n_bin == n_cols) {
            return .pure_binary;
        } else {
            return .pure_integer;
        }
    } else {
        return .mixed_integer;
    }
}

pub const MIPClass = enum {
    pure_lp,       // No integer variables
    pure_binary,   // All variables binary
    pure_integer,  // All variables integer
    mixed_integer, // Mix of continuous and integer
};
```

### Special MIP Structures
```zig
/// Set up Special Ordered Set of type 1 (SOS1)
/// At most one variable in the set can be non-zero
pub fn addSOS1(self: *Problem, variables: []const usize, weights: []const f64) !void {
    // Note: GLPK doesn't directly support SOS, may need workaround
    // Could be implemented using binary auxiliary variables
    return error.NotImplemented;
}

/// Set up Special Ordered Set of type 2 (SOS2)
/// At most two adjacent variables in the set can be non-zero
pub fn addSOS2(self: *Problem, variables: []const usize, weights: []const f64) !void {
    // Note: GLPK doesn't directly support SOS, may need workaround
    return error.NotImplemented;
}

/// Add a logical implication constraint (indicator constraint)
/// If binary_var = 1, then constraint is enforced
pub fn addIndicatorConstraint(
    self: *Problem,
    binary_var: usize,
    constraint_row: usize,
    big_m: ?f64,
) !void {
    // Implement using big-M method
    // This is a common MIP modeling technique
    const m = big_m orelse 1e6;
    // Modify constraint bounds based on binary variable
    return error.NotImplemented; // Placeholder
}
```

### MIP-Specific Bounds and Cuts
```zig
/// Set integer feasibility tolerance
pub fn setIntegerTolerance(self: *Problem, tolerance: f64) !void {
    if (tolerance <= 0 or tolerance >= 1) {
        return error.InvalidTolerance;
    }
    // This would be set in MIP solver options
    // Store for later use when solving
}

/// Add a cut (user-defined constraint valid only for integer solutions)
pub fn addCut(self: *Problem, coeffs: []const f64, rhs: f64, sense: CutSense) !usize {
    // Add as a regular constraint but mark as cut
    const row = try self.addRow();
    // Set coefficients and bounds
    // Mark as cut for solver
    return row;
}

pub const CutSense = enum {
    less_equal,
    equal,
    greater_equal,
};
```

### Variable Branching Priority
```zig
/// Set branching priority for integer variable (higher = branch first)
pub fn setColumnBranchingPriority(self: *Problem, col: usize, priority: i32) !void {
    // Note: GLPK may not support branching priorities directly
    // Could store and use in custom branching callback
    return error.NotImplemented;
}

/// Set branching direction preference
pub fn setColumnBranchingDirection(self: *Problem, col: usize, dir: BranchingDirection) !void {
    // Note: GLPK may not support this directly
    return error.NotImplemented;
}

pub const BranchingDirection = enum {
    down_first,  // Branch down (towards 0) first
    up_first,    // Branch up (towards 1) first
    auto,        // Let solver decide
};
```

### MIP Start Solutions
```zig
/// Provide an initial feasible solution for warm starting MIP
pub fn setMIPStart(self: *Problem, cols: []const usize, values: []const f64) !void {
    if (cols.len != values.len) {
        return error.LengthMismatch;
    }
    
    // GLPK uses glp_ios_heur_sol in callback
    // Store solution for use in MIP solver
    // This is more complex and may need solver integration
}

/// Clear MIP start solution
pub fn clearMIPStart(self: *Problem) void {
    // Clear stored MIP start
}
```

## Implementation Notes
- Binary variables automatically get [0,1] bounds
- Integer variables can have any bounds
- MIP problems require different solvers than pure LP
- Some advanced MIP features may not be directly supported by GLPK
- Consider which features are essential vs nice-to-have

## Testing Requirements
- Test setting variable types
- Test mixed problems (continuous + integer)
- Test pure binary problems
- Test pure integer problems
- Test variable count methods
- Test MIP class detection
- Verify binary variables get correct bounds
- Test error cases (invalid indices)

## Dependencies
- [#006](006_issue.md) - Problem struct base
- [#008](008_issue.md) - Column management methods

## Acceptance Criteria
- [ ] Variable kind setting/getting works
- [ ] Batch variable type operations work
- [ ] MIP problem detection works
- [ ] Variable counting methods accurate
- [ ] MIP class identification correct
- [ ] Binary variables auto-bounded to [0,1]
- [ ] Tests cover all variable types
- [ ] Documentation explains MIP concepts
- [ ] Error handling for invalid operations

## Status
🟡 Not Started