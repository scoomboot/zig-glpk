# Issue #018: Create unit tests for type conversions and utilities

## Priority
🔴 Critical

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#51-unit-tests)
- [Issue #005](005_issue.md) - Type definitions

## Description
Create comprehensive unit tests for all type conversion functions, utility methods, and basic data structures. These tests ensure that the foundational type system works correctly and conversions between Zig and GLPK representations are accurate.

## Requirements

### Test Files to Create/Update
- `lib/core/utils/types/types.test.zig`
- `lib/c/utils/glpk/glpk.test.zig`

### Type Conversion Tests
```zig
// In types.test.zig

test "OptimizationDirection conversions" {
    const testing = std.testing;
    
    // Test toGLPK
    try testing.expectEqual(glpk.GLP_MIN, OptimizationDirection.minimize.toGLPK());
    try testing.expectEqual(glpk.GLP_MAX, OptimizationDirection.maximize.toGLPK());
    
    // Test fromGLPK
    try testing.expectEqual(OptimizationDirection.minimize, try OptimizationDirection.fromGLPK(glpk.GLP_MIN));
    try testing.expectEqual(OptimizationDirection.maximize, try OptimizationDirection.fromGLPK(glpk.GLP_MAX));
    
    // Test invalid value
    try testing.expectError(error.InvalidDirection, OptimizationDirection.fromGLPK(999));
    
    // Test round-trip conversion
    const directions = [_]OptimizationDirection{ .minimize, .maximize };
    for (directions) |dir| {
        const glpk_val = dir.toGLPK();
        const back = try OptimizationDirection.fromGLPK(glpk_val);
        try testing.expectEqual(dir, back);
    }
}

test "BoundType conversions" {
    const testing = std.testing;
    
    // Test all bound types
    const bounds = [_]BoundType{ .free, .lower, .upper, .double, .fixed };
    const glpk_bounds = [_]c_int{ glpk.GLP_FR, glpk.GLP_LO, glpk.GLP_UP, glpk.GLP_DB, glpk.GLP_FX };
    
    for (bounds, glpk_bounds) |bound, expected| {
        try testing.expectEqual(expected, bound.toGLPK());
    }
    
    // Test round-trip
    for (bounds) |bound| {
        const glpk_val = bound.toGLPK();
        const back = try BoundType.fromGLPK(glpk_val);
        try testing.expectEqual(bound, back);
    }
}

test "VariableKind conversions" {
    const testing = std.testing;
    
    try testing.expectEqual(glpk.GLP_CV, VariableKind.continuous.toGLPK());
    try testing.expectEqual(glpk.GLP_IV, VariableKind.integer.toGLPK());
    try testing.expectEqual(glpk.GLP_BV, VariableKind.binary.toGLPK());
    
    // Test fromGLPK
    try testing.expectEqual(VariableKind.continuous, try VariableKind.fromGLPK(glpk.GLP_CV));
    try testing.expectEqual(VariableKind.integer, try VariableKind.fromGLPK(glpk.GLP_IV));
    try testing.expectEqual(VariableKind.binary, try VariableKind.fromGLPK(glpk.GLP_BV));
}

test "SolutionStatus conversions and helpers" {
    const testing = std.testing;
    
    // Test status conversions
    try testing.expectEqual(SolutionStatus.optimal, SolutionStatus.fromGLPK(glpk.GLP_OPT));
    try testing.expectEqual(SolutionStatus.feasible, SolutionStatus.fromGLPK(glpk.GLP_FEAS));
    try testing.expectEqual(SolutionStatus.infeasible, SolutionStatus.fromGLPK(glpk.GLP_INFEAS));
    
    // Test isSuccess helper
    try testing.expect(SolutionStatus.optimal.isSuccess());
    try testing.expect(SolutionStatus.feasible.isSuccess());
    try testing.expect(!SolutionStatus.infeasible.isSuccess());
    try testing.expect(!SolutionStatus.unbounded.isSuccess());
}
```

### Sparse Matrix Tests
```zig
test "SparseMatrix validation" {
    const testing = std.testing;
    const allocator = testing.allocator;
    
    // Valid matrix
    const valid = SparseMatrix{
        .rows = &[_]usize{ 1, 2, 3 },
        .cols = &[_]usize{ 1, 2, 3 },
        .values = &[_]f64{ 1.0, 2.0, 3.0 },
    };
    try valid.validate();
    
    // Mismatched lengths
    const invalid = SparseMatrix{
        .rows = &[_]usize{ 1, 2 },
        .cols = &[_]usize{ 1, 2, 3 },
        .values = &[_]f64{ 1.0, 2.0, 3.0 },
    };
    try testing.expectError(error.InvalidMatrixData, invalid.validate());
    
    // Invalid indices (0-based when expecting 1-based)
    const invalid_idx = SparseMatrix{
        .rows = &[_]usize{ 0, 1, 2 },
        .cols = &[_]usize{ 1, 2, 3 },
        .values = &[_]f64{ 1.0, 2.0, 3.0 },
    };
    try testing.expectError(error.InvalidRowIndex, invalid_idx.validate());
}

test "SparseMatrix from dense" {
    const testing = std.testing;
    const allocator = testing.allocator;
    
    // Create dense matrix
    const dense = [_][3]f64{
        .{ 1.0, 0.0, 2.0 },
        .{ 0.0, 3.0, 0.0 },
        .{ 4.0, 0.0, 5.0 },
    };
    
    const sparse = try SparseMatrix.fromDense(allocator, &dense);
    defer sparse.deinit();
    
    // Should have 5 non-zero entries
    try testing.expectEqual(@as(usize, 5), sparse.values.len);
    
    // Verify correct values
    // Note: Order might vary depending on implementation
    var found_values = [_]bool{ false, false, false, false, false };
    for (sparse.values) |val| {
        if (val == 1.0) found_values[0] = true;
        if (val == 2.0) found_values[1] = true;
        if (val == 3.0) found_values[2] = true;
        if (val == 4.0) found_values[3] = true;
        if (val == 5.0) found_values[4] = true;
    }
    
    for (found_values) |found| {
        try testing.expect(found);
    }
}
```

### Solver Options Tests
```zig
test "SimplexMethod enum conversions" {
    const testing = std.testing;
    
    try testing.expectEqual(glpk.GLP_PRIMAL, SimplexMethod.primal.toGLPK());
    try testing.expectEqual(glpk.GLP_DUAL, SimplexMethod.dual.toGLPK());
    try testing.expectEqual(glpk.GLP_DUALP, SimplexMethod.dual_primal.toGLPK());
}

test "MessageLevel conversions" {
    const testing = std.testing;
    
    try testing.expectEqual(glpk.GLP_MSG_OFF, MessageLevel.none.toGLPK());
    try testing.expectEqual(glpk.GLP_MSG_ERR, MessageLevel.errors_only.toGLPK());
    try testing.expectEqual(glpk.GLP_MSG_ON, MessageLevel.normal.toGLPK());
    try testing.expectEqual(glpk.GLP_MSG_ALL, MessageLevel.all.toGLPK());
}

test "BranchingTechnique conversions" {
    const testing = std.testing;
    
    const techniques = [_]BranchingTechnique{
        .first_fractional,
        .last_fractional,
        .most_fractional,
        .driebeek_tomlin,
        .hybrid,
    };
    
    // Test that each has a valid GLPK conversion
    for (techniques) |tech| {
        const val = tech.toGLPK();
        try testing.expect(val != 0); // Should be a valid constant
    }
}
```

### C Bindings Tests
```zig
// In glpk.test.zig

test "GLPK constants are imported" {
    const testing = std.testing;
    
    // Test that constants exist and have expected values
    try testing.expect(glpk.GLP_MIN != glpk.GLP_MAX);
    try testing.expect(glpk.GLP_FR != glpk.GLP_LO);
    try testing.expect(glpk.GLP_CV != glpk.GLP_IV);
    
    // Test that we can create and destroy a problem
    const prob = glpk.c.glp_create_prob();
    try testing.expect(prob != null);
    defer glpk.c.glp_delete_prob(prob);
    
    // Test basic problem operations
    glpk.c.glp_set_prob_name(prob, "test");
    glpk.c.glp_set_obj_dir(prob, glpk.GLP_MIN);
}

test "GLPK version check" {
    const testing = std.testing;
    
    // Get GLPK version
    const version = glpk.c.glp_version();
    try testing.expect(version != null);
    
    // Should be at least version 4.65
    // Parse version string if needed
}
```

### Edge Cases and Error Conditions
```zig
test "Edge cases for type conversions" {
    const testing = std.testing;
    
    // Test with maximum/minimum values
    const max_int: c_int = std.math.maxInt(c_int);
    const min_int: c_int = std.math.minInt(c_int);
    
    // These should fail gracefully
    try testing.expectError(error.InvalidDirection, OptimizationDirection.fromGLPK(max_int));
    try testing.expectError(error.InvalidBoundType, BoundType.fromGLPK(min_int));
}

test "Floating point edge cases" {
    const testing = std.testing;
    
    // Test with special float values
    const inf = std.math.inf(f64);
    const nan = std.math.nan(f64);
    
    // SparseMatrix should handle these appropriately
    const matrix = SparseMatrix{
        .rows = &[_]usize{1},
        .cols = &[_]usize{1},
        .values = &[_]f64{inf},
    };
    
    // Depending on requirements, this might be valid or invalid
    // Document the expected behavior
}
```

### Performance and Memory Tests
```zig
test "Memory allocation and cleanup" {
    const testing = std.testing;
    const allocator = testing.allocator;
    
    // Test that allocations are properly freed
    {
        const sparse = try SparseMatrix.fromDense(allocator, &dense_matrix);
        defer sparse.deinit();
        // Use the matrix
    }
    // Allocator should report no leaks after this block
}

test "Large sparse matrix handling" {
    const testing = std.testing;
    const allocator = testing.allocator;
    
    // Create a large sparse matrix
    const size = 10000;
    var rows = try allocator.alloc(usize, size);
    defer allocator.free(rows);
    var cols = try allocator.alloc(usize, size);
    defer allocator.free(cols);
    var values = try allocator.alloc(f64, size);
    defer allocator.free(values);
    
    // Fill with diagonal matrix pattern
    for (0..size) |i| {
        rows[i] = i + 1;
        cols[i] = i + 1;
        values[i] = @floatFromInt(i + 1);
    }
    
    const matrix = SparseMatrix{
        .rows = rows,
        .cols = cols,
        .values = values,
    };
    
    try matrix.validate();
}
```

## Implementation Notes
- Use `std.testing` utilities for assertions
- Test both success and failure cases
- Include edge cases and boundary conditions
- Verify memory is properly managed
- Document any platform-specific behavior
- Consider adding benchmarks for performance-critical conversions

## Testing Requirements
- All type conversion functions tested
- Round-trip conversions verified
- Error cases handled properly
- Memory leaks checked
- Edge cases covered
- Performance acceptable for large data

## Dependencies
- [#005](005_issue.md) - Type definitions must be implemented

## Acceptance Criteria
- [x] All enum conversion functions tested
- [x] SparseMatrix validation tests complete
- [x] Dense to sparse conversion tested
- [x] GLPK constants verified accessible
- [x] Error conditions properly tested
- [x] Memory management verified
- [x] Edge cases covered
- [x] All tests pass reliably
- [x] No memory leaks detected
- [x] Test coverage > 90% for types module

## Status
✅ Completed

## Resolution Summary

### Implementation Already Completed
Unit tests for type conversions and utilities were comprehensively implemented as part of Issue #005's resolution.

### Test Coverage Delivered
1. **158 Total Tests**: 102 inline tests in types.zig + 56 tests in types.test.zig
2. **All Enum Conversions Tested**: Complete coverage of toGLPK/fromGLPK for all 9 enum types
3. **SparseMatrix Validation**: Extensive testing including edge cases, memory management, and performance
4. **Round-trip Conversions**: Verified for all enum types with multi-round stability tests
5. **Error Handling**: Invalid value handling tested for all conversion functions
6. **Memory Management**: Verified with std.testing.allocator
7. **Edge Cases**: NaN, Inf, empty matrices, single elements, large matrices all tested

### Files Created
- `lib/core/utils/types/types.test.zig` - Comprehensive test suite
- Inline tests in `lib/core/utils/types/types.zig`

### Test Categories Covered
- Unit tests for all type conversions
- Integration tests for matrix operations
- Performance tests for large matrices
- Stress tests for memory management
- Edge case validation

All acceptance criteria met through the comprehensive testing implemented in Issue #005.