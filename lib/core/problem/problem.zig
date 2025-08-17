// problem.zig — High-level GLPK problem wrapper with RAII semantics
//
// repo   : https://github.com/scoomboot/zig-glpk
// docs   : https://scoomboot.github.io/zig-glpk/lib/core/utils/problem
// author : https://github.com/scoomboot
//
// Vibe coded by Scoom.

// ╔══════════════════════════════════════ PACK ══════════════════════════════════════╗

    const std = @import("std");
    const glpk = @import("../../c/utils/glpk/glpk.zig");
    const types = @import("../types/types.zig");

// ╚══════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ INIT ══════════════════════════════════════╗

    // ┌──────────────────────────── Problem Statistics ────────────────────────────┐
    
        /// Statistics about a problem instance
        pub const ProblemStats = struct {
            /// Number of rows (constraints)
            rows: usize,
            /// Number of columns (variables)
            columns: usize,
            /// Number of non-zero elements in constraint matrix
            non_zeros: usize,
            /// Number of integer variables
            integers: usize,
            /// Number of binary variables
            binaries: usize,
            /// Objective direction
            direction: types.OptimizationDirection,
            /// Problem name (if set)
            name: ?[]const u8,
        };
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Export Format ────────────────────────────┐
    
        /// File format for problem export
        pub const ExportFormat = enum {
            /// CPLEX LP format
            cplex_lp,
            /// MPS format (free format)
            mps_free,
            /// MPS format (fixed format)
            mps_fixed,
            /// GLPK format
            glpk,
        };
    
    // └──────────────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ CORE ══════════════════════════════════════╗

    /// High-level wrapper for GLPK problem with RAII semantics
    pub const Problem = struct {
        /// Allocator for memory management
        allocator: std.mem.Allocator,
        /// Underlying GLPK problem pointer
        ptr: ?*glpk.c.glp_prob,
        /// Optional problem name (owned by this struct)
        name: ?[]u8 = null,
        
        // ┌──────────────────────────── Initialization ────────────────────────────┐
        
            /// Initialize a new problem instance
            ///
            /// __Parameters__
            /// - `allocator`: Memory allocator for managing resources
            ///
            /// __Return__
            /// - A new Problem instance or an error if allocation fails
            pub fn init(allocator: std.mem.Allocator) !Problem {
                const ptr = glpk.createProblem();
                if (ptr == null) {
                    return error.GLPKAllocationFailed;
                }
                
                return Problem{
                    .allocator = allocator,
                    .ptr = ptr,
                    .name = null,
                };
            }
            
            /// Clean up problem instance and free resources
            pub fn deinit(self: *Problem) void {
                // Free the problem name if allocated
                if (self.name) |name| {
                    self.allocator.free(name);
                    self.name = null;
                }
                
                // Delete the GLPK problem
                if (self.ptr) |ptr| {
                    glpk.deleteProblem(ptr);
                    self.ptr = null;
                }
            }
        
        // └──────────────────────────────────────────────────────────────────────────────┘
        
        // ┌──────────────────────────── Basic Properties ────────────────────────────┐
        
            /// Set the problem name
            pub fn setName(self: *Problem, name: []const u8) !void {
                // Free existing name if any
                if (self.name) |old_name| {
                    self.allocator.free(old_name);
                }
                
                // Duplicate the string
                self.name = try self.allocator.dupe(u8, name);
                
                // Create null-terminated string for GLPK
                const c_name = try self.allocator.dupeZ(u8, name);
                defer self.allocator.free(c_name);
                
                glpk.setProblemName(self.ptr, c_name);
            }
            
            /// Set the optimization direction
            pub fn setObjectiveDirection(self: *Problem, direction: types.OptimizationDirection) void {
                glpk.setObjectiveDirection(self.ptr, direction.toGLPK());
            }
            
            /// Get the optimization direction
            pub fn getObjectiveDirection(self: *const Problem) types.OptimizationDirection {
                const dir = glpk.getObjectiveDirection(self.ptr);
                return types.OptimizationDirection.fromGLPK(dir) catch .minimize;
            }
            
            /// Get the number of rows (constraints)
            pub fn getRowCount(self: *const Problem) usize {
                return @intCast(glpk.getNumRows(self.ptr));
            }
            
            /// Get the number of columns (variables)
            pub fn getColumnCount(self: *const Problem) usize {
                return @intCast(glpk.getNumColumns(self.ptr));
            }
            
            /// Get the number of non-zero elements in the constraint matrix
            pub fn getNonZeroCount(self: *const Problem) usize {
                // GLPK doesn't provide a direct function for this
                // We need to count non-zeros by iterating through the matrix
                const rows = glpk.getNumRows(self.ptr);
                var count: usize = 0;
                
                // Count non-zeros in each row
                var i: c_int = 1;
                while (i <= rows) : (i += 1) {
                    const len = glpk.c.glp_get_mat_row(self.ptr, i, null, null);
                    count += @intCast(len);
                }
                
                return count;
            }
        
        // └──────────────────────────────────────────────────────────────────────────────┘
        
        // ┌──────────────────────────── Problem Modification ────────────────────────────┐
        
            /// Clear the problem, removing all rows and columns
            pub fn clear(self: *Problem) void {
                // GLPK has a built-in function to erase the problem content
                glpk.c.glp_erase_prob(self.ptr);
            }
            
            /// Set the objective function name
            pub fn setObjectiveName(self: *Problem, name: []const u8) !void {
                const c_name = try self.allocator.dupeZ(u8, name);
                defer self.allocator.free(c_name);
                
                glpk.c.glp_set_obj_name(self.ptr, c_name);
            }
            
            /// Set the constant term in the objective function
            pub fn setObjectiveConstant(self: *Problem, value: f64) void {
                glpk.setObjectiveCoef(self.ptr, 0, value);
            }
            
            /// Enable or disable terminal output from GLPK
            pub fn setTerminalOutput(self: *Problem, enabled: bool) void {
                _ = self;
                // Control GLPK terminal output
                if (enabled) {
                    _ = glpk.c.glp_term_out(glpk.GLP_ON);
                } else {
                    _ = glpk.c.glp_term_out(glpk.GLP_OFF);
                }
            }
        
        // └──────────────────────────────────────────────────────────────────────────────┘
        
        // ┌──────────────────────────── Utility Functions ────────────────────────────┐
        
            /// Clone the problem to create an independent copy
            pub fn clone(self: *const Problem) !Problem {
                // Create new problem
                var new_prob = try Problem.init(self.allocator);
                errdefer new_prob.deinit();
                
                // Copy the problem using GLPK's copy function
                glpk.c.glp_copy_prob(new_prob.ptr, self.ptr, glpk.GLP_ON);
                
                // Copy the name if present
                if (self.name) |name| {
                    try new_prob.setName(name);
                }
                
                return new_prob;
            }
            
            /// Write the problem to a file in the specified format
            pub fn writeToFile(self: *const Problem, path: []const u8, format: ExportFormat) !void {
                const c_path = try self.allocator.dupeZ(u8, path);
                defer self.allocator.free(c_path);
                
                const result = switch (format) {
                    .cplex_lp => glpk.writeLP(self.ptr, null, c_path),
                    .mps_free => glpk.writeMPS(self.ptr, 1, null, c_path), // GLP_MPS_FILE = 1
                    .mps_fixed => glpk.writeMPS(self.ptr, 2, null, c_path), // GLP_MPS_DECK = 2  
                    .glpk => glpk.c.glp_write_prob(self.ptr, 0, c_path),
                };
                
                if (result != 0) {
                    return error.FileWriteFailed;
                }
            }
            
            /// Get statistics about the problem
            pub fn getStats(self: *const Problem) ProblemStats {
                const rows = glpk.getNumRows(self.ptr);
                const cols = glpk.getNumColumns(self.ptr);
                
                // Count integer and binary variables
                var integers: usize = 0;
                var binaries: usize = 0;
                
                var j: c_int = 1;
                while (j <= cols) : (j += 1) {
                    const kind = glpk.c.glp_get_col_kind(self.ptr, j);
                    switch (kind) {
                        glpk.GLP_IV => integers += 1,
                        glpk.GLP_BV => binaries += 1,
                        else => {},
                    }
                }
                
                return ProblemStats{
                    .rows = @intCast(rows),
                    .columns = @intCast(cols),
                    .non_zeros = self.getNonZeroCount(),
                    .integers = integers,
                    .binaries = binaries,
                    .direction = self.getObjectiveDirection(),
                    .name = self.name,
                };
            }
        
        // └──────────────────────────────────────────────────────────────────────────────┘
    };

