// Example demonstrating the proper use of setMatrixRow with GLPK's 1-based indexing
//
// GLPK uses 1-based indexing for arrays, meaning:
// - Array index 0 is unused (dummy element)
// - Actual data starts at index 1
//
// This example shows both approaches:
// 1. Using the original setMatrixRow with 1-based arrays
// 2. Using the safe wrapper safeSetMatrixRow with 0-based arrays

const std = @import("std");

// Note: This example assumes it's built through the build system
// If running standalone, you'll need to adjust the import path
const glpk = @cImport({
    @cInclude("glpk.h");
});

// Import our wrapper functions
const glpk_wrapper = struct {
    const c = glpk;
    
    pub fn createProblem() ?*glpk.glp_prob {
        return glpk.glp_create_prob();
    }
    
    pub fn deleteProblem(prob: ?*glpk.glp_prob) void {
        glpk.glp_delete_prob(prob);
    }
    
    pub fn setProblemName(prob: ?*glpk.glp_prob, name: [*c]const u8) void {
        glpk.glp_set_prob_name(prob, name);
    }
    
    pub fn addRows(prob: ?*glpk.glp_prob, nrs: c_int) c_int {
        return glpk.glp_add_rows(prob, nrs);
    }
    
    pub fn addColumns(prob: ?*glpk.glp_prob, ncs: c_int) c_int {
        return glpk.glp_add_cols(prob, ncs);
    }
    
    pub fn setMatrixRow(prob: ?*glpk.glp_prob, i: c_int, len: c_int, ind: [*c]const c_int, val: [*c]const f64) void {
        glpk.glp_set_mat_row(prob, i, len, ind, val);
    }
    
    /// Safe wrapper for setMatrixRow that handles 0-based array conversion
    pub fn safeSetMatrixRow(
        allocator: std.mem.Allocator,
        prob: ?*glpk.glp_prob,
        i: c_int,
        ind: []const c_int,
        val: []const f64,
    ) !void {
        if (ind.len != val.len) {
            return error.MismatchedArrayLengths;
        }
        
        // Allocate 1-based arrays with space for dummy element at index 0
        const ind_1based = try allocator.alloc(c_int, ind.len + 1);
        defer allocator.free(ind_1based);
        const val_1based = try allocator.alloc(f64, val.len + 1);
        defer allocator.free(val_1based);
        
        // Set dummy element at index 0
        ind_1based[0] = 0;
        val_1based[0] = 0;
        
        // Copy 0-based data to 1-based positions
        for (ind, 0..) |index, k| {
            ind_1based[k + 1] = index;
        }
        for (val, 0..) |value, k| {
            val_1based[k + 1] = value;
        }
        
        // Call the original function with 1-based arrays
        setMatrixRow(prob, i, @intCast(ind.len), ind_1based.ptr, val_1based.ptr);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    std.debug.print("\n=== GLPK Matrix Indexing Example ===\n\n", .{});
    
    // Create a simple linear programming problem
    const prob = glpk_wrapper.createProblem();
    defer glpk_wrapper.deleteProblem(prob);
    
    // Set problem name
    glpk_wrapper.setProblemName(prob, "Matrix Indexing Example");
    
    // Add 2 rows (constraints) and 3 columns (variables)
    const row1 = glpk_wrapper.addRows(prob, 2);
    const col1 = glpk_wrapper.addColumns(prob, 3);
    
    std.debug.print("Created problem with 2 rows and 3 columns\n", .{});
    std.debug.print("Row indices: {d} to {d}\n", .{ row1, row1 + 1 });
    std.debug.print("Column indices: {d} to {d}\n\n", .{ col1, col1 + 2 });
    
    // ========================================
    // Method 1: Original function with 1-based arrays
    // ========================================
    std.debug.print("Method 1: Using original setMatrixRow with 1-based arrays\n", .{});
    std.debug.print("-" ** 50 ++ "\n", .{});
    
    // For row 1, set coefficients: x1=1.0, x2=2.0, x3=3.0
    // IMPORTANT: Arrays must have dummy element at index 0
    var row1_indices_1based = [_]c_int{ 
        0,      // Dummy element (unused)
        col1,   // Column 1
        col1+1, // Column 2
        col1+2  // Column 3
    };
    var row1_values_1based = [_]f64{ 
        0.0,    // Dummy element (unused)
        1.0,    // Coefficient for x1
        2.0,    // Coefficient for x2
        3.0     // Coefficient for x3
    };
    
    // Pass arrays starting from index 0, but GLPK will read from index 1
    glpk_wrapper.setMatrixRow(prob, row1, 3, &row1_indices_1based, &row1_values_1based);
    std.debug.print("Row 1 set: [1.0, 2.0, 3.0]\n", .{});
    
    // For row 2, set sparse coefficients: x1=4.0, x3=5.0 (x2=0)
    var row2_indices_1based = [_]c_int{ 
        0,      // Dummy element (unused)
        col1,   // Column 1
        col1+2  // Column 3 (skip column 2)
    };
    var row2_values_1based = [_]f64{ 
        0.0,    // Dummy element (unused)
        4.0,    // Coefficient for x1
        5.0     // Coefficient for x3
    };
    
    glpk_wrapper.setMatrixRow(prob, row1 + 1, 2, &row2_indices_1based, &row2_values_1based);
    std.debug.print("Row 2 set: [4.0, 0.0, 5.0] (sparse)\n\n", .{});
    
    // ========================================
    // Method 2: Safe wrapper with 0-based arrays
    // ========================================
    std.debug.print("Method 2: Using safeSetMatrixRow with 0-based arrays\n", .{});
    std.debug.print("-" ** 50 ++ "\n", .{});
    
    // Create a new problem to demonstrate
    const prob2 = glpk_wrapper.createProblem();
    defer glpk_wrapper.deleteProblem(prob2);
    
    const row2_1 = glpk_wrapper.addRows(prob2, 2);
    const col2_1 = glpk_wrapper.addColumns(prob2, 3);
    
    // For row 1, same coefficients but using natural 0-based arrays
    const row1_indices_0based = [_]c_int{ col2_1, col2_1+1, col2_1+2 };
    const row1_values_0based = [_]f64{ 1.0, 2.0, 3.0 };
    
    // The safe wrapper handles the conversion to 1-based internally
    try glpk_wrapper.safeSetMatrixRow(allocator, prob2, row2_1, &row1_indices_0based, &row1_values_0based);
    std.debug.print("Row 1 set: [1.0, 2.0, 3.0]\n", .{});
    
    // For row 2, sparse coefficients using 0-based arrays
    const row2_indices_0based = [_]c_int{ col2_1, col2_1+2 };
    const row2_values_0based = [_]f64{ 4.0, 5.0 };
    
    try glpk_wrapper.safeSetMatrixRow(allocator, prob2, row2_1 + 1, &row2_indices_0based, &row2_values_0based);
    std.debug.print("Row 2 set: [4.0, 0.0, 5.0] (sparse)\n\n", .{});
    
    // ========================================
    // Summary
    // ========================================
    std.debug.print("Summary:\n", .{});
    std.debug.print("-" ** 50 ++ "\n", .{});
    std.debug.print("✓ Original setMatrixRow: Requires 1-based arrays with dummy at index 0\n", .{});
    std.debug.print("✓ safeSetMatrixRow: Accepts natural 0-based arrays (recommended)\n", .{});
    std.debug.print("✓ Both methods produce the same constraint matrix\n", .{});
    std.debug.print("\nRecommendation: Use safeSetMatrixRow for Zig code to avoid\n", .{});
    std.debug.print("the confusion and potential errors with 1-based indexing.\n", .{});
}