# Issue #008: Implement column (variable) management methods

## Priority
🟡 Medium

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#23-problem-structure)
- [Issue #006](006_issue.md) - Problem struct

## Description
Extend the Problem struct with methods for managing columns (variables) in the optimization problem. This includes adding variables, setting their properties, bounds, objective coefficients, and variable types for MIP problems.

## Requirements

### Methods to Add to Problem Struct

#### Column Addition
```zig
/// Add columns (variables) to the problem
pub fn addColumns(self: *Problem, count: usize) !void {
    const first_col = glpk.c.glp_add_cols(self.ptr, @intCast(count));
    if (first_col == 0) return error.ColumnAdditionFailed;
}

/// Add a single column and return its index
pub fn addColumn(self: *Problem) !usize {
    const col_idx = glpk.c.glp_add_cols(self.ptr, 1);
    if (col_idx == 0) return error.ColumnAdditionFailed;
    return @intCast(col_idx);
}
```

#### Column Configuration
```zig
/// Set the name of a column
pub fn setColumnName(self: *Problem, col: usize, name: []const u8) !void {
    // Convert to C string
    // Call glp_set_col_name
    // Handle string allocation
}

/// Set column bounds (variable limits)
pub fn setColumnBounds(self: *Problem, col: usize, bound_type: types.BoundType, lb: f64, ub: f64) !void {
    // Validate column index
    // Map bound_type to GLPK constants
    // Call glp_set_col_bnds
}

/// Convenience methods for common bound types
pub fn setColumnLowerBound(self: *Problem, col: usize, lb: f64) !void {
    self.setColumnBounds(col, .lower, lb, 0);
}

pub fn setColumnUpperBound(self: *Problem, col: usize, ub: f64) !void {
    self.setColumnBounds(col, .upper, 0, ub);
}

pub fn setColumnRangeBounds(self: *Problem, col: usize, lb: f64, ub: f64) !void {
    self.setColumnBounds(col, .double, lb, ub);
}

pub fn setColumnFixed(self: *Problem, col: usize, value: f64) !void {
    self.setColumnBounds(col, .fixed, value, value);
}

pub fn setColumnFree(self: *Problem, col: usize) !void {
    self.setColumnBounds(col, .free, 0, 0);
}
```

#### Objective Coefficients
```zig
/// Set objective coefficient for a column
pub fn setObjectiveCoefficient(self: *Problem, col: usize, coef: f64) void {
    glpk.c.glp_set_obj_coef(self.ptr, @intCast(col), coef);
}

/// Set multiple objective coefficients at once
pub fn setObjectiveCoefficients(self: *Problem, cols: []const usize, coefs: []const f64) !void {
    if (cols.len != coefs.len) return error.LengthMismatch;
    for (cols, coefs) |col, coef| {
        self.setObjectiveCoefficient(col, coef);
    }
}

/// Get objective coefficient for a column
pub fn getObjectiveCoefficient(self: *const Problem, col: usize) f64 {
    return glpk.c.glp_get_obj_coef(self.ptr, @intCast(col));
}
```

#### Column Coefficients (Matrix Column)
```zig
/// Set coefficients for a column (sparse format)
pub fn setColumnCoefficients(self: *Problem, col: usize, rows: []const usize, values: []const f64) !void {
    if (rows.len != values.len) return error.LengthMismatch;
    if (rows.len == 0) return;
    
    // Convert to GLPK's 1-based indexing
    // Call glp_set_mat_col
}

/// Set a single coefficient in a column
pub fn setColumnCoefficient(self: *Problem, col: usize, row: usize, value: f64) !void {
    // Set single matrix element
    // Use glp_set_mat_col or glp_set_aij
}
```

#### Column Type (for MIP)
```zig
/// Set column kind (continuous, integer, binary)
pub fn setColumnKind(self: *Problem, col: usize, kind: types.VariableKind) !void {
    const glpk_kind = kind.toGLPK();
    glpk.c.glp_set_col_kind(self.ptr, @intCast(col), glpk_kind);
}

/// Convenience methods for variable types
pub fn setColumnContinuous(self: *Problem, col: usize) !void {
    self.setColumnKind(col, .continuous);
}

pub fn setColumnInteger(self: *Problem, col: usize) !void {
    self.setColumnKind(col, .integer);
}

pub fn setColumnBinary(self: *Problem, col: usize) !void {
    self.setColumnKind(col, .binary);
    // Also set bounds to [0, 1]
    try self.setColumnRangeBounds(col, 0, 1);
}
```

#### Column Retrieval
```zig
/// Get column name
pub fn getColumnName(self: *const Problem, col: usize) ?[]const u8 {
    // Call glp_get_col_name
    // Return null if no name set
}

/// Get column bounds
pub fn getColumnBounds(self: *const Problem, col: usize) !ColumnBounds {
    // Get type and bounds from GLPK
    // Return structured data
}

/// Get column coefficients (sparse format)
pub fn getColumnCoefficients(self: *const Problem, col: usize, allocator: std.mem.Allocator) !SparseVector {
    // Get column length with glp_get_mat_col
    // Allocate arrays
    // Fill with coefficients
}

/// Get column kind
pub fn getColumnKind(self: *const Problem, col: usize) types.VariableKind {
    const kind = glpk.c.glp_get_col_kind(self.ptr, @intCast(col));
    return types.VariableKind.fromGLPK(kind);
}
```

#### Column Deletion
```zig
/// Delete columns from the problem
pub fn deleteColumns(self: *Problem, cols: []const usize) !void {
    // Convert to GLPK's format
    // Call glp_del_cols
}

/// Delete a single column
pub fn deleteColumn(self: *Problem, col: usize) !void {
    const cols = [_]usize{col};
    try self.deleteColumns(&cols);
}
```

### Data Structures
```zig
pub const ColumnBounds = struct {
    type: types.BoundType,
    lower: f64,
    upper: f64,
};
```

## Implementation Notes
- GLPK uses 1-based indexing for columns
- Binary variables should automatically set bounds to [0, 1]
- Column operations may invalidate existing column indices
- Consider the interaction between variable type and bounds
- Objective coefficient index 0 is the constant term

## Testing Requirements
- Test adding single and multiple columns
- Test setting various bound types
- Test objective coefficient setting
- Test column coefficient setting
- Test variable type setting (continuous/integer/binary)
- Test column name management
- Test column deletion
- Test retrieval methods
- Verify binary variables have correct bounds

## Dependencies
- [#006](006_issue.md) - Problem struct must be implemented

## Acceptance Criteria
- [x] Column addition methods implemented
- [x] Column naming functionality works
- [x] All bound types can be set
- [x] Objective coefficients can be set/retrieved
- [x] Column coefficients work (sparse format)
- [x] Variable types can be set (MIP support)
- [x] Column deletion implemented
- [x] Binary variables automatically bounded
- [x] Tests cover all column operations
- [x] Documentation for all methods

## Status
✅ Completed

## Solution Summary
Successfully implemented comprehensive column (variable) management methods for the Problem struct, providing a complete API for managing variables in linear programming problems.

### Implementation Details
- **Added to `/lib/core/problem/problem.zig`:**
  - `ColumnBounds` struct with validation
  - Column addition methods (`addColumns`, `addColumn`)
  - Column configuration methods (name, bounds with all convenience methods)
  - Objective coefficient management
  - Column coefficient methods for constraint matrix
  - Variable kind methods for MIP support (continuous, integer, binary)
  - Column retrieval methods
  - Column deletion methods

- **Enhanced `/lib/c/utils/glpk/glpk.zig`:**
  - Added missing GLPK wrapper functions for column operations
  - `getColumnName`, `getColumnType`, `getColumnLowerBound`, `getColumnUpperBound`
  - `getObjectiveCoef`, `getColumnKind`, `getMatrixCol`

### Key Features
- ✅ 0-based indexing in public API (converted to 1-based for GLPK)
- ✅ Binary variables automatically set bounds to [0,1]
- ✅ Memory-safe with proper allocation/deallocation
- ✅ Comprehensive error handling
- ✅ Full MCS compliance with decorative headers and proper indentation
- ✅ Complete test coverage with 30+ column-specific tests
- ✅ All tests passing successfully

### Test Coverage
- Unit tests for all individual methods
- Integration test demonstrating complete column workflow
- Validation tests for bounds and error conditions
- All existing tests continue to pass (214 total tests)