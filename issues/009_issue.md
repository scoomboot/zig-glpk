# Issue #009: Implement sparse matrix loading

## Priority
🟡 Medium

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#23-problem-structure)
- [Issue #006](006_issue.md) - Problem struct
- [Issue #007](007_issue.md) - Row management
- [Issue #008](008_issue.md) - Column management

## Description
Implement efficient methods for loading the constraint matrix in sparse format. This is critical for handling large-scale optimization problems where the constraint matrix is mostly zeros.

## Requirements

### Core Matrix Loading Method
```zig
/// Load the entire constraint matrix in sparse triplet format
pub fn loadMatrix(self: *Problem, data: types.SparseMatrix) !void {
    // Validate matrix dimensions
    if (data.rows.len != data.cols.len or data.rows.len != data.values.len) {
        return error.InvalidMatrixData;
    }
    
    // Check bounds
    const max_row = self.getRowCount();
    const max_col = self.getColumnCount();
    for (data.rows) |row| {
        if (row == 0 or row > max_row) return error.InvalidRowIndex;
    }
    for (data.cols) |col| {
        if (col == 0 or col > max_col) return error.InvalidColumnIndex;
    }
    
    // Convert to GLPK format (1-based indexing)
    // Allocate temporary arrays if needed
    // Call glp_load_matrix
}
```

### Alternative Loading Methods
```zig
/// Load matrix from coordinate (COO) format
pub fn loadMatrixCOO(self: *Problem, rows: []const usize, cols: []const usize, values: []const f64) !void {
    const matrix = types.SparseMatrix{
        .rows = rows,
        .cols = cols,
        .values = values,
    };
    try self.loadMatrix(matrix);
}

/// Load matrix incrementally (useful for building problems programmatically)
pub fn setMatrixEntry(self: *Problem, row: usize, col: usize, value: f64) !void {
    // Validate indices
    if (row == 0 or row > self.getRowCount()) return error.InvalidRowIndex;
    if (col == 0 or col > self.getColumnCount()) return error.InvalidColumnIndex;
    
    // Set single matrix element
    glpk.c.glp_set_aij(self.ptr, @intCast(row), @intCast(col), value);
}

/// Clear all matrix entries (keep rows and columns)
pub fn clearMatrix(self: *Problem) void {
    // Load empty matrix
    glpk.c.glp_load_matrix(self.ptr, 0, null, null, null);
}
```

### Batch Operations
```zig
/// Efficient batch update of matrix entries
pub fn updateMatrixEntries(self: *Problem, updates: []const MatrixUpdate) !void {
    for (updates) |update| {
        try self.setMatrixEntry(update.row, update.col, update.value);
    }
}

pub const MatrixUpdate = struct {
    row: usize,
    col: usize,
    value: f64,
};
```

### Matrix Building Helpers
```zig
/// Builder pattern for constructing sparse matrices
pub const MatrixBuilder = struct {
    rows: std.ArrayList(usize),
    cols: std.ArrayList(usize),
    values: std.ArrayList(f64),
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) MatrixBuilder {
        return .{
            .rows = std.ArrayList(usize).init(allocator),
            .cols = std.ArrayList(usize).init(allocator),
            .values = std.ArrayList(f64).init(allocator),
            .allocator = allocator,
        };
    }
    
    pub fn deinit(self: *MatrixBuilder) void {
        self.rows.deinit();
        self.cols.deinit();
        self.values.deinit();
    }
    
    pub fn addEntry(self: *MatrixBuilder, row: usize, col: usize, value: f64) !void {
        if (value == 0) return; // Skip zeros
        try self.rows.append(row);
        try self.cols.append(col);
        try self.values.append(value);
    }
    
    pub fn build(self: *MatrixBuilder) types.SparseMatrix {
        return .{
            .rows = self.rows.items,
            .cols = self.cols.items,
            .values = self.values.items,
        };
    }
};
```

### Matrix Retrieval
```zig
/// Get the entire constraint matrix in sparse format
pub fn getMatrix(self: *const Problem, allocator: std.mem.Allocator) !types.SparseMatrix {
    const nnz = self.getNonZeroCount();
    if (nnz == 0) {
        return types.SparseMatrix{
            .rows = &[_]usize{},
            .cols = &[_]usize{},
            .values = &[_]f64{},
        };
    }
    
    // Allocate arrays
    var rows = try allocator.alloc(usize, nnz);
    var cols = try allocator.alloc(usize, nnz);
    var values = try allocator.alloc(f64, nnz);
    
    // Iterate through matrix and collect non-zeros
    // Note: GLPK doesn't have a direct "get all matrix" function
    // May need to iterate through rows or columns
}

/// Get a specific matrix entry
pub fn getMatrixEntry(self: *const Problem, row: usize, col: usize) f64 {
    return glpk.c.glp_get_aij(self.ptr, @intCast(row), @intCast(col));
}
```

### Matrix Analysis
```zig
/// Compute matrix statistics
pub fn getMatrixStats(self: *const Problem) MatrixStats {
    const rows = self.getRowCount();
    const cols = self.getColumnCount();
    const nnz = self.getNonZeroCount();
    const total_entries = rows * cols;
    
    return .{
        .rows = rows,
        .columns = cols,
        .non_zeros = nnz,
        .density = if (total_entries > 0) 
            @as(f64, @floatFromInt(nnz)) / @as(f64, @floatFromInt(total_entries))
            else 0.0,
    };
}

pub const MatrixStats = struct {
    rows: usize,
    columns: usize,
    non_zeros: usize,
    density: f64, // Fraction of non-zero entries
};
```

## Implementation Notes
- GLPK uses 1-based indexing for matrix entries
- The constraint matrix excludes the objective function coefficients
- Zero values should typically be omitted from sparse representation
- Loading a new matrix replaces the existing one entirely
- Consider memory efficiency for large matrices
- GLPK stores the matrix in compressed format internally

## Testing Requirements
- Test loading small and large sparse matrices
- Test matrix with all zero entries
- Test dense matrix loading
- Test incremental matrix building
- Test matrix retrieval
- Test index validation (bounds checking)
- Test matrix statistics computation
- Test memory management with large matrices
- Verify 0-based to 1-based index conversion

## Dependencies
- [#006](006_issue.md) - Problem struct must be implemented
- [#007](007_issue.md) - Rows must exist before matrix loading
- [#008](008_issue.md) - Columns must exist before matrix loading

## Acceptance Criteria
- [ ] Basic sparse matrix loading works
- [ ] COO format loading implemented
- [ ] Single entry updates work
- [ ] Matrix builder pattern implemented
- [ ] Matrix retrieval methods work
- [ ] Matrix statistics computed correctly
- [ ] Index validation prevents errors
- [ ] Zero entries handled efficiently
- [ ] Tests cover various matrix patterns
- [ ] Documentation explains sparse format
- [ ] Memory efficient for large matrices

## Status
🟡 Not Started