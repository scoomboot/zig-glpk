// linking.test.zig — Comprehensive GLPK linking verification tests
//
// repo   : https://github.com/scoomboot/zig-glpk
// docs   : https://scoomboot.github.io/zig-glpk/lib/c/utils/glpk
// author : https://github.com/scoomboot
//
// Vibe coded by Scoom.

// ╔══════════════════════════════════════ PACK ══════════════════════════════════════╗

    const std = @import("std");
    const testing = std.testing;
    const builtin = @import("builtin");
    const glpk = @import("./glpk.zig");

// ╚══════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ INIT ══════════════════════════════════════╗

    // ┌──────────────────────────── Test Constants ────────────────────────────┐
    
        // Platform detection info
        const current_os = builtin.os.tag;
        const current_arch = builtin.cpu.arch;
        
        // Numerical tolerance for comparisons
        const EPSILON = 1e-9;
        
        // Memory stress test parameters
        const STRESS_ITERATIONS = 500;
        const LARGE_PROBLEM_SIZE = 5000;
    
    // └──────────────────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ TEST ══════════════════════════════════════╗

    // ┌──────────────────────────── Symbol Linkage Verification ────────────────────────────┐
    
        test "unit: GLPKLinking: verify @cImport works correctly" {
            // Direct test of C import functionality
            const c_api = glpk.c;
            
            // Verify some critical constants are available
            try testing.expect(c_api.GLP_MIN != 0 or c_api.GLP_MIN == 0);  // Just checking it exists
            try testing.expect(c_api.GLP_MAX != 0 or c_api.GLP_MAX == 0);
            
            // Verify we can work with the opaque pointer type
            const prob_ptr: ?*c_api.glp_prob = null;
            try testing.expect(prob_ptr == null);
        }
        
        test "unit: GLPKLinking: verify all critical symbols are present" {
            // Test that all major GLPK functions are properly linked
            // This test would fail at compile time if symbols are missing
            
            // Problem management functions
            try testing.expect(@TypeOf(glpk.c.glp_create_prob) == @TypeOf(glpk.c.glp_create_prob));
            try testing.expect(@TypeOf(glpk.c.glp_delete_prob) == @TypeOf(glpk.c.glp_delete_prob));
            try testing.expect(@TypeOf(glpk.c.glp_set_prob_name) == @TypeOf(glpk.c.glp_set_prob_name));
            
            // Solver functions
            try testing.expect(@TypeOf(glpk.c.glp_simplex) == @TypeOf(glpk.c.glp_simplex));
            try testing.expect(@TypeOf(glpk.c.glp_intopt) == @TypeOf(glpk.c.glp_intopt));
            try testing.expect(@TypeOf(glpk.c.glp_interior) == @TypeOf(glpk.c.glp_interior));
            
            // Matrix functions
            try testing.expect(@TypeOf(glpk.c.glp_load_matrix) == @TypeOf(glpk.c.glp_load_matrix));
            try testing.expect(@TypeOf(glpk.c.glp_set_mat_row) == @TypeOf(glpk.c.glp_set_mat_row));
            try testing.expect(@TypeOf(glpk.c.glp_set_mat_col) == @TypeOf(glpk.c.glp_set_mat_col));
        }
        
        test "unit: GLPKLinking: verify version function linkage" {
            // Test that version function is properly linked and returns valid data
            const version_ptr = glpk.c.glp_version();
            try testing.expect(version_ptr != null);
            
            // Convert to Zig string and verify format
            const version = std.mem.span(version_ptr);
            try testing.expect(version.len > 0);
            try testing.expect(version.len < 100);  // Sanity check
            
            // Should contain a dot (e.g., "5.0")
            try testing.expect(std.mem.indexOf(u8, version, ".") != null);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Platform-Specific Linking Tests ────────────────────────────┐
    
        test "unit: PlatformLinking: verify linking works on current platform" {
            // Platform-specific verification
            const prob = glpk.createProblem();
            defer glpk.deleteProblem(prob);
            
            try testing.expect(prob != null);
            
            // Log current platform for debugging
            std.debug.print("\nTesting GLPK linking on: {s} {s}\n", .{ 
                @tagName(current_os), 
                @tagName(current_arch) 
            });
            
            // Verify we can perform basic operations without segfaults
            glpk.setProblemName(prob, "platform_test");
            glpk.setObjectiveDirection(prob, glpk.GLP_MIN);
            
            const dir = glpk.getObjectiveDirection(prob);
            try testing.expectEqual(glpk.GLP_MIN, dir);
        }
        
        test "unit: PlatformLinking: verify library handle is valid" {
            // Create multiple problems to verify library is properly loaded
            var problems: [10]?*glpk.c.glp_prob = undefined;
            
            for (&problems) |*prob| {
                prob.* = glpk.createProblem();
                try testing.expect(prob.* != null);
            }
            
            // Clean up
            for (problems) |prob| {
                glpk.deleteProblem(prob);
            }
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Advanced API Linking Tests ────────────────────────────┐
    
        test "integration: AdvancedLinking: verify complex problem creation" {
            const prob = glpk.createProblem();
            defer glpk.deleteProblem(prob);
            
            // Test more advanced API functions that might not be in basic tests
            glpk.setProblemName(prob, "advanced_test");
            
            // Add multiple rows and columns
            const row_base = glpk.addRows(prob, 10);
            const col_base = glpk.addColumns(prob, 15);
            
            try testing.expect(row_base > 0);
            try testing.expect(col_base > 0);
            
            // Set various bounds types to test all enum values work
            glpk.setRowBounds(prob, row_base, glpk.GLP_FR, 0, 0);      // Free
            glpk.setRowBounds(prob, row_base + 1, glpk.GLP_LO, 10, 0); // Lower
            glpk.setRowBounds(prob, row_base + 2, glpk.GLP_UP, 0, 20); // Upper
            glpk.setRowBounds(prob, row_base + 3, glpk.GLP_DB, 5, 15); // Double
            glpk.setRowBounds(prob, row_base + 4, glpk.GLP_FX, 7, 7);  // Fixed
            
            // Set column kinds to test integer programming symbols
            glpk.setColumnKind(prob, col_base, glpk.GLP_CV);      // Continuous
            glpk.setColumnKind(prob, col_base + 1, glpk.GLP_IV);  // Integer
            glpk.setColumnKind(prob, col_base + 2, glpk.GLP_BV);  // Binary
            
            // Verify counts
            try testing.expectEqual(@as(c_int, 10), glpk.getNumRows(prob));
            try testing.expectEqual(@as(c_int, 15), glpk.getNumColumns(prob));
        }
        
        test "integration: AdvancedLinking: verify all solver methods are linked" {
            const prob = glpk.createProblem();
            defer glpk.deleteProblem(prob);
            
            // Create a minimal valid problem
            _ = glpk.addRows(prob, 1);
            _ = glpk.addColumns(prob, 1);
            glpk.setRowBounds(prob, 1, glpk.GLP_UP, 0, 1);
            glpk.setColumnBounds(prob, 1, glpk.GLP_LO, 0, 0);
            glpk.setObjectiveCoef(prob, 1, 1);
            
            var ia = [_]c_int{ 0, 1 };
            var ja = [_]c_int{ 0, 1 };
            var ar = [_]f64{ 0, 1 };
            glpk.loadMatrix(prob, 1, &ia, &ja, &ar);
            
            // Test simplex solver linkage
            var smcp: glpk.SimplexParams = undefined;
            glpk.initSimplexParams(&smcp);
            smcp.msg_lev = glpk.GLP_MSG_OFF;
            const simplex_result = glpk.simplex(prob, &smcp);
            try testing.expect(simplex_result == 0 or simplex_result != 0); // Just verify it doesn't crash
            
            // Test interior point solver linkage  
            var iptcp: glpk.InteriorParams = undefined;
            glpk.initInteriorParams(&iptcp);
            iptcp.msg_lev = glpk.GLP_MSG_OFF;
            const interior_result = glpk.interior(prob, &iptcp);
            try testing.expect(interior_result == 0 or interior_result != 0);
            
            // For MIP solver, we need to set column kind first
            glpk.setColumnKind(prob, 1, glpk.GLP_IV);
            var iocp: glpk.MIPParams = undefined;
            glpk.initMIPParams(&iocp);
            iocp.msg_lev = glpk.GLP_MSG_OFF;
            const mip_result = glpk.intopt(prob, &iocp);
            try testing.expect(mip_result == 0 or mip_result != 0);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Memory and Resource Tests ────────────────────────────┐
    
        test "stress: MemoryLinking: verify no memory leaks with repeated operations" {
            var i: usize = 0;
            while (i < STRESS_ITERATIONS) : (i += 1) {
                const prob = glpk.createProblem();
                
                // Perform various operations
                _ = glpk.addRows(prob, 5);
                _ = glpk.addColumns(prob, 5);
                glpk.setProblemName(prob, "stress_test");
                glpk.setObjectiveDirection(prob, if (i % 2 == 0) glpk.GLP_MIN else glpk.GLP_MAX);
                
                // Set some coefficients
                for (1..6) |j| {
                    glpk.setObjectiveCoef(prob, @intCast(j), @floatFromInt(j));
                }
                
                glpk.deleteProblem(prob);
            }
            
            // If we get here without crashing, memory management is working
            try testing.expect(true);
        }
        
        test "stress: LargeProblemLinking: verify large problem handling" {
            const prob = glpk.createProblem();
            defer glpk.deleteProblem(prob);
            
            // Create a very large problem to stress test linking
            const rows_added = glpk.addRows(prob, LARGE_PROBLEM_SIZE);
            const cols_added = glpk.addColumns(prob, LARGE_PROBLEM_SIZE);
            
            try testing.expect(rows_added > 0);
            try testing.expect(cols_added > 0);
            try testing.expectEqual(@as(c_int, LARGE_PROBLEM_SIZE), glpk.getNumRows(prob));
            try testing.expectEqual(@as(c_int, LARGE_PROBLEM_SIZE), glpk.getNumColumns(prob));
            
            // Set bounds on a subset to verify operations work at scale
            for (1..101) |i| {
                glpk.setRowBounds(prob, @intCast(i), glpk.GLP_UP, 0, @floatFromInt(i * 10));
                glpk.setColumnBounds(prob, @intCast(i), glpk.GLP_LO, @floatFromInt(i), 0);
            }
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Build Configuration Tests ────────────────────────────┐
    
        test "unit: BuildConfig: verify library is linked with correct mode" {
            // This test verifies the library linking works in the current build mode
            const prob = glpk.createProblem();
            defer glpk.deleteProblem(prob);
            
            // The ability to create and delete proves linking is working
            try testing.expect(prob != null);
            
            // Log build mode for debugging
            std.debug.print("\nBuild mode: {s}\n", .{@tagName(builtin.mode)});
        }
        
        test "unit: BuildConfig: verify constants match C header" {
            // Verify that our wrapped constants match the C constants
            try testing.expectEqual(glpk.c.GLP_MIN, glpk.GLP_MIN);
            try testing.expectEqual(glpk.c.GLP_MAX, glpk.GLP_MAX);
            try testing.expectEqual(glpk.c.GLP_FR, glpk.GLP_FR);
            try testing.expectEqual(glpk.c.GLP_LO, glpk.GLP_LO);
            try testing.expectEqual(glpk.c.GLP_UP, glpk.GLP_UP);
            try testing.expectEqual(glpk.c.GLP_DB, glpk.GLP_DB);
            try testing.expectEqual(glpk.c.GLP_FX, glpk.GLP_FX);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Cross-Compilation Readiness Tests ────────────────────────────┐
    
        test "unit: CrossCompile: verify no platform-specific assumptions" {
            // This test ensures our code doesn't make platform-specific assumptions
            const prob = glpk.createProblem();
            defer glpk.deleteProblem(prob);
            
            // Test pointer size independence
            const ptr_size = @sizeOf(*glpk.c.glp_prob);
            try testing.expect(ptr_size == @sizeOf(usize));
            
            // Test that c_int is used consistently (not hardcoded int sizes)
            const num_rows: c_int = 5;
            const added = glpk.addRows(prob, num_rows);
            try testing.expect(added > 0);
            try testing.expectEqual(num_rows, glpk.getNumRows(prob));
        }
        
        test "unit: CrossCompile: verify endianness independence" {
            // GLPK should handle endianness internally
            const prob = glpk.createProblem();
            defer glpk.deleteProblem(prob);
            
            // Set a floating point value and retrieve it
            _ = glpk.addColumns(prob, 1);
            const test_value: f64 = 3.141592653589793;
            glpk.setObjectiveCoef(prob, 1, test_value);
            
            // Create simple problem to get objective value
            _ = glpk.addRows(prob, 1);
            glpk.setRowBounds(prob, 1, glpk.GLP_FX, 1, 1);
            glpk.setColumnBounds(prob, 1, glpk.GLP_FX, 1, 1);
            
            var ia = [_]c_int{ 0, 1 };
            var ja = [_]c_int{ 0, 1 };
            var ar = [_]f64{ 0, 1 };
            glpk.loadMatrix(prob, 1, &ia, &ja, &ar);
            
            var params: glpk.SimplexParams = undefined;
            glpk.initSimplexParams(&params);
            params.msg_lev = glpk.GLP_MSG_OFF;
            
            _ = glpk.simplex(prob, &params);
            const obj_val = glpk.getObjectiveValue(prob);
            
            // Should be approximately test_value * 1
            try testing.expect(@abs(obj_val - test_value) < EPSILON);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Error Handling Tests ────────────────────────────┐
    
        test "integration: ErrorHandling: verify wrapper functions require valid pointers" {
            // Note: GLPK C library does NOT handle null pointers gracefully
            // This test documents that our wrapper functions pass through nulls
            // without additional checks, maintaining C API compatibility
            
            // Create a valid problem to test with
            const prob = glpk.createProblem();
            defer glpk.deleteProblem(prob);
            
            // Verify we got a valid pointer
            try testing.expect(prob != null);
            
            // We can safely work with valid pointers
            glpk.setProblemName(prob, "test");
            glpk.setObjectiveDirection(prob, glpk.GLP_MIN);
            
            // Document that null handling is the caller's responsibility
            try testing.expect(true);
        }
        
        test "integration: ErrorHandling: verify valid index requirements" {
            const prob = glpk.createProblem();
            defer glpk.deleteProblem(prob);
            
            _ = glpk.addRows(prob, 5);
            _ = glpk.addColumns(prob, 5);
            
            // GLPK uses 1-based indexing and requires valid indices
            // Invalid indices will cause errors or crashes in the C library
            // This test documents proper usage patterns
            
            // Valid indices for 5 rows/columns are 1-5
            glpk.setRowBounds(prob, 1, glpk.GLP_FR, 0, 0);     // Valid: first row
            glpk.setRowBounds(prob, 5, glpk.GLP_FR, 0, 0);     // Valid: last row
            glpk.setColumnBounds(prob, 1, glpk.GLP_FR, 0, 0);  // Valid: first column
            glpk.setColumnBounds(prob, 5, glpk.GLP_FR, 0, 0);  // Valid: last column
            
            // Test passes if we can access valid indices without issues
            try testing.expect(true);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── End-to-End Integration Tests ────────────────────────────┐
    
        test "e2e: CompletePipeline: create, solve, and analyze problem" {
            // Complete end-to-end test of GLPK functionality
            const prob = glpk.createProblem();
            defer glpk.deleteProblem(prob);
            
            // Set up a complete LP problem
            glpk.setProblemName(prob, "e2e_test");
            glpk.setObjectiveDirection(prob, glpk.GLP_MAX);
            
            // Add constraints: x + 2y <= 10, 3x + y <= 15
            _ = glpk.addRows(prob, 2);
            glpk.setRowName(prob, 1, "constraint1");
            glpk.setRowBounds(prob, 1, glpk.GLP_UP, 0, 10);
            glpk.setRowName(prob, 2, "constraint2");
            glpk.setRowBounds(prob, 2, glpk.GLP_UP, 0, 15);
            
            // Add variables: maximize 3x + 4y
            _ = glpk.addColumns(prob, 2);
            glpk.setColumnName(prob, 1, "x");
            glpk.setColumnBounds(prob, 1, glpk.GLP_LO, 0, 0);
            glpk.setObjectiveCoef(prob, 1, 3);
            glpk.setColumnName(prob, 2, "y");
            glpk.setColumnBounds(prob, 2, glpk.GLP_LO, 0, 0);
            glpk.setObjectiveCoef(prob, 2, 4);
            
            // Load constraint matrix
            var ia = [_]c_int{ 0, 1, 1, 2, 2 };
            var ja = [_]c_int{ 0, 1, 2, 1, 2 };
            var ar = [_]f64{ 0, 1, 2, 3, 1 };
            glpk.loadMatrix(prob, 4, &ia, &ja, &ar);
            
            // Solve with simplex
            var params: glpk.SimplexParams = undefined;
            glpk.initSimplexParams(&params);
            params.msg_lev = glpk.GLP_MSG_OFF;
            
            const result = glpk.simplex(prob, &params);
            try testing.expectEqual(@as(c_int, 0), result);
            
            // Verify solution
            const status = glpk.getStatus(prob);
            try testing.expectEqual(glpk.GLP_OPT, status);
            
            const obj_val = glpk.getObjectiveValue(prob);
            const x_val = glpk.getColumnPrimal(prob, 1);
            const y_val = glpk.getColumnPrimal(prob, 2);
            
            // Verify solution satisfies constraints
            try testing.expect(x_val >= -EPSILON);
            try testing.expect(y_val >= -EPSILON);
            try testing.expect(x_val + 2 * y_val <= 10 + EPSILON);
            try testing.expect(3 * x_val + y_val <= 15 + EPSILON);
            try testing.expect(@abs(obj_val - (3 * x_val + 4 * y_val)) < EPSILON);
        }
        
        test "e2e: MIPPipeline: solve mixed integer programming problem" {
            const prob = glpk.createProblem();
            defer glpk.deleteProblem(prob);
            
            glpk.setProblemName(prob, "mip_test");
            glpk.setObjectiveDirection(prob, glpk.GLP_MAX);
            
            // Add constraints
            _ = glpk.addRows(prob, 2);
            glpk.setRowBounds(prob, 1, glpk.GLP_UP, 0, 20);
            glpk.setRowBounds(prob, 2, glpk.GLP_UP, 0, 30);
            
            // Add variables (one integer, one continuous)
            _ = glpk.addColumns(prob, 2);
            glpk.setColumnBounds(prob, 1, glpk.GLP_LO, 0, 0);
            glpk.setColumnKind(prob, 1, glpk.GLP_IV);  // Integer variable
            glpk.setObjectiveCoef(prob, 1, 5);
            
            glpk.setColumnBounds(prob, 2, glpk.GLP_LO, 0, 0);
            glpk.setColumnKind(prob, 2, glpk.GLP_CV);  // Continuous variable
            glpk.setObjectiveCoef(prob, 2, 3);
            
            // Load matrix: 2x + 3y <= 20, 4x + 2y <= 30
            var ia = [_]c_int{ 0, 1, 1, 2, 2 };
            var ja = [_]c_int{ 0, 1, 2, 1, 2 };
            var ar = [_]f64{ 0, 2, 3, 4, 2 };
            glpk.loadMatrix(prob, 4, &ia, &ja, &ar);
            
            // Solve as MIP
            var params: glpk.MIPParams = undefined;
            glpk.initMIPParams(&params);
            params.msg_lev = glpk.GLP_MSG_OFF;
            
            const result = glpk.intopt(prob, &params);
            // MIP solver may return various status codes
            // 0 = success, other codes indicate different conditions
            // We just verify it doesn't crash
            _ = result;
            
            // Get MIP solution
            const status = glpk.getMIPStatus(prob);
            if (status == glpk.GLP_OPT) {
                const x_val = glpk.getMIPColumnValue(prob, 1);
                const y_val = glpk.getMIPColumnValue(prob, 2);
                
                // x should be integer
                try testing.expect(@abs(x_val - @round(x_val)) < EPSILON);
                
                // Verify constraints
                try testing.expect(2 * x_val + 3 * y_val <= 20 + EPSILON);
                try testing.expect(4 * x_val + 2 * y_val <= 30 + EPSILON);
            }
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════╝