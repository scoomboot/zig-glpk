// types.test.zig — Comprehensive test suite for types module
//
// repo   : https://github.com/scoomboot/zig-glpk
// docs   : https://scoomboot.github.io/zig-glpk/lib/core/utils/types
// author : https://github.com/scoomboot
//
// Vibe coded by Scoom.

// ╔══════════════════════════════════════ PACK ══════════════════════════════════════╗

    const std = @import("std");
    const testing = std.testing;
    const types = @import("./types.zig");

// ╚══════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ TEST ══════════════════════════════════════╗

    // ┌──────────────────────────── Boundary Value Tests ────────────────────────────┐

        test "integration: OptimizationDirection: handles all valid GLPK constants" {
            // Test that all known GLPK constants convert correctly
            const valid_values = [_]struct { glpk: c_int, expected: types.OptimizationDirection }{
                .{ .glpk = 1, .expected = .minimize },
                .{ .glpk = 2, .expected = .maximize },
            };
            
            for (valid_values) |test_case| {
                const result = try types.OptimizationDirection.fromGLPK(test_case.glpk);
                try testing.expectEqual(test_case.expected, result);
            }
        }

        test "integration: BoundType: handles boundary GLPK values" {
            // Test edge cases with minimum and maximum valid constants
            const edge_cases = [_]c_int{ 1, 2, 3, 4, 5 }; // GLP_FR to GLP_FX
            
            for (edge_cases) |val| {
                const bound_type = try types.BoundType.fromGLPK(val);
                const back = bound_type.toGLPK();
                try testing.expectEqual(val, back);
            }
        }

        test "stress: VariableKind: handles large invalid values" {
            // Test with various invalid values including large numbers
            const invalid_values = [_]c_int{ 
                -1, 0, 4, 100, 1000, 
                std.math.maxInt(c_int), 
                std.math.minInt(c_int) 
            };
            
            for (invalid_values) |val| {
                const result = types.VariableKind.fromGLPK(val);
                try testing.expectError(error.InvalidVariableKind, result);
            }
        }

    // └──────────────────────────────────────────────────────────────────────────────┘

    // ┌──────────────────────────── Round-Trip Conversion Tests ────────────────────────────┐

        test "integration: SolutionStatus: multi-round-trip conversion stability" {
            // Test that multiple round trips maintain value integrity
            const initial = types.SolutionStatus.optimal;
            var current = initial;
            
            // Perform 10 round trips
            for (0..10) |_| {
                const glpk_val = current.toGLPK();
                current = try types.SolutionStatus.fromGLPK(glpk_val);
            }
            
            try testing.expectEqual(initial, current);
        }

        test "integration: SimplexMethod: all variants round-trip correctly" {
            // Comprehensive round-trip test for all enum values
            inline for (std.meta.fields(types.SimplexMethod)) |field| {
                const value = @field(types.SimplexMethod, field.name);
                const glpk = value.toGLPK();
                const back = try types.SimplexMethod.fromGLPK(glpk);
                try testing.expectEqual(value, back);
            }
        }

        test "integration: PricingRule: validates hardcoded constants" {
            // Ensure hardcoded hex values are correct
            try testing.expectEqual(@as(c_int, 0x11), types.PricingRule.standard.toGLPK());
            try testing.expectEqual(@as(c_int, 0x22), types.PricingRule.steepest_edge.toGLPK());
            
            // Test round-trip with these specific values
            const standard_glpk = types.PricingRule.standard.toGLPK();
            try testing.expectEqual(types.PricingRule.standard, try types.PricingRule.fromGLPK(standard_glpk));
            
            const steepest_glpk = types.PricingRule.steepest_edge.toGLPK();
            try testing.expectEqual(types.PricingRule.steepest_edge, try types.PricingRule.fromGLPK(steepest_glpk));
        }

    // └──────────────────────────────────────────────────────────────────────────────┘

    // ┌──────────────────────────── Invalid Value Handling ────────────────────────────┐

        test "stress: RatioTest: exhaustive invalid value testing" {
            // Test that only 0x11 and 0x22 are valid
            for (0..256) |i| {
                const val = @as(c_int, @intCast(i));
                if (val == 0x11 or val == 0x22) {
                    // Should succeed
                    _ = try types.RatioTest.fromGLPK(val);
                } else {
                    // Should fail
                    try testing.expectError(error.InvalidRatioTest, types.RatioTest.fromGLPK(val));
                }
            }
        }

        test "integration: BranchingRule: sequential value validation" {
            // Test that only values 1-4 are valid
            for (0..10) |i| {
                const val = @as(c_int, @intCast(i));
                if (val >= 1 and val <= 4) {
                    _ = try types.BranchingRule.fromGLPK(val);
                } else {
                    try testing.expectError(error.InvalidBranchingRule, types.BranchingRule.fromGLPK(val));
                }
            }
        }

        test "integration: BacktrackingRule: negative value handling" {
            // Test negative values which should all be invalid
            const negative_values = [_]c_int{ -1, -10, -100, -1000 };
            
            for (negative_values) |val| {
                try testing.expectError(error.InvalidBacktrackingRule, types.BacktrackingRule.fromGLPK(val));
            }
        }

    // └──────────────────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ TEST ══════════════════════════════════════╗

    // ┌──────────────────────────── Validation Edge Cases ────────────────────────────┐

        test "unit: SparseMatrix: empty matrix is valid" {
            const matrix = types.SparseMatrix{
                .rows = &[_]i32{},
                .cols = &[_]i32{},
                .values = &[_]f64{},
            };
            try matrix.validate();
        }

        test "unit: SparseMatrix: single element matrix" {
            const matrix = types.SparseMatrix{
                .rows = &[_]i32{1},
                .cols = &[_]i32{1},
                .values = &[_]f64{42.0},
            };
            try matrix.validate();
        }

        test "stress: SparseMatrix: large indices validation" {
            const large_index = std.math.maxInt(i32) - 1;
            const matrix = types.SparseMatrix{
                .rows = &[_]i32{ 1, large_index },
                .cols = &[_]i32{ 1, large_index },
                .values = &[_]f64{ 1.0, 2.0 },
            };
            try matrix.validate();
        }

        test "unit: SparseMatrix: negative infinity value fails" {
            const matrix = types.SparseMatrix{
                .rows = &[_]i32{1},
                .cols = &[_]i32{1},
                .values = &[_]f64{-std.math.inf(f64)},
            };
            try testing.expectError(error.InvalidValue, matrix.validate());
        }

        test "unit: SparseMatrix: very small positive values are valid" {
            const matrix = types.SparseMatrix{
                .rows = &[_]i32{ 1, 2 },
                .cols = &[_]i32{ 1, 2 },
                .values = &[_]f64{ std.math.floatMin(f64), std.math.floatEps(f64) },
            };
            try matrix.validate();
        }

    // └──────────────────────────────────────────────────────────────────────────────┘

    // ┌──────────────────────────── Dense to Sparse Conversion ────────────────────────────┐

        test "integration: SparseMatrix: converts identity matrix correctly" {
            const size = 4;
            var dense: [size][size]f64 = undefined;
            
            // Create identity matrix
            for (0..size) |i| {
                for (0..size) |j| {
                    dense[i][j] = if (i == j) 1.0 else 0.0;
                }
            }
            
            // Convert to slices
            var dense_slices: [size][]const f64 = undefined;
            for (&dense_slices, &dense) |*slice, *row| {
                slice.* = row;
            }
            
            var sparse = try types.SparseMatrix.fromDense(
                testing.allocator,
                &dense_slices,
                1e-10
            );
            defer sparse.deinit(testing.allocator);
            
            // Identity matrix should have exactly 'size' non-zero elements
            try testing.expectEqual(@as(usize, size), sparse.values.len);
            
            // All values should be 1.0
            for (sparse.values) |val| {
                try testing.expectApproxEqAbs(@as(f64, 1.0), val, 1e-10);
            }
            
            try sparse.validate();
        }

        test "integration: SparseMatrix: handles diagonal matrix" {
            const dense = [_][3]f64{
                .{ 2.5, 0.0, 0.0 },
                .{ 0.0, -3.7, 0.0 },
                .{ 0.0, 0.0, 9.1 },
            };
            
            var dense_slices: [3][]const f64 = undefined;
            for (&dense_slices, &dense) |*slice, *row| {
                slice.* = row;
            }
            
            var sparse = try types.SparseMatrix.fromDense(
                testing.allocator,
                &dense_slices,
                1e-10
            );
            defer sparse.deinit(testing.allocator);
            
            try testing.expectEqual(@as(usize, 3), sparse.values.len);
            
            // Verify diagonal elements are captured
            var found_values = [_]bool{ false, false, false };
            const expected = [_]f64{ 2.5, -3.7, 9.1 };
            
            for (sparse.values) |val| {
                for (expected, 0..) |exp, i| {
                    if (@abs(val - exp) < 1e-10) {
                        found_values[i] = true;
                    }
                }
            }
            
            for (found_values) |found| {
                try testing.expect(found);
            }
            
            try sparse.validate();
        }

        test "stress: SparseMatrix: large sparse matrix conversion" {
            const size = 100;
            var dense: [size][size]f64 = undefined;
            
            // Create a sparse pattern with ~5% density
            for (0..size) |i| {
                for (0..size) |j| {
                    // Create a checkerboard-like pattern
                    if ((i + j) % 20 == 0) {
                        dense[i][j] = @as(f64, @floatFromInt(i + j + 1));
                    } else {
                        dense[i][j] = 0.0;
                    }
                }
            }
            
            // Convert to slices
            var dense_slices: [size][]const f64 = undefined;
            for (&dense_slices, &dense) |*slice, *row| {
                slice.* = row;
            }
            
            var sparse = try types.SparseMatrix.fromDense(
                testing.allocator,
                &dense_slices,
                1e-10
            );
            defer sparse.deinit(testing.allocator);
            
            // Count expected non-zeros
            var expected_nnz: usize = 0;
            for (dense) |row| {
                for (row) |val| {
                    if (@abs(val) > 1e-10) {
                        expected_nnz += 1;
                    }
                }
            }
            
            try testing.expectEqual(expected_nnz, sparse.values.len);
            try sparse.validate();
        }

        test "integration: SparseMatrix: tolerance filtering works correctly" {
            const dense = [_][2]f64{
                .{ 10.0, 0.5 },
                .{ 0.05, 20.0 },
            };
            
            var dense_slices: [2][]const f64 = undefined;
            for (&dense_slices, &dense) |*slice, *row| {
                slice.* = row;
            }
            
            // Test with different tolerances
            const test_cases = [_]struct { tolerance: f64, expected_nnz: usize }{
                .{ .tolerance = 0.01, .expected_nnz = 4 },  // All values
                .{ .tolerance = 0.1, .expected_nnz = 3 },   // Excludes 0.05
                .{ .tolerance = 1.0, .expected_nnz = 2 },   // Only 10.0 and 20.0
                .{ .tolerance = 15.0, .expected_nnz = 1 },  // Only 20.0
                .{ .tolerance = 25.0, .expected_nnz = 0 },  // Nothing
            };
            
            for (test_cases) |tc| {
                var sparse = try types.SparseMatrix.fromDense(
                    testing.allocator,
                    &dense_slices,
                    tc.tolerance
                );
                defer sparse.deinit(testing.allocator);
                
                try testing.expectEqual(tc.expected_nnz, sparse.values.len);
                try sparse.validate();
            }
        }

    // └──────────────────────────────────────────────────────────────────────────────┘

    // ┌──────────────────────────── Memory Management Tests ────────────────────────────┐

        test "integration: SparseMatrix: memory allocation and deallocation" {
            const dense = [_][3]f64{
                .{ 1.0, 2.0, 3.0 },
                .{ 4.0, 5.0, 6.0 },
                .{ 7.0, 8.0, 9.0 },
            };
            
            var dense_slices: [3][]const f64 = undefined;
            for (&dense_slices, &dense) |*slice, *row| {
                slice.* = row;
            }
            
            // Use a testing allocator that tracks memory
            var sparse = try types.SparseMatrix.fromDense(
                testing.allocator,
                &dense_slices,
                1e-10
            );
            
            // Verify all elements were captured
            try testing.expectEqual(@as(usize, 9), sparse.values.len);
            
            // Clean up memory
            sparse.deinit(testing.allocator);
            
            // After deinit, the pointers should be freed (we can't access them)
            // The test passes if no memory leak is detected by testing.allocator
        }

        test "stress: SparseMatrix: multiple allocations and deallocations" {
            // Stress test memory management with repeated allocations
            for (0..10) |iteration| {
                const size = iteration + 1;
                const dense = try testing.allocator.alloc([]f64, size);
                defer testing.allocator.free(dense);
                
                for (dense) |*row| {
                    row.* = try testing.allocator.alloc(f64, size);
                }
                defer for (dense) |row| {
                    testing.allocator.free(row);
                };
                
                // Fill with some pattern
                for (dense, 0..) |row, i| {
                    for (row, 0..) |*val, j| {
                        val.* = if (i == j) @as(f64, @floatFromInt(i + 1)) else 0.0;
                    }
                }
                
                // Convert to const slices
                const dense_const = try testing.allocator.alloc([]const f64, size);
                defer testing.allocator.free(dense_const);
                for (dense_const, dense) |*dst, src| {
                    dst.* = src;
                }
                
                var sparse = try types.SparseMatrix.fromDense(
                    testing.allocator,
                    dense_const,
                    1e-10
                );
                
                try sparse.validate();
                sparse.deinit(testing.allocator);
            }
        }

    // └──────────────────────────────────────────────────────────────────────────────┘

    // ┌──────────────────────────── Special Matrix Patterns ────────────────────────────┐

        test "e2e: SparseMatrix: tridiagonal matrix pattern" {
            const size = 5;
            var dense: [size][size]f64 = undefined;
            
            // Create tridiagonal matrix
            for (0..size) |i| {
                for (0..size) |j| {
                    if (i == j) {
                        dense[i][j] = 2.0;  // Main diagonal
                    } else if (@abs(@as(i32, @intCast(i)) - @as(i32, @intCast(j))) == 1) {
                        dense[i][j] = -1.0;  // Off-diagonals
                    } else {
                        dense[i][j] = 0.0;
                    }
                }
            }
            
            var dense_slices: [size][]const f64 = undefined;
            for (&dense_slices, &dense) |*slice, *row| {
                slice.* = row;
            }
            
            var sparse = try types.SparseMatrix.fromDense(
                testing.allocator,
                &dense_slices,
                1e-10
            );
            defer sparse.deinit(testing.allocator);
            
            // Tridiagonal 5x5 matrix has 5 + 4 + 4 = 13 non-zero elements
            try testing.expectEqual(@as(usize, 13), sparse.values.len);
            
            // Verify indices are in valid range
            for (sparse.rows) |row| {
                try testing.expect(row >= 1 and row <= size);
            }
            for (sparse.cols) |col| {
                try testing.expect(col >= 1 and col <= size);
            }
            
            try sparse.validate();
        }

        test "e2e: SparseMatrix: upper triangular matrix" {
            const dense = [_][4]f64{
                .{ 1.0, 2.0, 3.0, 4.0 },
                .{ 0.0, 5.0, 6.0, 7.0 },
                .{ 0.0, 0.0, 8.0, 9.0 },
                .{ 0.0, 0.0, 0.0, 10.0 },
            };
            
            var dense_slices: [4][]const f64 = undefined;
            for (&dense_slices, &dense) |*slice, *row| {
                slice.* = row;
            }
            
            var sparse = try types.SparseMatrix.fromDense(
                testing.allocator,
                &dense_slices,
                1e-10
            );
            defer sparse.deinit(testing.allocator);
            
            // Upper triangular 4x4 has 4+3+2+1 = 10 non-zero elements
            try testing.expectEqual(@as(usize, 10), sparse.values.len);
            
            // Verify upper triangular structure (row <= col for all entries)
            for (sparse.rows, sparse.cols) |row, col| {
                try testing.expect(row <= col);
            }
            
            try sparse.validate();
        }

        test "integration: SparseMatrix: single row matrix" {
            const dense = [_][5]f64{
                .{ 1.0, 0.0, 3.0, 0.0, 5.0 },
            };
            
            var dense_slices: [1][]const f64 = undefined;
            dense_slices[0] = &dense[0];
            
            var sparse = try types.SparseMatrix.fromDense(
                testing.allocator,
                &dense_slices,
                1e-10
            );
            defer sparse.deinit(testing.allocator);
            
            try testing.expectEqual(@as(usize, 3), sparse.values.len);
            
            // All row indices should be 1
            for (sparse.rows) |row| {
                try testing.expectEqual(@as(i32, 1), row);
            }
            
            try sparse.validate();
        }

        test "integration: SparseMatrix: single column matrix" {
            const dense = [_][1]f64{
                .{2.0},
                .{0.0},
                .{4.0},
                .{0.0},
                .{6.0},
            };
            
            var dense_slices: [5][]const f64 = undefined;
            for (&dense_slices, &dense) |*slice, *row| {
                slice.* = row;
            }
            
            var sparse = try types.SparseMatrix.fromDense(
                testing.allocator,
                &dense_slices,
                1e-10
            );
            defer sparse.deinit(testing.allocator);
            
            try testing.expectEqual(@as(usize, 3), sparse.values.len);
            
            // All column indices should be 1
            for (sparse.cols) |col| {
                try testing.expectEqual(@as(i32, 1), col);
            }
            
            try sparse.validate();
        }

    // └──────────────────────────────────────────────────────────────────────────────┘

    // ┌──────────────────────────── Numerical Edge Cases ────────────────────────────┐

        test "unit: SparseMatrix: handles denormalized numbers" {
            const denorm = std.math.floatMin(f64) / 2.0;  // Denormalized number
            const matrix = types.SparseMatrix{
                .rows = &[_]i32{1},
                .cols = &[_]i32{1},
                .values = &[_]f64{denorm},
            };
            try matrix.validate();  // Should be valid
        }

        test "integration: SparseMatrix: mixed positive and negative values" {
            const dense = [_][3]f64{
                .{ -1.5, 2.7, -3.9 },
                .{ 4.1, -5.3, 6.5 },
                .{ -7.7, 8.9, -9.1 },
            };
            
            var dense_slices: [3][]const f64 = undefined;
            for (&dense_slices, &dense) |*slice, *row| {
                slice.* = row;
            }
            
            var sparse = try types.SparseMatrix.fromDense(
                testing.allocator,
                &dense_slices,
                1e-10
            );
            defer sparse.deinit(testing.allocator);
            
            try testing.expectEqual(@as(usize, 9), sparse.values.len);
            
            // Check that signs are preserved
            var positive_count: usize = 0;
            var negative_count: usize = 0;
            for (sparse.values) |val| {
                if (val > 0) positive_count += 1;
                if (val < 0) negative_count += 1;
            }
            
            try testing.expectEqual(@as(usize, 4), positive_count);
            try testing.expectEqual(@as(usize, 5), negative_count);
            
            try sparse.validate();
        }

    // └──────────────────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ TEST ══════════════════════════════════════╗

    // ┌──────────────────────────── Conversion Performance ────────────────────────────┐

        test "performance: SparseMatrix: large matrix conversion benchmark" {
            const size = 200;
            const dense = try testing.allocator.alloc([]f64, size);
            defer testing.allocator.free(dense);
            
            for (dense) |*row| {
                row.* = try testing.allocator.alloc(f64, size);
            }
            defer for (dense) |row| {
                testing.allocator.free(row);
            };
            
            // Create a sparse pattern (about 1% density)
            for (dense, 0..) |row, i| {
                for (row, 0..) |*val, j| {
                    if ((i * size + j) % 100 == 0) {
                        val.* = @as(f64, @floatFromInt(i + j + 1));
                    } else {
                        val.* = 0.0;
                    }
                }
            }
            
            // Convert to const slices
            const dense_const = try testing.allocator.alloc([]const f64, size);
            defer testing.allocator.free(dense_const);
            for (dense_const, dense) |*dst, src| {
                dst.* = src;
            }
            
            const start = std.time.nanoTimestamp();
            var sparse = try types.SparseMatrix.fromDense(
                testing.allocator,
                dense_const,
                1e-10
            );
            const elapsed = std.time.nanoTimestamp() - start;
            defer sparse.deinit(testing.allocator);
            
            // Verify result
            const expected_nnz = (size * size) / 100;  // 1% density
            try testing.expectEqual(@as(usize, expected_nnz), sparse.values.len);
            try sparse.validate();
            
            // Performance assertion: conversion should be reasonably fast
            // This is a soft constraint - adjust if needed based on target hardware
            const elapsed_ms = @as(f64, @floatFromInt(elapsed)) / 1_000_000.0;
            try testing.expect(elapsed_ms < 100.0);  // Should complete within 100ms
        }

    // └──────────────────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ TEST ══════════════════════════════════════╗

    // ┌──────────────────────────── Cross-Type Interactions ────────────────────────────┐

        test "integration: AllEnums: consistent error naming convention" {
            // Verify all enum types follow consistent error naming
            const error_tests = .{
                .{ types.OptimizationDirection.fromGLPK(999), error.InvalidOptimizationDirection },
                .{ types.BoundType.fromGLPK(999), error.InvalidBoundType },
                .{ types.VariableKind.fromGLPK(999), error.InvalidVariableKind },
                .{ types.SolutionStatus.fromGLPK(999), error.InvalidSolutionStatus },
                .{ types.SimplexMethod.fromGLPK(999), error.InvalidSimplexMethod },
                .{ types.PricingRule.fromGLPK(999), error.InvalidPricingRule },
                .{ types.RatioTest.fromGLPK(999), error.InvalidRatioTest },
                .{ types.BranchingRule.fromGLPK(999), error.InvalidBranchingRule },
                .{ types.BacktrackingRule.fromGLPK(999), error.InvalidBacktrackingRule },
            };
            
            inline for (error_tests) |test_case| {
                try testing.expectError(test_case[1], test_case[0]);
            }
        }

        test "e2e: SparseMatrix: complete workflow from dense to validation" {
            // End-to-end test simulating real usage
            const allocator = testing.allocator;
            
            // Step 1: Create a realistic constraint matrix
            const constraints = [_][4]f64{
                .{ 2.0, 1.0, 1.0, 0.0 },  // 2x + y + z <= 10
                .{ 1.0, 2.0, 0.0, 1.0 },  // x + 2y + w <= 8
                .{ 0.0, 1.0, 2.0, 1.0 },  // y + 2z + w <= 6
            };
            
            var dense_slices: [3][]const f64 = undefined;
            for (&dense_slices, &constraints) |*slice, *row| {
                slice.* = row;
            }
            
            // Step 2: Convert to sparse format
            var sparse = try types.SparseMatrix.fromDense(
                allocator,
                &dense_slices,
                1e-10
            );
            defer sparse.deinit(allocator);
            
            // Step 3: Validate the matrix
            try sparse.validate();
            
            // Step 4: Verify expected properties
            // Count non-zeros: Row 1 has 3, Row 2 has 3, Row 3 has 3 = 9 total
            try testing.expectEqual(@as(usize, 9), sparse.values.len);  // 9 non-zeros
            
            // Step 5: Check that all indices are in valid range
            for (sparse.rows) |row| {
                try testing.expect(row >= 1 and row <= 3);
            }
            for (sparse.cols) |col| {
                try testing.expect(col >= 1 and col <= 4);
            }
            
            // Step 6: Verify all values are positive (as expected for this constraint matrix)
            for (sparse.values) |val| {
                try testing.expect(val > 0);
            }
        }

    // └──────────────────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════╝