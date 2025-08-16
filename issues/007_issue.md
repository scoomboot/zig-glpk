# Issue #007: Implement row (constraint) management methods

## Priority
🟡 Medium

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#23-problem-structure)
- [Issue #006](006_issue.md) - Problem struct

## Description
Extend the Problem struct with methods for managing rows (constraints) in the optimization problem. This includes adding rows, setting their properties, bounds, and coefficients.

## Requirements

### Methods to Add to Problem Struct

#### Row Addition
```zig
/// Add rows (constraints) to the problem
pub fn addRows(self: *Problem, count: usize) !void {
    const first_row = glpk.c.glp_add_rows(self.ptr, @intCast(count));
    if (first_row == 0) return error.RowAdditionFailed;
}

/// Add a single row and return its index
pub fn addRow(self: *Problem) !usize {
    const row_idx = glpk.c.glp_add_rows(self.ptr, 1);
    if (row_idx == 0) return error.RowAdditionFailed;
    return @intCast(row_idx);
}
```

#### Row Configuration
```zig
/// Set the name of a row
pub fn setRowName(self: *Problem, row: usize, name: []const u8) !void {
    // Convert to C string
    // Call glp_set_row_name
    // Handle string allocation
}

/// Set row bounds (constraint limits)
pub fn setRowBounds(self: *Problem, row: usize, bound_type: types.BoundType, lb: f64, ub: f64) !void {
    // Validate row index
    // Map bound_type to GLPK constants
    // Call glp_set_row_bnds
}

/// Convenience methods for common bound types
pub fn setRowLowerBound(self: *Problem, row: usize, lb: f64) !void {
    self.setRowBounds(row, .lower, lb, 0);
}

pub fn setRowUpperBound(self: *Problem, row: usize, ub: f64) !void {
    self.setRowBounds(row, .upper, 0, ub);
}

pub fn setRowRangeBounds(self: *Problem, row: usize, lb: f64, ub: f64) !void {
    self.setRowBounds(row, .double, lb, ub);
}

pub fn setRowFixed(self: *Problem, row: usize, value: f64) !void {
    self.setRowBounds(row, .fixed, value, value);
}
```

#### Row Coefficients
```zig
/// Set coefficients for a row (sparse format)
pub fn setRowCoefficients(self: *Problem, row: usize, cols: []const usize, values: []const f64) !void {
    if (cols.len != values.len) return error.LengthMismatch;
    if (cols.len == 0) return;
    
    // Convert to GLPK's 1-based indexing
    // Call glp_set_mat_row
}

/// Set a single coefficient in a row
pub fn setRowCoefficient(self: *Problem, row: usize, col: usize, value: f64) !void {
    // Set single matrix element
    // Use glp_set_mat_row or glp_set_aij
}
```

#### Row Retrieval
```zig
/// Get row name
pub fn getRowName(self: *const Problem, row: usize) ?[]const u8 {
    // Call glp_get_row_name
    // Return null if no name set
}

/// Get row bounds
pub fn getRowBounds(self: *const Problem, row: usize) !RowBounds {
    // Get type and bounds from GLPK
    // Return structured data
}

/// Get row coefficients (sparse format)
pub fn getRowCoefficients(self: *const Problem, row: usize, allocator: std.mem.Allocator) !SparseVector {
    // Get row length with glp_get_mat_row
    // Allocate arrays
    // Fill with coefficients
}
```

#### Row Deletion
```zig
/// Delete rows from the problem
pub fn deleteRows(self: *Problem, rows: []const usize) !void {
    // Convert to GLPK's format
    // Call glp_del_rows
}

/// Delete a single row
pub fn deleteRow(self: *Problem, row: usize) !void {
    const rows = [_]usize{row};
    try self.deleteRows(&rows);
}
```

### Data Structures
```zig
pub const RowBounds = struct {
    type: types.BoundType,
    lower: f64,
    upper: f64,
};

pub const SparseVector = struct {
    indices: []usize,
    values: []f64,
    allocator: std.mem.Allocator,
    
    pub fn deinit(self: *SparseVector) void {
        self.allocator.free(self.indices);
        self.allocator.free(self.values);
    }
};
```

## Implementation Notes
- GLPK uses 1-based indexing for rows and columns
- Need to convert between 0-based (Zig) and 1-based (GLPK) indices
- Row operations may invalidate existing row indices
- Consider caching row names to avoid repeated allocations
- Validate bounds (e.g., lb <= ub for double bounds)

## Testing Requirements
- Test adding single and multiple rows
- Test setting various bound types
- Test coefficient setting (single and bulk)
- Test row name management
- Test row deletion
- Test bounds validation
- Test index boundary conditions
- Verify memory management

## Dependencies
- [#006](006_issue.md) - Problem struct must be implemented

## Acceptance Criteria
- [ ] Row addition methods implemented
- [ ] Row naming functionality works
- [ ] All bound types can be set
- [ ] Coefficient setting works (sparse format)
- [ ] Row retrieval methods work
- [ ] Row deletion implemented
- [ ] Index conversion handled correctly
- [ ] Tests cover all row operations
- [ ] Documentation for all methods
- [ ] No memory leaks

## Status
🟡 Not Started