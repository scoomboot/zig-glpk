// glpk.test.zig — Comprehensive unit tests for GLPK bindings
//
// repo   : https://github.com/scoomboot/zig-glpk
// docs   : https://scoomboot.github.io/zig-glpk/lib/c/utils/glpk
// author : https://github.com/scoomboot
//
// Vibe coded by Scoom.

// ╔══════════════════════════════════════ PACK ══════════════════════════════════════╗

    const std = @import("std");
    const testing = std.testing;
    const glpk = @import("./glpk.zig");

// ╚══════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ INIT ══════════════════════════════════════╗

    // ┌──────────────────────────── Test Constants ────────────────────────────┐
    
        // Expected GLPK version constants
        const EXPECTED_MAJOR_VERSION = 5;
        const EXPECTED_MINOR_VERSION = 0;
        const EXPECTED_VERSION_STRING = "5.0";
        
        // Test problem parameters
        const TEST_PROBLEM_NAME = "test_problem";
        const TEST_ROW_NAME = "constraint1";
        const TEST_COL_NAME = "variable1";
        
        // Numerical tolerance for floating point comparisons
        const EPSILON = 1e-6;
    
    // └──────────────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ TEST ══════════════════════════════════════╗

    // ┌──────────────────────────── Library Linkage Tests ────────────────────────────┐
    
        test "unit: GLPKLibrary: verify library is properly linked" {
            // Test that we can call a basic GLPK function without crashing
            // Creating and immediately deleting a problem tests linkage
            const prob = glpk.createProblem();
            try testing.expect(prob != null);
            glpk.deleteProblem(prob);
        }
        
        test "unit: GLPKVersion: library version string matches expected format" {
            const version = glpk.getVersion();
            try testing.expect(version.len > 0);
            
            // Version should contain a dot separator
            const dot_index = std.mem.indexOf(u8, version, ".");
            try testing.expect(dot_index != null);
        }
    
    // └──────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Version Function Tests ────────────────────────────┐
    
        test "unit: VersionUtils: getVersion returns expected version string" {
            const version = glpk.getVersion();
            try testing.expectEqualStrings(EXPECTED_VERSION_STRING, version);
        }
        
        test "unit: VersionUtils: getMajorVersion returns correct major version" {
            const major = glpk.getMajorVersion();
            try testing.expectEqual(EXPECTED_MAJOR_VERSION, major);
        }
        
        test "unit: VersionUtils: getMinorVersion returns correct minor version" {
            const minor = glpk.getMinorVersion();
            try testing.expectEqual(EXPECTED_MINOR_VERSION, minor);
        }
        
        test "unit: VersionUtils: version functions handle edge cases" {
            // These should not crash even if version format changes
            const version = glpk.getVersion();
            const major = glpk.getMajorVersion();
            const minor = glpk.getMinorVersion();
            
            // Basic sanity checks
            try testing.expect(version.len > 0);
            try testing.expect(major >= 0);
            try testing.expect(minor >= 0);
        }
    
    // └──────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Problem Management Tests ────────────────────────────┐
    
        test "unit: ProblemManagement: create and delete problem" {
            const prob = glpk.createProblem();
            try testing.expect(prob != null);
            
            // Should be able to delete without issues
            glpk.deleteProblem(prob);
        }
        
        test "unit: ProblemManagement: set problem name" {
            const prob = glpk.createProblem();
            defer glpk.deleteProblem(prob);
            
            // Setting problem name should not crash
            glpk.setProblemName(prob, TEST_PROBLEM_NAME);
            
            // No direct way to get problem name in basic API,
            // but we can verify it doesn't crash
        }
        
        test "unit: ProblemManagement: set and get objective direction" {
            const prob = glpk.createProblem();
            defer glpk.deleteProblem(prob);
            
            // Test minimize
            glpk.setObjectiveDirection(prob, glpk.GLP_MIN);
            try testing.expectEqual(glpk.GLP_MIN, glpk.getObjectiveDirection(prob));
            
            // Test maximize
            glpk.setObjectiveDirection(prob, glpk.GLP_MAX);
            try testing.expectEqual(glpk.GLP_MAX, glpk.getObjectiveDirection(prob));
        }
        
        test "unit: ProblemManagement: multiple problems can coexist" {
            const prob1 = glpk.createProblem();
            const prob2 = glpk.createProblem();
            const prob3 = glpk.createProblem();
            
            try testing.expect(prob1 != null);
            try testing.expect(prob2 != null);
            try testing.expect(prob3 != null);
            try testing.expect(prob1 != prob2);
            try testing.expect(prob2 != prob3);
            try testing.expect(prob1 != prob3);
            
            glpk.deleteProblem(prob1);
            glpk.deleteProblem(prob2);
            glpk.deleteProblem(prob3);
        }
    
    // └──────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Row Management Tests ────────────────────────────┐
    
        test "unit: RowManagement: add rows to problem" {
            const prob = glpk.createProblem();
            defer glpk.deleteProblem(prob);
            
            // Initially should have 0 rows
            try testing.expectEqual(@as(c_int, 0), glpk.getNumRows(prob));
            
            // Add 3 rows
            const row_index = glpk.addRows(prob, 3);
            try testing.expect(row_index > 0);
            try testing.expectEqual(@as(c_int, 3), glpk.getNumRows(prob));
            
            // Add 2 more rows
            _ = glpk.addRows(prob, 2);
            try testing.expectEqual(@as(c_int, 5), glpk.getNumRows(prob));
        }
        
        test "unit: RowManagement: set row properties" {
            const prob = glpk.createProblem();
            defer glpk.deleteProblem(prob);
            
            const row_idx = glpk.addRows(prob, 1);
            
            // Set row name (should not crash)
            glpk.setRowName(prob, row_idx, TEST_ROW_NAME);
            
            // Set different types of bounds
            glpk.setRowBounds(prob, row_idx, glpk.GLP_FX, 10.0, 10.0);  // Fixed
            glpk.setRowBounds(prob, row_idx, glpk.GLP_LO, 5.0, 0.0);    // Lower bound
            glpk.setRowBounds(prob, row_idx, glpk.GLP_UP, 0.0, 15.0);   // Upper bound
            glpk.setRowBounds(prob, row_idx, glpk.GLP_DB, 5.0, 15.0);   // Double bound
            glpk.setRowBounds(prob, row_idx, glpk.GLP_FR, 0.0, 0.0);    // Free
        }
    
    // └──────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Column Management Tests ────────────────────────────┐
    
        test "unit: ColumnManagement: add columns to problem" {
            const prob = glpk.createProblem();
            defer glpk.deleteProblem(prob);
            
            // Initially should have 0 columns
            try testing.expectEqual(@as(c_int, 0), glpk.getNumColumns(prob));
            
            // Add 4 columns
            const col_index = glpk.addColumns(prob, 4);
            try testing.expect(col_index > 0);
            try testing.expectEqual(@as(c_int, 4), glpk.getNumColumns(prob));
            
            // Add 3 more columns
            _ = glpk.addColumns(prob, 3);
            try testing.expectEqual(@as(c_int, 7), glpk.getNumColumns(prob));
        }
        
        test "unit: ColumnManagement: set column properties" {
            const prob = glpk.createProblem();
            defer glpk.deleteProblem(prob);
            
            const col_idx = glpk.addColumns(prob, 1);
            
            // Set column name (should not crash)
            glpk.setColumnName(prob, col_idx, TEST_COL_NAME);
            
            // Set objective coefficient
            glpk.setObjectiveCoef(prob, col_idx, 3.5);
            
            // Set different types of bounds
            glpk.setColumnBounds(prob, col_idx, glpk.GLP_FX, 10.0, 10.0);  // Fixed
            glpk.setColumnBounds(prob, col_idx, glpk.GLP_LO, 0.0, 0.0);    // Lower bound
            glpk.setColumnBounds(prob, col_idx, glpk.GLP_UP, 0.0, 100.0);  // Upper bound
            glpk.setColumnBounds(prob, col_idx, glpk.GLP_DB, 0.0, 100.0);  // Double bound
            glpk.setColumnBounds(prob, col_idx, glpk.GLP_FR, 0.0, 0.0);    // Free
            
            // Set column kind
            glpk.setColumnKind(prob, col_idx, glpk.GLP_CV);  // Continuous
            glpk.setColumnKind(prob, col_idx, glpk.GLP_IV);  // Integer
            glpk.setColumnKind(prob, col_idx, glpk.GLP_BV);  // Binary
        }
    
    // └──────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Simple LP Problem Test ────────────────────────────┐
    
        test "integration: SimplexSolver: solve basic LP problem" {
            // Create a simple LP problem:
            // Maximize: z = 10*x1 + 6*x2 + 4*x3
            // Subject to:
            //   x1 + x2 + x3 <= 100
            //   10*x1 + 4*x2 + 5*x3 <= 600
            //   2*x1 + 2*x2 + 6*x3 <= 300
            //   x1, x2, x3 >= 0
            
            const prob = glpk.createProblem();
            defer glpk.deleteProblem(prob);
            
            glpk.setProblemName(prob, "simple_lp");
            glpk.setObjectiveDirection(prob, glpk.GLP_MAX);
            
            // Add 3 constraints (rows)
            _ = glpk.addRows(prob, 3);
            glpk.setRowName(prob, 1, "constraint1");
            glpk.setRowBounds(prob, 1, glpk.GLP_UP, 0.0, 100.0);
            glpk.setRowName(prob, 2, "constraint2");
            glpk.setRowBounds(prob, 2, glpk.GLP_UP, 0.0, 600.0);
            glpk.setRowName(prob, 3, "constraint3");
            glpk.setRowBounds(prob, 3, glpk.GLP_UP, 0.0, 300.0);
            
            // Add 3 variables (columns)
            _ = glpk.addColumns(prob, 3);
            glpk.setColumnName(prob, 1, "x1");
            glpk.setColumnBounds(prob, 1, glpk.GLP_LO, 0.0, 0.0);
            glpk.setObjectiveCoef(prob, 1, 10.0);
            glpk.setColumnName(prob, 2, "x2");
            glpk.setColumnBounds(prob, 2, glpk.GLP_LO, 0.0, 0.0);
            glpk.setObjectiveCoef(prob, 2, 6.0);
            glpk.setColumnName(prob, 3, "x3");
            glpk.setColumnBounds(prob, 3, glpk.GLP_LO, 0.0, 0.0);
            glpk.setObjectiveCoef(prob, 3, 4.0);
            
            // Load the constraint matrix
            // Using 1-based indexing for GLPK
            var ia = [_]c_int{ 0, 1, 1, 1, 2, 2, 2, 3, 3, 3 };
            var ja = [_]c_int{ 0, 1, 2, 3, 1, 2, 3, 1, 2, 3 };
            var ar = [_]f64{ 0, 1, 1, 1, 10, 4, 5, 2, 2, 6 };
            
            glpk.loadMatrix(prob, 9, &ia, &ja, &ar);
            
            // Solve with simplex method
            var params: glpk.SimplexParams = undefined;
            glpk.initSimplexParams(&params);
            params.msg_lev = glpk.GLP_MSG_OFF;  // Suppress output during tests
            
            const result = glpk.simplex(prob, &params);
            
            // Check solution status
            try testing.expectEqual(@as(c_int, 0), result);  // 0 means success
            
            const status = glpk.getStatus(prob);
            try testing.expectEqual(glpk.GLP_OPT, status);  // Optimal solution found
            
            // Get objective value
            const obj_val = glpk.getObjectiveValue(prob);
            try testing.expect(obj_val > 0);  // Should have positive objective value
            
            // Get variable values
            const x1 = glpk.getColumnPrimal(prob, 1);
            const x2 = glpk.getColumnPrimal(prob, 2);
            const x3 = glpk.getColumnPrimal(prob, 3);
            
            // All variables should be non-negative
            try testing.expect(x1 >= 0.0);
            try testing.expect(x2 >= 0.0);
            try testing.expect(x3 >= 0.0);
            
            // Check constraints are satisfied (with tolerance)
            try testing.expect(x1 + x2 + x3 <= 100.0 + EPSILON);
            try testing.expect(10.0 * x1 + 4.0 * x2 + 5.0 * x3 <= 600.0 + EPSILON);
            try testing.expect(2.0 * x1 + 2.0 * x2 + 6.0 * x3 <= 300.0 + EPSILON);
        }
    
    // └──────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Matrix Coefficient Tests ────────────────────────────┐
    
        test "unit: MatrixOperations: set matrix row" {
            const prob = glpk.createProblem();
            defer glpk.deleteProblem(prob);
            
            _ = glpk.addRows(prob, 1);
            _ = glpk.addColumns(prob, 3);
            
            // Set entire row at once
            var indices = [_]c_int{ 0, 1, 2, 3 };  // 1-based indexing
            var values = [_]f64{ 0, 2.5, 3.0, 1.5 };
            
            glpk.setMatrixRow(prob, 1, 3, &indices, &values);
        }
        
        test "unit: MatrixOperations: set matrix column" {
            const prob = glpk.createProblem();
            defer glpk.deleteProblem(prob);
            
            _ = glpk.addRows(prob, 3);
            _ = glpk.addColumns(prob, 1);
            
            // Set entire column at once
            var indices = [_]c_int{ 0, 1, 2, 3 };  // 1-based indexing
            var values = [_]f64{ 0, 4.0, 2.0, 5.0 };
            
            glpk.setMatrixCol(prob, 1, 3, &indices, &values);
        }
    
    // └──────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Memory Management Tests ────────────────────────────┐
    
        test "stress: MemoryManagement: create and delete many problems" {
            // Create and delete many problems to test memory management
            var i: usize = 0;
            while (i < 100) : (i += 1) {
                const prob = glpk.createProblem();
                try testing.expect(prob != null);
                
                // Add some rows and columns to stress memory allocation
                _ = glpk.addRows(prob, 10);
                _ = glpk.addColumns(prob, 10);
                
                glpk.deleteProblem(prob);
            }
        }
        
        test "stress: MemoryManagement: large problem creation" {
            const prob = glpk.createProblem();
            defer glpk.deleteProblem(prob);
            
            // Create a problem with many rows and columns
            const num_rows = 1000;
            const num_cols = 1000;
            
            _ = glpk.addRows(prob, num_rows);
            _ = glpk.addColumns(prob, num_cols);
            
            try testing.expectEqual(@as(c_int, num_rows), glpk.getNumRows(prob));
            try testing.expectEqual(@as(c_int, num_cols), glpk.getNumColumns(prob));
        }
    
    // └──────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Parameter Initialization Tests ────────────────────────────┐
    
        test "unit: Parameters: initialize simplex parameters" {
            var params: glpk.SimplexParams = undefined;
            glpk.initSimplexParams(&params);
            
            // Check some default values are set
            try testing.expect(params.msg_lev >= glpk.GLP_MSG_OFF);
            try testing.expect(params.msg_lev <= glpk.GLP_MSG_DBG);
        }
        
        test "unit: Parameters: initialize interior point parameters" {
            var params: glpk.InteriorParams = undefined;
            glpk.initInteriorParams(&params);
            
            // Just verify it doesn't crash
            try testing.expect(params.msg_lev >= glpk.GLP_MSG_OFF);
            try testing.expect(params.msg_lev <= glpk.GLP_MSG_DBG);
        }
        
        test "unit: Parameters: initialize MIP parameters" {
            var params: glpk.MIPParams = undefined;
            glpk.initMIPParams(&params);
            
            // Just verify it doesn't crash
            try testing.expect(params.msg_lev >= glpk.GLP_MSG_OFF);
            try testing.expect(params.msg_lev <= glpk.GLP_MSG_DBG);
        }
    
    // └──────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Constants Verification Tests ────────────────────────────┐
    
        test "unit: Constants: optimization direction constants are distinct" {
            try testing.expect(glpk.GLP_MIN != glpk.GLP_MAX);
        }
        
        test "unit: Constants: variable bound types are distinct" {
            const bounds = [_]c_int{ 
                glpk.GLP_FR, 
                glpk.GLP_LO, 
                glpk.GLP_UP, 
                glpk.GLP_DB, 
                glpk.GLP_FX 
            };
            
            // Check all bound types are unique
            for (bounds, 0..) |bound1, i| {
                for (bounds[i + 1..]) |bound2| {
                    try testing.expect(bound1 != bound2);
                }
            }
        }
        
        test "unit: Constants: variable kinds are distinct" {
            try testing.expect(glpk.GLP_CV != glpk.GLP_IV);
            try testing.expect(glpk.GLP_CV != glpk.GLP_BV);
            try testing.expect(glpk.GLP_IV != glpk.GLP_BV);
        }
        
        test "unit: Constants: solution status constants are distinct" {
            const statuses = [_]c_int{
                glpk.GLP_UNDEF,
                glpk.GLP_FEAS,
                glpk.GLP_INFEAS,
                glpk.GLP_NOFEAS,
                glpk.GLP_OPT,
                glpk.GLP_UNBND
            };
            
            // Check all status values are unique
            for (statuses, 0..) |status1, i| {
                for (statuses[i + 1..]) |status2| {
                    try testing.expect(status1 != status2);
                }
            }
        }
        
        test "unit: Constants: message levels are distinct" {
            const levels = [_]c_int{
                glpk.GLP_MSG_OFF,
                glpk.GLP_MSG_ERR,
                glpk.GLP_MSG_ON,
                glpk.GLP_MSG_ALL,
                glpk.GLP_MSG_DBG
            };
            
            // Check all message levels are unique
            for (levels, 0..) |level1, i| {
                for (levels[i + 1..]) |level2| {
                    try testing.expect(level1 != level2);
                }
            }
        }
    
    // └──────────────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════╝