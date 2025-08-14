// glpk.test.zig — Integration and stress tests for GLPK bindings
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
    
        // Numerical tolerance for floating point comparisons
        const EPSILON = 1e-6;
    
    // └──────────────────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ TEST ══════════════════════════════════════╗

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
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
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
    
    // └──────────────────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════╝