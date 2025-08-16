# Issue #019: Create unit tests for Problem management

## Priority
🔴 Critical

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#51-unit-tests)
- [Issue #006](006_issue.md) - Problem struct
- [Issue #007](007_issue.md) - Row management
- [Issue #008](008_issue.md) - Column management
- [Issue #009](009_issue.md) - Matrix loading

## Description
Create comprehensive unit tests for the Problem struct and all its management methods including creation, configuration, row/column operations, and matrix loading. These tests ensure the core problem management functionality works correctly.

## Requirements

### Test Files to Update
- `lib/core/utils/problem/problem.test.zig`

### Problem Creation and Destruction Tests
```zig
test "Problem creation and cleanup" {
    const testing = std.testing;
    const allocator = testing.allocator;
    
    // Test basic creation
    var problem = try Problem.init(allocator);
    defer problem.deinit();
    
    // Should start with empty problem
    try testing.expectEqual(@as(usize, 0), problem.getRowCount());
    try testing.expectEqual(@as(usize, 0), problem.getColumnCount());
    try testing.expectEqual(@as(usize, 0), problem.getNonZeroCount());
}

test "Problem naming" {
    const testing = std.testing;
    const allocator = testing.allocator;
    
    var problem = try Problem.init(allocator);
    defer problem.deinit();
    
    // Set and verify problem name
    try problem.setName("TestProblem");
    try testing.expectEqualStrings("TestProblem", problem.name.?);
    
    // Set objective name
    try problem.setObjectiveName("MaxProfit");
}

test "Problem configuration" {
    const testing = std.testing;
    const allocator = testing.allocator;
    
    var problem = try Problem.init(allocator);
    defer problem.deinit();
    
    // Test objective direction
    problem.setObjectiveDirection(.maximize);
    // Note: May need a getter to verify
    
    // Test objective constant
    problem.setObjectiveConstant(10.5);
    try testing.expectEqual(@as(f64, 10.5), problem.getObjectiveConstant());
    
    // Test terminal output control
    problem.setTerminalOutput(false);
    problem.setTerminalOutput(true);
}

test "Problem clearing" {
    const testing = std.testing;
    const allocator = testing.allocator;
    
    var problem = try Problem.init(allocator);
    defer problem.deinit();
    
    // Add some rows and columns
    try problem.addRows(5);
    try problem.addColumns(3);
    
    try testing.expectEqual(@as(usize, 5), problem.getRowCount());
    try testing.expectEqual(@as(usize, 3), problem.getColumnCount());
    
    // Clear the problem
    problem.clear();
    
    // Should be empty again
    try testing.expectEqual(@as(usize, 0), problem.getRowCount());
    try testing.expectEqual(@as(usize, 0), problem.getColumnCount());
}
```

### Row Management Tests
```zig
test "Row addition and configuration" {
    const testing = std.testing;
    const allocator = testing.allocator;
    
    var problem = try Problem.init(allocator);
    defer problem.deinit();
    
    // Add multiple rows
    try problem.addRows(3);
    try testing.expectEqual(@as(usize, 3), problem.getRowCount());
    
    // Add single row
    const row_idx = try problem.addRow();
    try testing.expectEqual(@as(usize, 4), row_idx);
    try testing.expectEqual(@as(usize, 4), problem.getRowCount());
    
    // Set row names
    try problem.setRowName(1, "Constraint1");
    try problem.setRowName(2, "Constraint2");
    
    // Set row bounds
    try problem.setRowLowerBound(1, 10.0);
    try problem.setRowUpperBound(2, 20.0);
    try problem.setRowRangeBounds(3, 5.0, 15.0);
    try problem.setRowFixed(4, 7.5);
    
    // Verify bounds
    const bounds1 = try problem.getRowBounds(1);
    try testing.expectEqual(BoundType.lower, bounds1.type);
    try testing.expectEqual(@as(f64, 10.0), bounds1.lower);
    
    const bounds3 = try problem.getRowBounds(3);
    try testing.expectEqual(BoundType.double, bounds3.type);
    try testing.expectEqual(@as(f64, 5.0), bounds3.lower);
    try testing.expectEqual(@as(f64, 15.0), bounds3.upper);
}

test "Row coefficient setting" {
    const testing = std.testing;
    const allocator = testing.allocator;
    
    var problem = try Problem.init(allocator);
    defer problem.deinit();
    
    try problem.addRows(2);
    try problem.addColumns(3);
    
    // Set coefficients for a row
    const cols = [_]usize{ 1, 2, 3 };
    const values = [_]f64{ 1.0, 2.0, 3.0 };
    try problem.setRowCoefficients(1, &cols, &values);
    
    // Set single coefficient
    try problem.setRowCoefficient(2, 2, 4.5);
    
    // Get and verify coefficients
    const sparse_vec = try problem.getRowCoefficients(1, allocator);
    defer sparse_vec.deinit();
    
    try testing.expectEqual(@as(usize, 3), sparse_vec.indices.len);
}

test "Row deletion" {
    const testing = std.testing;
    const allocator = testing.allocator;
    
    var problem = try Problem.init(allocator);
    defer problem.deinit();
    
    try problem.addRows(5);
    
    // Delete single row
    try problem.deleteRow(3);
    try testing.expectEqual(@as(usize, 4), problem.getRowCount());
    
    // Delete multiple rows
    const rows_to_delete = [_]usize{ 1, 2 };
    try problem.deleteRows(&rows_to_delete);
    try testing.expectEqual(@as(usize, 2), problem.getRowCount());
}
```

### Column Management Tests
```zig
test "Column addition and configuration" {
    const testing = std.testing;
    const allocator = testing.allocator;
    
    var problem = try Problem.init(allocator);
    defer problem.deinit();
    
    // Add columns
    try problem.addColumns(4);
    try testing.expectEqual(@as(usize, 4), problem.getColumnCount());
    
    // Set column names
    try problem.setColumnName(1, "x1");
    try problem.setColumnName(2, "x2");
    
    // Set column bounds
    try problem.setColumnLowerBound(1, 0.0);
    try problem.setColumnUpperBound(2, 100.0);
    try problem.setColumnRangeBounds(3, 10.0, 50.0);
    try problem.setColumnFree(4);
    
    // Set objective coefficients
    problem.setObjectiveCoefficient(1, 3.0);
    problem.setObjectiveCoefficient(2, 2.0);
    
    try testing.expectEqual(@as(f64, 3.0), problem.getObjectiveCoefficient(1));
    try testing.expectEqual(@as(f64, 2.0), problem.getObjectiveCoefficient(2));
}

test "Column types for MIP" {
    const testing = std.testing;
    const allocator = testing.allocator;
    
    var problem = try Problem.init(allocator);
    defer problem.deinit();
    
    try problem.addColumns(3);
    
    // Set variable types
    try problem.setColumnContinuous(1);
    try problem.setColumnInteger(2);
    try problem.setColumnBinary(3);
    
    // Verify types
    try testing.expectEqual(VariableKind.continuous, try problem.getColumnKind(1));
    try testing.expectEqual(VariableKind.integer, try problem.getColumnKind(2));
    try testing.expectEqual(VariableKind.binary, try problem.getColumnKind(3));
    
    // Binary should have [0,1] bounds
    const binary_bounds = try problem.getColumnBounds(3);
    try testing.expectEqual(@as(f64, 0.0), binary_bounds.lower);
    try testing.expectEqual(@as(f64, 1.0), binary_bounds.upper);
}
```

### Matrix Loading Tests
```zig
test "Sparse matrix loading" {
    const testing = std.testing;
    const allocator = testing.allocator;
    
    var problem = try Problem.init(allocator);
    defer problem.deinit();
    
    // Create a 3x4 problem
    try problem.addRows(3);
    try problem.addColumns(4);
    
    // Load matrix in sparse format
    const rows = [_]usize{ 1, 1, 2, 2, 3, 3, 3 };
    const cols = [_]usize{ 1, 2, 2, 3, 1, 3, 4 };
    const values = [_]f64{ 2.0, 1.0, 3.0, 1.0, 1.0, 2.0, 1.0 };
    
    const matrix = SparseMatrix{
        .rows = &rows,
        .cols = &cols,
        .values = &values,
    };
    
    try problem.loadMatrix(matrix);
    
    try testing.expectEqual(@as(usize, 7), problem.getNonZeroCount());
}

test "Matrix entry updates" {
    const testing = std.testing;
    const allocator = testing.allocator;
    
    var problem = try Problem.init(allocator);
    defer problem.deinit();
    
    try problem.addRows(2);
    try problem.addColumns(2);
    
    // Set individual entries
    try problem.setMatrixEntry(1, 1, 5.0);
    try problem.setMatrixEntry(1, 2, 3.0);
    try problem.setMatrixEntry(2, 1, 2.0);
    try problem.setMatrixEntry(2, 2, 4.0);
    
    // Verify entries
    try testing.expectEqual(@as(f64, 5.0), problem.getMatrixEntry(1, 1));
    try testing.expectEqual(@as(f64, 3.0), problem.getMatrixEntry(1, 2));
    
    // Test batch updates
    const updates = [_]MatrixUpdate{
        .{ .row = 1, .col = 1, .value = 6.0 },
        .{ .row = 2, .col = 2, .value = 7.0 },
    };
    try problem.updateMatrixEntries(&updates);
    
    try testing.expectEqual(@as(f64, 6.0), problem.getMatrixEntry(1, 1));
    try testing.expectEqual(@as(f64, 7.0), problem.getMatrixEntry(2, 2));
}

test "MatrixBuilder pattern" {
    const testing = std.testing;
    const allocator = testing.allocator;
    
    var builder = MatrixBuilder.init(allocator);
    defer builder.deinit();
    
    // Add entries (should skip zeros)
    try builder.addEntry(1, 1, 1.0);
    try builder.addEntry(1, 2, 0.0); // Should be skipped
    try builder.addEntry(2, 1, 2.0);
    try builder.addEntry(2, 2, 3.0);
    
    const matrix = builder.build();
    
    // Should have 3 non-zero entries
    try testing.expectEqual(@as(usize, 3), matrix.values.len);
}
```

### Error Handling Tests
```zig
test "Invalid index handling" {
    const testing = std.testing;
    const allocator = testing.allocator;
    
    var problem = try Problem.init(allocator);
    defer problem.deinit();
    
    try problem.addRows(2);
    try problem.addColumns(2);
    
    // Test invalid row index
    try testing.expectError(error.InvalidRowIndex, problem.setRowName(0, "Invalid"));
    try testing.expectError(error.InvalidRowIndex, problem.setRowName(3, "Invalid"));
    
    // Test invalid column index
    try testing.expectError(error.InvalidColumnIndex, problem.setColumnName(0, "Invalid"));
    try testing.expectError(error.InvalidColumnIndex, problem.setColumnName(3, "Invalid"));
    
    // Test invalid matrix indices
    try testing.expectError(error.InvalidRowIndex, problem.setMatrixEntry(0, 1, 1.0));
    try testing.expectError(error.InvalidColumnIndex, problem.setMatrixEntry(1, 0, 1.0));
}

test "Length mismatch handling" {
    const testing = std.testing;
    const allocator = testing.allocator;
    
    var problem = try Problem.init(allocator);
    defer problem.deinit();
    
    try problem.addRows(2);
    try problem.addColumns(3);
    
    // Mismatched arrays for row coefficients
    const cols = [_]usize{ 1, 2 };
    const values = [_]f64{ 1.0, 2.0, 3.0 }; // Different length
    
    try testing.expectError(error.LengthMismatch, problem.setRowCoefficients(1, &cols, &values));
}
```

### Integration Tests
```zig
test "Complete LP problem construction" {
    const testing = std.testing;
    const allocator = testing.allocator;
    
    // Build a complete LP problem:
    // Maximize: 3x + 2y
    // Subject to:
    //   2x + y <= 18
    //   2x + 3y <= 42
    //   x, y >= 0
    
    var problem = try Problem.init(allocator);
    defer problem.deinit();
    
    try problem.setName("Simple LP");
    problem.setObjectiveDirection(.maximize);
    
    // Add variables
    try problem.addColumns(2);
    try problem.setColumnName(1, "x");
    try problem.setColumnName(2, "y");
    try problem.setColumnLowerBound(1, 0);
    try problem.setColumnLowerBound(2, 0);
    problem.setObjectiveCoefficient(1, 3);
    problem.setObjectiveCoefficient(2, 2);
    
    // Add constraints
    try problem.addRows(2);
    try problem.setRowName(1, "Resource1");
    try problem.setRowName(2, "Resource2");
    try problem.setRowUpperBound(1, 18);
    try problem.setRowUpperBound(2, 42);
    
    // Set constraint coefficients
    const row1_cols = [_]usize{ 1, 2 };
    const row1_vals = [_]f64{ 2, 1 };
    try problem.setRowCoefficients(1, &row1_cols, &row1_vals);
    
    const row2_cols = [_]usize{ 1, 2 };
    const row2_vals = [_]f64{ 2, 3 };
    try problem.setRowCoefficients(2, &row2_cols, &row2_vals);
    
    // Verify problem structure
    try testing.expectEqual(@as(usize, 2), problem.getRowCount());
    try testing.expectEqual(@as(usize, 2), problem.getColumnCount());
    try testing.expectEqual(@as(usize, 4), problem.getNonZeroCount());
}
```

## Implementation Notes
- Test all public methods of Problem struct
- Include both success and failure cases
- Test index conversion (0-based vs 1-based)
- Verify memory management
- Test realistic problem construction patterns

## Testing Requirements
- Problem lifecycle (init/deinit) tested
- All row operations tested
- All column operations tested
- Matrix loading tested
- Error conditions handled
- Memory leaks checked
- Integration scenarios tested

## Dependencies
- [#006](006_issue.md) - Problem struct
- [#007](007_issue.md) - Row management
- [#008](008_issue.md) - Column management
- [#009](009_issue.md) - Matrix loading

## Acceptance Criteria
- [ ] Problem creation/destruction tested
- [ ] Configuration methods tested
- [ ] Row management fully tested
- [ ] Column management fully tested
- [ ] Matrix operations tested
- [ ] MIP extensions tested
- [ ] Error handling verified
- [ ] No memory leaks
- [ ] Integration tests pass
- [ ] Test coverage > 90% for problem module

## Status
🔴 Not Started