// ╚══════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ TEST ══════════════════════════════════════╗

    const testing = std.testing;
    
    // ┌──────────────────────────── Basic Tests ────────────────────────────┐
    
        test "unit: Problem: init and deinit" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            try testing.expect(prob.ptr != null);
            try testing.expectEqual(@as(?[]u8, null), prob.name);
        }
        
        test "unit: Problem: set and get name" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            try prob.setName("Test Problem");
            try testing.expect(prob.name != null);
            try testing.expectEqualStrings("Test Problem", prob.name.?);
        }
        
        test "unit: Problem: set and get objective direction" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            // Default should be minimize
            try testing.expectEqual(types.OptimizationDirection.minimize, prob.getObjectiveDirection());
            
            // Set to maximize
            prob.setObjectiveDirection(.maximize);
            try testing.expectEqual(types.OptimizationDirection.maximize, prob.getObjectiveDirection());
            
            // Set back to minimize
            prob.setObjectiveDirection(.minimize);
            try testing.expectEqual(types.OptimizationDirection.minimize, prob.getObjectiveDirection());
        }
        
        test "unit: Problem: get counts for empty problem" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            try testing.expectEqual(@as(usize, 0), prob.getRowCount());
            try testing.expectEqual(@as(usize, 0), prob.getColumnCount());
            try testing.expectEqual(@as(usize, 0), prob.getNonZeroCount());
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Problem Modification Tests ────────────────────────────┐
    
        test "unit: Problem: clear problem" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            // Add some rows and columns
            _ = glpk.addRows(prob.ptr, 3);
            _ = glpk.addColumns(prob.ptr, 4);
            
            try testing.expectEqual(@as(usize, 3), prob.getRowCount());
            try testing.expectEqual(@as(usize, 4), prob.getColumnCount());
            
            // Clear the problem
            prob.clear();
            
            try testing.expectEqual(@as(usize, 0), prob.getRowCount());
            try testing.expectEqual(@as(usize, 0), prob.getColumnCount());
        }
        
        test "unit: Problem: set objective name and constant" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            try prob.setObjectiveName("Cost");
            prob.setObjectiveConstant(10.5);
            
            // These functions don't have getters in GLPK, but they shouldn't crash
        }
        
        test "unit: Problem: terminal output control" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            // Disable output
            prob.setTerminalOutput(false);
            
            // Enable output
            prob.setTerminalOutput(true);
            
            // Disable again
            prob.setTerminalOutput(false);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Utility Function Tests ────────────────────────────┐
    
        test "unit: Problem: clone problem" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            try prob.setName("Original");
            prob.setObjectiveDirection(.maximize);
            _ = glpk.addRows(prob.ptr, 2);
            _ = glpk.addColumns(prob.ptr, 3);
            
            var cloned = try prob.clone();
            defer cloned.deinit();
            
            // Check that the clone has the same properties
            try testing.expect(cloned.name != null);
            try testing.expectEqualStrings("Original", cloned.name.?);
            try testing.expectEqual(types.OptimizationDirection.maximize, cloned.getObjectiveDirection());
            try testing.expectEqual(@as(usize, 2), cloned.getRowCount());
            try testing.expectEqual(@as(usize, 3), cloned.getColumnCount());
            
            // Verify they are independent
            prob.clear();
            try testing.expectEqual(@as(usize, 0), prob.getRowCount());
            try testing.expectEqual(@as(usize, 2), cloned.getRowCount());
        }
        
        test "unit: Problem: get stats" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            try prob.setName("Stats Test");
            prob.setObjectiveDirection(.maximize);
            
            // Add rows and columns
            _ = glpk.addRows(prob.ptr, 2);
            const col1 = glpk.addColumns(prob.ptr, 3);
            
            // Set column kinds
            glpk.setColumnKind(prob.ptr, col1, glpk.GLP_IV);
            glpk.setColumnKind(prob.ptr, col1 + 1, glpk.GLP_BV);
            glpk.setColumnKind(prob.ptr, col1 + 2, glpk.GLP_CV);
            
            const stats = prob.getStats();
            
            try testing.expectEqual(@as(usize, 2), stats.rows);
            try testing.expectEqual(@as(usize, 3), stats.columns);
            try testing.expectEqual(@as(usize, 1), stats.integers);
            try testing.expectEqual(@as(usize, 1), stats.binaries);
            try testing.expectEqual(types.OptimizationDirection.maximize, stats.direction);
            try testing.expect(stats.name != null);
            try testing.expectEqualStrings("Stats Test", stats.name.?);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── File I/O Tests ────────────────────────────┐
    
        test "integration: Problem: write to file" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            try prob.setName("Export Test");
            _ = glpk.addRows(prob.ptr, 1);
            _ = glpk.addColumns(prob.ptr, 2);
            
            // Create a temporary directory for test files
            var tmp_dir = testing.tmpDir(.{});
            defer tmp_dir.cleanup();
            
            // Get the path properly
            var path_buf: [std.fs.max_path_bytes]u8 = undefined;
            const dir_path = try tmp_dir.dir.realpath(".", &path_buf);
            
            // Test CPLEX LP format
            const lp_path = try std.fmt.allocPrint(testing.allocator, "{s}/test.lp", .{dir_path});
            defer testing.allocator.free(lp_path);
            
            // An empty problem might fail to write, so let's add some constraints
            glpk.setRowBounds(prob.ptr, 1, glpk.GLP_UP, 0.0, 100.0);
            glpk.setColumnBounds(prob.ptr, 1, glpk.GLP_LO, 0.0, 0.0);
            glpk.setColumnBounds(prob.ptr, 2, glpk.GLP_LO, 0.0, 0.0);
            glpk.setObjectiveCoef(prob.ptr, 1, 1.0);
            glpk.setObjectiveCoef(prob.ptr, 2, 1.0);
            
            // Now try to write
            try prob.writeToFile(lp_path, .cplex_lp);
            
            // Verify file was created
            const lp_file = try tmp_dir.dir.openFile("test.lp", .{});
            lp_file.close();
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════╝