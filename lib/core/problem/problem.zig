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

    // ┌──────────────────────────── Row Bounds ────────────────────────────┐
    
        /// Bounds specification for a row (constraint)
        pub const RowBounds = struct {
            /// Type of bounds
            type: types.BoundType,
            /// Lower bound (used for lower, double, and fixed types)
            lower: f64,
            /// Upper bound (used for upper, double, and fixed types)
            upper: f64,
            
            /// Validate that bounds are consistent
            ///
            /// __Return__
            /// - void on success, or error if bounds are invalid
            pub fn validate(self: RowBounds) !void {
                // Check for NaN or infinite values
                if (std.math.isNan(self.lower) or std.math.isInf(self.lower)) {
                    return error.InvalidLowerBound;
                }
                if (std.math.isNan(self.upper) or std.math.isInf(self.upper)) {
                    return error.InvalidUpperBound;
                }
                
                // For double bounds, lower must be <= upper
                if (self.type == .double and self.lower > self.upper) {
                    return error.InvalidBoundRange;
                }
                
                // For fixed bounds, lower must equal upper
                if (self.type == .fixed and self.lower != self.upper) {
                    return error.InconsistentFixedBounds;
                }
            }
        };
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Sparse Vector ────────────────────────────┐
    
        /// Sparse vector representation for row coefficients
        pub const SparseVector = struct {
            /// Column indices (0-based)
            indices: []const usize,
            /// Coefficient values
            values: []const f64,
            /// Allocator used for memory management
            allocator: std.mem.Allocator,
            
            /// Initialize a sparse vector from arrays
            ///
            /// __Parameters__
            /// - `allocator`: Memory allocator
            /// - `indices`: Column indices (will be copied)
            /// - `values`: Coefficient values (will be copied)
            ///
            /// __Return__
            /// - A new SparseVector or allocation error
            pub fn init(allocator: std.mem.Allocator, indices: []const usize, values: []const f64) !SparseVector {
                if (indices.len != values.len) {
                    return error.MismatchedArrayLengths;
                }
                
                return SparseVector{
                    .indices = try allocator.dupe(usize, indices),
                    .values = try allocator.dupe(f64, values),
                    .allocator = allocator,
                };
            }
            
            /// Free allocated memory
            pub fn deinit(self: *SparseVector) void {
                self.allocator.free(self.indices);
                self.allocator.free(self.values);
            }
            
            /// Validate that the sparse vector is well-formed
            ///
            /// __Return__
            /// - void on success, or error if validation fails
            pub fn validate(self: SparseVector) !void {
                // Check for NaN or infinite values
                for (self.values) |val| {
                    if (std.math.isNan(val) or std.math.isInf(val)) {
                        return error.InvalidValue;
                    }
                }
            }
        };
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
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
        
        // ┌──────────────────────────── Row Management ────────────────────────────┐
        
            /// Add multiple rows (constraints) to the problem
            ///
            /// __Parameters__
            /// - `count`: Number of rows to add
            ///
            /// __Return__
            /// - The index of the first added row (0-based) or error
            pub fn addRows(self: *Problem, count: usize) !usize {
                if (count == 0) {
                    return error.InvalidRowCount;
                }
                
                // GLPK returns 1-based index of first added row
                const first_row = glpk.addRows(self.ptr, @intCast(count));
                if (first_row <= 0) {
                    return error.GLPKOperationFailed;
                }
                
                // Convert to 0-based index
                return @intCast(first_row - 1);
            }
            
            /// Add a single row (constraint) to the problem
            ///
            /// __Return__
            /// - The index of the added row (0-based) or error
            pub fn addRow(self: *Problem) !usize {
                return self.addRows(1);
            }
            
            /// Set the name of a row
            ///
            /// __Parameters__
            /// - `row`: Row index (0-based)
            /// - `name`: Name for the row
            pub fn setRowName(self: *Problem, row: usize, name: []const u8) !void {
                const c_name = try self.allocator.dupeZ(u8, name);
                defer self.allocator.free(c_name);
                
                // Convert to 1-based index for GLPK
                glpk.setRowName(self.ptr, @intCast(row + 1), c_name);
            }
            
            /// Set the bounds of a row
            ///
            /// __Parameters__
            /// - `row`: Row index (0-based)
            /// - `bounds`: Bounds specification
            pub fn setRowBounds(self: *Problem, row: usize, bounds: RowBounds) !void {
                try bounds.validate();
                
                // Convert to 1-based index for GLPK
                const row_idx: c_int = @intCast(row + 1);
                const bound_type = bounds.type.toGLPK();
                
                glpk.setRowBounds(self.ptr, row_idx, bound_type, bounds.lower, bounds.upper);
            }
            
            /// Set row bounds with free type (no bounds)
            ///
            /// __Parameters__
            /// - `row`: Row index (0-based)
            pub fn setRowFree(self: *Problem, row: usize) !void {
                try self.setRowBounds(row, .{
                    .type = .free,
                    .lower = 0.0,
                    .upper = 0.0,
                });
            }
            
            /// Set row bounds with lower bound only
            ///
            /// __Parameters__
            /// - `row`: Row index (0-based)
            /// - `lower`: Lower bound value
            pub fn setRowLowerBound(self: *Problem, row: usize, lower: f64) !void {
                try self.setRowBounds(row, .{
                    .type = .lower,
                    .lower = lower,
                    .upper = 0.0,
                });
            }
            
            /// Set row bounds with upper bound only
            ///
            /// __Parameters__
            /// - `row`: Row index (0-based)
            /// - `upper`: Upper bound value
            pub fn setRowUpperBound(self: *Problem, row: usize, upper: f64) !void {
                try self.setRowBounds(row, .{
                    .type = .upper,
                    .lower = 0.0,
                    .upper = upper,
                });
            }
            
            /// Set row bounds with both lower and upper bounds
            ///
            /// __Parameters__
            /// - `row`: Row index (0-based)
            /// - `lower`: Lower bound value
            /// - `upper`: Upper bound value
            pub fn setRowDoubleBound(self: *Problem, row: usize, lower: f64, upper: f64) !void {
                if (lower > upper) {
                    return error.InvalidBoundRange;
                }
                
                try self.setRowBounds(row, .{
                    .type = .double,
                    .lower = lower,
                    .upper = upper,
                });
            }
            
            /// Set row bounds to a fixed value
            ///
            /// __Parameters__
            /// - `row`: Row index (0-based)
            /// - `value`: Fixed value for the row
            pub fn setRowFixed(self: *Problem, row: usize, value: f64) !void {
                try self.setRowBounds(row, .{
                    .type = .fixed,
                    .lower = value,
                    .upper = value,
                });
            }
            
            /// Set coefficients for a row in the constraint matrix
            ///
            /// __Parameters__
            /// - `row`: Row index (0-based)
            /// - `indices`: Column indices (0-based)
            /// - `values`: Coefficient values
            pub fn setRowCoefficients(self: *Problem, row: usize, indices: []const usize, values: []const f64) !void {
                if (indices.len != values.len) {
                    return error.MismatchedArrayLengths;
                }
                
                if (indices.len == 0) {
                    // Clear the row
                    glpk.setMatrixRow(self.ptr, @intCast(row + 1), 0, null, null);
                    return;
                }
                
                // Convert 0-based indices to 1-based for GLPK
                const ind_1based = try self.allocator.alloc(c_int, indices.len + 1);
                defer self.allocator.free(ind_1based);
                const val_1based = try self.allocator.alloc(f64, values.len + 1);
                defer self.allocator.free(val_1based);
                
                // GLPK expects dummy element at index 0
                ind_1based[0] = 0;
                val_1based[0] = 0.0;
                
                for (indices, 0..) |idx, i| {
                    ind_1based[i + 1] = @intCast(idx + 1); // Convert to 1-based
                }
                for (values, 0..) |val, i| {
                    val_1based[i + 1] = val;
                }
                
                glpk.setMatrixRow(self.ptr, @intCast(row + 1), @intCast(indices.len), ind_1based.ptr, val_1based.ptr);
            }
            
            /// Set a single coefficient in the constraint matrix
            ///
            /// __Parameters__
            /// - `row`: Row index (0-based)
            /// - `col`: Column index (0-based)
            /// - `value`: Coefficient value
            pub fn setRowCoefficient(self: *Problem, row: usize, col: usize, value: f64) !void {
                const indices = [_]usize{col};
                const values = [_]f64{value};
                try self.setRowCoefficients(row, &indices, &values);
            }
            
            /// Get the name of a row
            ///
            /// __Parameters__
            /// - `row`: Row index (0-based)
            ///
            /// __Return__
            /// - The row name or null if not set
            pub fn getRowName(self: *const Problem, row: usize) ?[]const u8 {
                const name_ptr = glpk.getRowName(self.ptr, @intCast(row + 1));
                if (name_ptr) |ptr| {
                    return std.mem.span(ptr);
                }
                return null;
            }
            
            /// Get the bounds of a row
            ///
            /// __Parameters__
            /// - `row`: Row index (0-based)
            ///
            /// __Return__
            /// - The row bounds
            pub fn getRowBounds(self: *const Problem, row: usize) !RowBounds {
                const row_idx: c_int = @intCast(row + 1);
                const bound_type = glpk.getRowType(self.ptr, row_idx);
                const lower = glpk.getRowLowerBound(self.ptr, row_idx);
                const upper = glpk.getRowUpperBound(self.ptr, row_idx);
                
                return RowBounds{
                    .type = try types.BoundType.fromGLPK(bound_type),
                    .lower = lower,
                    .upper = upper,
                };
            }
            
            /// Get the coefficients of a row
            ///
            /// __Parameters__
            /// - `row`: Row index (0-based)
            ///
            /// __Return__
            /// - A SparseVector containing the row coefficients
            pub fn getRowCoefficients(self: *const Problem, row: usize) !SparseVector {
                const row_idx: c_int = @intCast(row + 1);
                
                // First, get the number of non-zero elements
                const nnz = glpk.getMatrixRow(self.ptr, row_idx, null, null);
                
                if (nnz == 0) {
                    // Empty row
                    return SparseVector{
                        .indices = &[_]usize{},
                        .values = &[_]f64{},
                        .allocator = self.allocator,
                    };
                }
                
                // Allocate arrays for GLPK (1-based with dummy at index 0)
                const ind_1based = try self.allocator.alloc(c_int, @intCast(nnz + 1));
                defer self.allocator.free(ind_1based);
                const val_1based = try self.allocator.alloc(f64, @intCast(nnz + 1));
                defer self.allocator.free(val_1based);
                
                // Get the actual coefficients
                _ = glpk.getMatrixRow(self.ptr, row_idx, ind_1based.ptr, val_1based.ptr);
                
                // Convert to 0-based arrays
                const indices = try self.allocator.alloc(usize, @intCast(nnz));
                errdefer self.allocator.free(indices);
                const values = try self.allocator.alloc(f64, @intCast(nnz));
                errdefer self.allocator.free(values);
                
                var i: usize = 0;
                while (i < nnz) : (i += 1) {
                    indices[i] = @intCast(ind_1based[i + 1] - 1); // Convert to 0-based
                    values[i] = val_1based[i + 1];
                }
                
                return SparseVector{
                    .indices = indices,
                    .values = values,
                    .allocator = self.allocator,
                };
            }
            
            /// Delete multiple rows from the problem
            ///
            /// __Parameters__
            /// - `rows`: Array of row indices to delete (0-based)
            pub fn deleteRows(self: *Problem, rows: []const usize) !void {
                if (rows.len == 0) {
                    return;
                }
                
                // Convert to 1-based indices for GLPK
                const indices = try self.allocator.alloc(c_int, rows.len + 1);
                defer self.allocator.free(indices);
                
                // GLPK expects dummy element at index 0
                indices[0] = 0;
                
                for (rows, 0..) |row, i| {
                    indices[i + 1] = @intCast(row + 1);
                }
                
                glpk.deleteRows(self.ptr, @intCast(rows.len), indices.ptr);
            }
            
            /// Delete a single row from the problem
            ///
            /// __Parameters__
            /// - `row`: Row index to delete (0-based)
            pub fn deleteRow(self: *Problem, row: usize) !void {
                const rows = [_]usize{row};
                try self.deleteRows(&rows);
            }
        
        // └──────────────────────────────────────────────────────────────────────────────┘
        
        // ┌──────────────────────────── Column Management ────────────────────────────┐
        
            /// Bounds specification for a column (variable)
            pub const ColumnBounds = struct {
                /// Type of bounds
                type: types.BoundType,
                /// Lower bound (used for lower, double, and fixed types)
                lower: f64,
                /// Upper bound (used for upper, double, and fixed types)
                upper: f64,
                
                /// Validate that bounds are consistent
                ///
                /// __Return__
                /// - void on success, or error if bounds are invalid
                pub fn validate(self: ColumnBounds) !void {
                    // Check for NaN or infinite values
                    if (std.math.isNan(self.lower) or std.math.isInf(self.lower)) {
                        return error.InvalidLowerBound;
                    }
                    if (std.math.isNan(self.upper) or std.math.isInf(self.upper)) {
                        return error.InvalidUpperBound;
                    }
                    
                    // For double bounds, lower must be <= upper
                    if (self.type == .double and self.lower > self.upper) {
                        return error.InvalidBoundRange;
                    }
                    
                    // For fixed bounds, lower must equal upper
                    if (self.type == .fixed and self.lower != self.upper) {
                        return error.InconsistentFixedBounds;
                    }
                }
            };
            
            /// Add multiple columns (variables) to the problem
            ///
            /// __Parameters__
            /// - `count`: Number of columns to add
            ///
            /// __Return__
            /// - The index of the first added column (0-based) or error
            pub fn addColumns(self: *Problem, count: usize) !usize {
                if (count == 0) {
                    return error.InvalidColumnCount;
                }
                
                // GLPK returns 1-based index of first added column
                const first_col = glpk.addColumns(self.ptr, @intCast(count));
                if (first_col <= 0) {
                    return error.GLPKOperationFailed;
                }
                
                // Convert to 0-based index
                return @intCast(first_col - 1);
            }
            
            /// Add a single column (variable) to the problem
            ///
            /// __Return__
            /// - The index of the added column (0-based) or error
            pub fn addColumn(self: *Problem) !usize {
                return self.addColumns(1);
            }
            
            /// Set the name of a column
            ///
            /// __Parameters__
            /// - `col`: Column index (0-based)
            /// - `name`: Name for the column
            pub fn setColumnName(self: *Problem, col: usize, name: []const u8) !void {
                const c_name = try self.allocator.dupeZ(u8, name);
                defer self.allocator.free(c_name);
                
                // Convert to 1-based index for GLPK
                glpk.setColumnName(self.ptr, @intCast(col + 1), c_name);
            }
            
            /// Set the bounds of a column
            ///
            /// __Parameters__
            /// - `col`: Column index (0-based)
            /// - `bounds`: Bounds specification
            pub fn setColumnBounds(self: *Problem, col: usize, bounds: ColumnBounds) !void {
                try bounds.validate();
                
                // Convert to 1-based index for GLPK
                const col_idx: c_int = @intCast(col + 1);
                const bound_type = bounds.type.toGLPK();
                
                glpk.setColumnBounds(self.ptr, col_idx, bound_type, bounds.lower, bounds.upper);
            }
            
            /// Set column bounds with lower bound only
            ///
            /// __Parameters__
            /// - `col`: Column index (0-based)
            /// - `lb`: Lower bound value
            pub fn setColumnLowerBound(self: *Problem, col: usize, lb: f64) !void {
                try self.setColumnBounds(col, .{
                    .type = .lower,
                    .lower = lb,
                    .upper = 0.0,
                });
            }
            
            /// Set column bounds with upper bound only
            ///
            /// __Parameters__
            /// - `col`: Column index (0-based)
            /// - `ub`: Upper bound value
            pub fn setColumnUpperBound(self: *Problem, col: usize, ub: f64) !void {
                try self.setColumnBounds(col, .{
                    .type = .upper,
                    .lower = 0.0,
                    .upper = ub,
                });
            }
            
            /// Set column bounds with both lower and upper bounds
            ///
            /// __Parameters__
            /// - `col`: Column index (0-based)
            /// - `lb`: Lower bound value
            /// - `ub`: Upper bound value
            pub fn setColumnRangeBounds(self: *Problem, col: usize, lb: f64, ub: f64) !void {
                if (lb > ub) {
                    return error.InvalidBoundRange;
                }
                
                try self.setColumnBounds(col, .{
                    .type = .double,
                    .lower = lb,
                    .upper = ub,
                });
            }
            
            /// Set column bounds to a fixed value
            ///
            /// __Parameters__
            /// - `col`: Column index (0-based)
            /// - `value`: Fixed value for the column
            pub fn setColumnFixed(self: *Problem, col: usize, value: f64) !void {
                try self.setColumnBounds(col, .{
                    .type = .fixed,
                    .lower = value,
                    .upper = value,
                });
            }
            
            /// Set column bounds with free type (no bounds)
            ///
            /// __Parameters__
            /// - `col`: Column index (0-based)
            pub fn setColumnFree(self: *Problem, col: usize) !void {
                try self.setColumnBounds(col, .{
                    .type = .free,
                    .lower = 0.0,
                    .upper = 0.0,
                });
            }
            
            /// Set objective coefficient for a column
            ///
            /// __Parameters__
            /// - `col`: Column index (0-based)
            /// - `coef`: Coefficient value
            pub fn setObjectiveCoefficient(self: *Problem, col: usize, coef: f64) void {
                // Convert to 1-based index for GLPK
                glpk.setObjectiveCoef(self.ptr, @intCast(col + 1), coef);
            }
            
            /// Set objective coefficients for multiple columns
            ///
            /// __Parameters__
            /// - `cols`: Column indices (0-based)
            /// - `coefs`: Coefficient values
            pub fn setObjectiveCoefficients(self: *Problem, cols: []const usize, coefs: []const f64) !void {
                if (cols.len != coefs.len) {
                    return error.MismatchedArrayLengths;
                }
                
                for (cols, coefs) |col, coef| {
                    self.setObjectiveCoefficient(col, coef);
                }
            }
            
            /// Get objective coefficient for a column
            ///
            /// __Parameters__
            /// - `col`: Column index (0-based)
            ///
            /// __Return__
            /// - The objective coefficient value
            pub fn getObjectiveCoefficient(self: *const Problem, col: usize) f64 {
                // Convert to 1-based index for GLPK
                return glpk.getObjectiveCoef(self.ptr, @intCast(col + 1));
            }
            
            /// Set coefficients for a column in the constraint matrix
            ///
            /// __Parameters__
            /// - `col`: Column index (0-based)
            /// - `rows`: Row indices (0-based)
            /// - `values`: Coefficient values
            pub fn setColumnCoefficients(self: *Problem, col: usize, rows: []const usize, values: []const f64) !void {
                if (rows.len != values.len) {
                    return error.MismatchedArrayLengths;
                }
                
                if (rows.len == 0) {
                    // Clear the column
                    glpk.setMatrixCol(self.ptr, @intCast(col + 1), 0, null, null);
                    return;
                }
                
                // Convert 0-based indices to 1-based for GLPK
                const ind_1based = try self.allocator.alloc(c_int, rows.len + 1);
                defer self.allocator.free(ind_1based);
                const val_1based = try self.allocator.alloc(f64, values.len + 1);
                defer self.allocator.free(val_1based);
                
                // GLPK expects dummy element at index 0
                ind_1based[0] = 0;
                val_1based[0] = 0.0;
                
                for (rows, 0..) |row, i| {
                    ind_1based[i + 1] = @intCast(row + 1); // Convert to 1-based
                }
                for (values, 0..) |val, i| {
                    val_1based[i + 1] = val;
                }
                
                glpk.setMatrixCol(self.ptr, @intCast(col + 1), @intCast(rows.len), ind_1based.ptr, val_1based.ptr);
            }
            
            /// Set a single coefficient in the constraint matrix
            ///
            /// __Parameters__
            /// - `col`: Column index (0-based)
            /// - `row`: Row index (0-based)
            /// - `value`: Coefficient value
            pub fn setColumnCoefficient(self: *Problem, col: usize, row: usize, value: f64) !void {
                const rows = [_]usize{row};
                const values = [_]f64{value};
                try self.setColumnCoefficients(col, &rows, &values);
            }
            
            /// Set the kind of a column (continuous, integer, or binary)
            ///
            /// __Parameters__
            /// - `col`: Column index (0-based)
            /// - `kind`: Variable kind
            pub fn setColumnKind(self: *Problem, col: usize, kind: types.VariableKind) void {
                // Convert to 1-based index for GLPK
                glpk.setColumnKind(self.ptr, @intCast(col + 1), kind.toGLPK());
            }
            
            /// Set column as continuous variable
            ///
            /// __Parameters__
            /// - `col`: Column index (0-based)
            pub fn setColumnContinuous(self: *Problem, col: usize) void {
                self.setColumnKind(col, .continuous);
            }
            
            /// Set column as integer variable
            ///
            /// __Parameters__
            /// - `col`: Column index (0-based)
            pub fn setColumnInteger(self: *Problem, col: usize) void {
                self.setColumnKind(col, .integer);
            }
            
            /// Set column as binary variable (also sets bounds to [0,1])
            ///
            /// __Parameters__
            /// - `col`: Column index (0-based)
            pub fn setColumnBinary(self: *Problem, col: usize) !void {
                self.setColumnKind(col, .binary);
                // Binary variables should have bounds [0, 1]
                try self.setColumnRangeBounds(col, 0.0, 1.0);
            }
            
            /// Get the name of a column
            ///
            /// __Parameters__
            /// - `col`: Column index (0-based)
            ///
            /// __Return__
            /// - The column name or null if not set
            pub fn getColumnName(self: *const Problem, col: usize) ?[]const u8 {
                const name_ptr = glpk.getColumnName(self.ptr, @intCast(col + 1));
                if (name_ptr) |ptr| {
                    return std.mem.span(ptr);
                }
                return null;
            }
            
            /// Get the bounds of a column
            ///
            /// __Parameters__
            /// - `col`: Column index (0-based)
            ///
            /// __Return__
            /// - The column bounds
            pub fn getColumnBounds(self: *const Problem, col: usize) !ColumnBounds {
                const col_idx: c_int = @intCast(col + 1);
                const bound_type = glpk.getColumnType(self.ptr, col_idx);
                const lower = glpk.getColumnLowerBound(self.ptr, col_idx);
                const upper = glpk.getColumnUpperBound(self.ptr, col_idx);
                
                return ColumnBounds{
                    .type = try types.BoundType.fromGLPK(bound_type),
                    .lower = lower,
                    .upper = upper,
                };
            }
            
            /// Get the coefficients of a column
            ///
            /// __Parameters__
            /// - `col`: Column index (0-based)
            ///
            /// __Return__
            /// - A SparseVector containing the column coefficients
            pub fn getColumnCoefficients(self: *const Problem, col: usize) !SparseVector {
                const col_idx: c_int = @intCast(col + 1);
                
                // First, get the number of non-zero elements
                const nnz = glpk.getMatrixCol(self.ptr, col_idx, null, null);
                
                if (nnz == 0) {
                    // Empty column
                    return SparseVector{
                        .indices = &[_]usize{},
                        .values = &[_]f64{},
                        .allocator = self.allocator,
                    };
                }
                
                // Allocate arrays for GLPK (1-based with dummy at index 0)
                const ind_1based = try self.allocator.alloc(c_int, @intCast(nnz + 1));
                defer self.allocator.free(ind_1based);
                const val_1based = try self.allocator.alloc(f64, @intCast(nnz + 1));
                defer self.allocator.free(val_1based);
                
                // Get the actual coefficients
                _ = glpk.getMatrixCol(self.ptr, col_idx, ind_1based.ptr, val_1based.ptr);
                
                // Convert to 0-based arrays
                const indices = try self.allocator.alloc(usize, @intCast(nnz));
                errdefer self.allocator.free(indices);
                const values = try self.allocator.alloc(f64, @intCast(nnz));
                errdefer self.allocator.free(values);
                
                var i: usize = 0;
                while (i < nnz) : (i += 1) {
                    indices[i] = @intCast(ind_1based[i + 1] - 1); // Convert to 0-based
                    values[i] = val_1based[i + 1];
                }
                
                return SparseVector{
                    .indices = indices,
                    .values = values,
                    .allocator = self.allocator,
                };
            }
            
            /// Get the kind of a column
            ///
            /// __Parameters__
            /// - `col`: Column index (0-based)
            ///
            /// __Return__
            /// - The variable kind
            pub fn getColumnKind(self: *const Problem, col: usize) types.VariableKind {
                const col_idx: c_int = @intCast(col + 1);
                const kind = glpk.getColumnKind(self.ptr, col_idx);
                return types.VariableKind.fromGLPK(kind) catch .continuous;
            }
            
            /// Delete multiple columns from the problem
            ///
            /// __Parameters__
            /// - `cols`: Array of column indices to delete (0-based)
            pub fn deleteColumns(self: *Problem, cols: []const usize) !void {
                if (cols.len == 0) {
                    return;
                }
                
                // Convert to 1-based indices for GLPK
                const indices = try self.allocator.alloc(c_int, cols.len + 1);
                defer self.allocator.free(indices);
                
                // GLPK expects dummy element at index 0
                indices[0] = 0;
                
                for (cols, 0..) |col, i| {
                    indices[i + 1] = @intCast(col + 1);
                }
                
                glpk.deleteColumns(self.ptr, @intCast(cols.len), indices.ptr);
            }
            
            /// Delete a single column from the problem
            ///
            /// __Parameters__
            /// - `col`: Column index to delete (0-based)
            pub fn deleteColumn(self: *Problem, col: usize) !void {
                const cols = [_]usize{col};
                try self.deleteColumns(&cols);
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
    
    // ┌──────────────────────────── Row Management Tests ────────────────────────────┐
    
        test "unit: Problem: add and count rows" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            // Initially should have 0 rows
            try testing.expectEqual(@as(usize, 0), prob.getRowCount());
            
            // Add single row
            const row1 = try prob.addRow();
            try testing.expectEqual(@as(usize, 0), row1);
            try testing.expectEqual(@as(usize, 1), prob.getRowCount());
            
            // Add multiple rows
            const first_row = try prob.addRows(3);
            try testing.expectEqual(@as(usize, 1), first_row);
            try testing.expectEqual(@as(usize, 4), prob.getRowCount());
        }
        
        test "unit: Problem: set and get row name" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            const row = try prob.addRow();
            
            // Initially no name
            try testing.expect(prob.getRowName(row) == null);
            
            // Set name
            try prob.setRowName(row, "constraint_1");
            
            // Get name
            const name = prob.getRowName(row);
            try testing.expect(name != null);
            try testing.expectEqualStrings("constraint_1", name.?);
        }
        
        test "unit: Problem: set and get row bounds" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            const row = try prob.addRow();
            
            // Test free bounds
            try prob.setRowFree(row);
            const free_bounds = try prob.getRowBounds(row);
            try testing.expectEqual(types.BoundType.free, free_bounds.type);
            
            // Test lower bound
            try prob.setRowLowerBound(row, 5.0);
            const lower_bounds = try prob.getRowBounds(row);
            try testing.expectEqual(types.BoundType.lower, lower_bounds.type);
            try testing.expectApproxEqAbs(@as(f64, 5.0), lower_bounds.lower, 1e-10);
            
            // Test upper bound
            try prob.setRowUpperBound(row, 10.0);
            const upper_bounds = try prob.getRowBounds(row);
            try testing.expectEqual(types.BoundType.upper, upper_bounds.type);
            try testing.expectApproxEqAbs(@as(f64, 10.0), upper_bounds.upper, 1e-10);
            
            // Test double bounds
            try prob.setRowDoubleBound(row, 2.0, 8.0);
            const double_bounds = try prob.getRowBounds(row);
            try testing.expectEqual(types.BoundType.double, double_bounds.type);
            try testing.expectApproxEqAbs(@as(f64, 2.0), double_bounds.lower, 1e-10);
            try testing.expectApproxEqAbs(@as(f64, 8.0), double_bounds.upper, 1e-10);
            
            // Test fixed bounds
            try prob.setRowFixed(row, 7.5);
            const fixed_bounds = try prob.getRowBounds(row);
            try testing.expectEqual(types.BoundType.fixed, fixed_bounds.type);
            try testing.expectApproxEqAbs(@as(f64, 7.5), fixed_bounds.lower, 1e-10);
            try testing.expectApproxEqAbs(@as(f64, 7.5), fixed_bounds.upper, 1e-10);
        }
        
        test "unit: Problem: invalid row bounds" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            const row = try prob.addRow();
            
            // Lower > upper should fail
            try testing.expectError(error.InvalidBoundRange, prob.setRowDoubleBound(row, 10.0, 5.0));
        }
        
        test "unit: Problem: set and get row coefficients" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            // Add row and columns
            const row = try prob.addRow();
            _ = glpk.addColumns(prob.ptr, 5);
            
            // Set coefficients
            const indices = [_]usize{ 0, 2, 4 };
            const values = [_]f64{ 1.5, -2.0, 3.5 };
            try prob.setRowCoefficients(row, &indices, &values);
            
            // Get coefficients
            var coeffs = try prob.getRowCoefficients(row);
            defer coeffs.deinit();
            
            try testing.expectEqual(@as(usize, 3), coeffs.indices.len);
            try testing.expectEqual(@as(usize, 3), coeffs.values.len);
            
            // Check values (note: order might not be preserved)
            for (coeffs.indices, coeffs.values) |idx, val| {
                if (idx == 0) {
                    try testing.expectApproxEqAbs(@as(f64, 1.5), val, 1e-10);
                } else if (idx == 2) {
                    try testing.expectApproxEqAbs(@as(f64, -2.0), val, 1e-10);
                } else if (idx == 4) {
                    try testing.expectApproxEqAbs(@as(f64, 3.5), val, 1e-10);
                } else {
                    try testing.expect(false);
                }
            }
        }
        
        test "unit: Problem: set single row coefficient" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            const row = try prob.addRow();
            _ = glpk.addColumns(prob.ptr, 3);
            
            // Set single coefficient
            try prob.setRowCoefficient(row, 1, 2.5);
            
            // Get coefficients
            var coeffs = try prob.getRowCoefficients(row);
            defer coeffs.deinit();
            
            try testing.expectEqual(@as(usize, 1), coeffs.indices.len);
            try testing.expectEqual(@as(usize, 1), coeffs.indices[0]);
            try testing.expectApproxEqAbs(@as(f64, 2.5), coeffs.values[0], 1e-10);
        }
        
        test "unit: Problem: empty row coefficients" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            const row = try prob.addRow();
            
            // Get coefficients from empty row
            var coeffs = try prob.getRowCoefficients(row);
            defer coeffs.deinit();
            
            try testing.expectEqual(@as(usize, 0), coeffs.indices.len);
            try testing.expectEqual(@as(usize, 0), coeffs.values.len);
        }
        
        test "unit: Problem: delete rows" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            // Add 5 rows
            _ = try prob.addRows(5);
            try testing.expectEqual(@as(usize, 5), prob.getRowCount());
            
            // Delete single row
            try prob.deleteRow(2);
            try testing.expectEqual(@as(usize, 4), prob.getRowCount());
            
            // Delete multiple rows
            // Note: After deleting row 2, indices shift
            const rows_to_delete = [_]usize{ 0, 2 };
            try prob.deleteRows(&rows_to_delete);
            try testing.expectEqual(@as(usize, 2), prob.getRowCount());
        }
        
        test "unit: RowBounds: validation" {
            // Valid free bounds
            const free = RowBounds{ .type = .free, .lower = 0, .upper = 0 };
            try free.validate();
            
            // Valid double bounds
            const double = RowBounds{ .type = .double, .lower = 1, .upper = 10 };
            try double.validate();
            
            // Invalid double bounds (lower > upper)
            const invalid_double = RowBounds{ .type = .double, .lower = 10, .upper = 1 };
            try testing.expectError(error.InvalidBoundRange, invalid_double.validate());
            
            // Valid fixed bounds
            const fixed = RowBounds{ .type = .fixed, .lower = 5, .upper = 5 };
            try fixed.validate();
            
            // Invalid fixed bounds (lower != upper)
            const invalid_fixed = RowBounds{ .type = .fixed, .lower = 5, .upper = 6 };
            try testing.expectError(error.InconsistentFixedBounds, invalid_fixed.validate());
            
            // Invalid NaN bounds
            const nan_bounds = RowBounds{ .type = .lower, .lower = std.math.nan(f64), .upper = 0 };
            try testing.expectError(error.InvalidLowerBound, nan_bounds.validate());
            
            // Invalid infinite bounds
            const inf_bounds = RowBounds{ .type = .upper, .lower = 0, .upper = std.math.inf(f64) };
            try testing.expectError(error.InvalidUpperBound, inf_bounds.validate());
        }
        
        test "unit: SparseVector: initialization and validation" {
            const indices = [_]usize{ 0, 3, 5 };
            const values = [_]f64{ 1.0, -2.5, 3.7 };
            
            var vec = try SparseVector.init(testing.allocator, &indices, &values);
            defer vec.deinit();
            
            try testing.expectEqual(@as(usize, 3), vec.indices.len);
            try testing.expectEqual(@as(usize, 3), vec.values.len);
            
            // Validate should pass
            try vec.validate();
            
            // Test with mismatched lengths
            const bad_values = [_]f64{ 1.0, 2.0 };
            try testing.expectError(
                error.MismatchedArrayLengths,
                SparseVector.init(testing.allocator, &indices, &bad_values)
            );
        }
        
        test "integration: Problem: complete row workflow" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            // Create a problem with 3 rows and 4 columns
            _ = try prob.addRows(3);
            _ = glpk.addColumns(prob.ptr, 4);
            
            // Configure row 0: 2x₁ + 3x₂ - x₃ ≤ 10
            try prob.setRowName(0, "capacity");
            try prob.setRowUpperBound(0, 10.0);
            const row0_indices = [_]usize{ 0, 1, 2 };
            const row0_values = [_]f64{ 2.0, 3.0, -1.0 };
            try prob.setRowCoefficients(0, &row0_indices, &row0_values);
            
            // Configure row 1: x₁ + x₄ = 5
            try prob.setRowName(1, "balance");
            try prob.setRowFixed(1, 5.0);
            const row1_indices = [_]usize{ 0, 3 };
            const row1_values = [_]f64{ 1.0, 1.0 };
            try prob.setRowCoefficients(1, &row1_indices, &row1_values);
            
            // Configure row 2: x₂ + 2x₃ ≥ 3
            try prob.setRowName(2, "minimum");
            try prob.setRowLowerBound(2, 3.0);
            const row2_indices = [_]usize{ 1, 2 };
            const row2_values = [_]f64{ 1.0, 2.0 };
            try prob.setRowCoefficients(2, &row2_indices, &row2_values);
            
            // Verify configuration
            try testing.expectEqual(@as(usize, 3), prob.getRowCount());
            
            // Check row 0
            const name0 = prob.getRowName(0);
            try testing.expect(name0 != null);
            try testing.expectEqualStrings("capacity", name0.?);
            
            const bounds0 = try prob.getRowBounds(0);
            try testing.expectEqual(types.BoundType.upper, bounds0.type);
            try testing.expectApproxEqAbs(@as(f64, 10.0), bounds0.upper, 1e-10);
            
            var coeffs0 = try prob.getRowCoefficients(0);
            defer coeffs0.deinit();
            try testing.expectEqual(@as(usize, 3), coeffs0.indices.len);
            
            // Check row 1
            const name1 = prob.getRowName(1);
            try testing.expect(name1 != null);
            try testing.expectEqualStrings("balance", name1.?);
            
            const bounds1 = try prob.getRowBounds(1);
            try testing.expectEqual(types.BoundType.fixed, bounds1.type);
            try testing.expectApproxEqAbs(@as(f64, 5.0), bounds1.lower, 1e-10);
            
            var coeffs1 = try prob.getRowCoefficients(1);
            defer coeffs1.deinit();
            try testing.expectEqual(@as(usize, 2), coeffs1.indices.len);
            
            // Delete row 0 and verify
            try prob.deleteRow(0);
            try testing.expectEqual(@as(usize, 2), prob.getRowCount());
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Column Management Tests ────────────────────────────┐
    
        test "unit: Problem: add and count columns" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            // Initially should have 0 columns
            try testing.expectEqual(@as(usize, 0), prob.getColumnCount());
            
            // Add single column
            const col1 = try prob.addColumn();
            try testing.expectEqual(@as(usize, 0), col1);
            try testing.expectEqual(@as(usize, 1), prob.getColumnCount());
            
            // Add multiple columns
            const first_col = try prob.addColumns(3);
            try testing.expectEqual(@as(usize, 1), first_col);
            try testing.expectEqual(@as(usize, 4), prob.getColumnCount());
        }
        
        test "unit: Problem: set and get column name" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            const col = try prob.addColumn();
            
            // Initially no name
            try testing.expect(prob.getColumnName(col) == null);
            
            // Set name
            try prob.setColumnName(col, "variable_x");
            
            // Get name
            const name = prob.getColumnName(col);
            try testing.expect(name != null);
            try testing.expectEqualStrings("variable_x", name.?);
        }
        
        test "unit: Problem: set and get column bounds" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            const col = try prob.addColumn();
            
            // Test free bounds
            try prob.setColumnFree(col);
            const free_bounds = try prob.getColumnBounds(col);
            try testing.expectEqual(types.BoundType.free, free_bounds.type);
            
            // Test lower bound
            try prob.setColumnLowerBound(col, 2.5);
            const lower_bounds = try prob.getColumnBounds(col);
            try testing.expectEqual(types.BoundType.lower, lower_bounds.type);
            try testing.expectApproxEqAbs(@as(f64, 2.5), lower_bounds.lower, 1e-10);
            
            // Test upper bound
            try prob.setColumnUpperBound(col, 15.0);
            const upper_bounds = try prob.getColumnBounds(col);
            try testing.expectEqual(types.BoundType.upper, upper_bounds.type);
            try testing.expectApproxEqAbs(@as(f64, 15.0), upper_bounds.upper, 1e-10);
            
            // Test range bounds
            try prob.setColumnRangeBounds(col, 1.0, 10.0);
            const range_bounds = try prob.getColumnBounds(col);
            try testing.expectEqual(types.BoundType.double, range_bounds.type);
            try testing.expectApproxEqAbs(@as(f64, 1.0), range_bounds.lower, 1e-10);
            try testing.expectApproxEqAbs(@as(f64, 10.0), range_bounds.upper, 1e-10);
            
            // Test fixed bounds
            try prob.setColumnFixed(col, 5.5);
            const fixed_bounds = try prob.getColumnBounds(col);
            try testing.expectEqual(types.BoundType.fixed, fixed_bounds.type);
            try testing.expectApproxEqAbs(@as(f64, 5.5), fixed_bounds.lower, 1e-10);
            try testing.expectApproxEqAbs(@as(f64, 5.5), fixed_bounds.upper, 1e-10);
        }
        
        test "unit: Problem: invalid column bounds" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            const col = try prob.addColumn();
            
            // Lower > upper should fail
            try testing.expectError(error.InvalidBoundRange, prob.setColumnRangeBounds(col, 10.0, 5.0));
        }
        
        test "unit: Problem: set and get objective coefficients" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            // Add columns
            _ = try prob.addColumns(3);
            
            // Initially should be 0
            try testing.expectApproxEqAbs(@as(f64, 0.0), prob.getObjectiveCoefficient(0), 1e-10);
            try testing.expectApproxEqAbs(@as(f64, 0.0), prob.getObjectiveCoefficient(1), 1e-10);
            
            // Set single coefficient
            prob.setObjectiveCoefficient(0, 3.5);
            try testing.expectApproxEqAbs(@as(f64, 3.5), prob.getObjectiveCoefficient(0), 1e-10);
            
            // Set multiple coefficients
            const cols = [_]usize{ 1, 2 };
            const coefs = [_]f64{ -2.0, 4.5 };
            try prob.setObjectiveCoefficients(&cols, &coefs);
            
            try testing.expectApproxEqAbs(@as(f64, -2.0), prob.getObjectiveCoefficient(1), 1e-10);
            try testing.expectApproxEqAbs(@as(f64, 4.5), prob.getObjectiveCoefficient(2), 1e-10);
        }
        
        test "unit: Problem: set and get column coefficients" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            // Add columns and rows
            const col = try prob.addColumn();
            _ = try prob.addRows(5);
            
            // Set coefficients
            const rows = [_]usize{ 0, 2, 4 };
            const values = [_]f64{ 1.5, -2.0, 3.5 };
            try prob.setColumnCoefficients(col, &rows, &values);
            
            // Get coefficients
            var coeffs = try prob.getColumnCoefficients(col);
            defer coeffs.deinit();
            
            try testing.expectEqual(@as(usize, 3), coeffs.indices.len);
            try testing.expectEqual(@as(usize, 3), coeffs.values.len);
            
            // Check values (note: order might not be preserved)
            for (coeffs.indices, coeffs.values) |idx, val| {
                if (idx == 0) {
                    try testing.expectApproxEqAbs(@as(f64, 1.5), val, 1e-10);
                } else if (idx == 2) {
                    try testing.expectApproxEqAbs(@as(f64, -2.0), val, 1e-10);
                } else if (idx == 4) {
                    try testing.expectApproxEqAbs(@as(f64, 3.5), val, 1e-10);
                } else {
                    try testing.expect(false);
                }
            }
        }
        
        test "unit: Problem: set single column coefficient" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            const col = try prob.addColumn();
            _ = try prob.addRows(3);
            
            // Set single coefficient
            try prob.setColumnCoefficient(col, 1, 2.5);
            
            // Get coefficients
            var coeffs = try prob.getColumnCoefficients(col);
            defer coeffs.deinit();
            
            try testing.expectEqual(@as(usize, 1), coeffs.indices.len);
            try testing.expectEqual(@as(usize, 1), coeffs.indices[0]);
            try testing.expectApproxEqAbs(@as(f64, 2.5), coeffs.values[0], 1e-10);
        }
        
        test "unit: Problem: empty column coefficients" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            const col = try prob.addColumn();
            
            // Get coefficients from empty column
            var coeffs = try prob.getColumnCoefficients(col);
            defer coeffs.deinit();
            
            try testing.expectEqual(@as(usize, 0), coeffs.indices.len);
            try testing.expectEqual(@as(usize, 0), coeffs.values.len);
        }
        
        test "unit: Problem: column kinds" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            // Add columns
            _ = try prob.addColumns(3);
            
            // Default should be continuous
            try testing.expectEqual(types.VariableKind.continuous, prob.getColumnKind(0));
            
            // Set as integer
            prob.setColumnInteger(0);
            try testing.expectEqual(types.VariableKind.integer, prob.getColumnKind(0));
            
            // Set as continuous
            prob.setColumnContinuous(0);
            try testing.expectEqual(types.VariableKind.continuous, prob.getColumnKind(0));
            
            // Set as binary (should also set bounds)
            try prob.setColumnBinary(1);
            try testing.expectEqual(types.VariableKind.binary, prob.getColumnKind(1));
            
            // Check that binary bounds were set
            const binary_bounds = try prob.getColumnBounds(1);
            try testing.expectEqual(types.BoundType.double, binary_bounds.type);
            try testing.expectApproxEqAbs(@as(f64, 0.0), binary_bounds.lower, 1e-10);
            try testing.expectApproxEqAbs(@as(f64, 1.0), binary_bounds.upper, 1e-10);
            
            // Set kind directly
            prob.setColumnKind(2, .integer);
            try testing.expectEqual(types.VariableKind.integer, prob.getColumnKind(2));
        }
        
        test "unit: Problem: delete columns" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            // Add 5 columns
            _ = try prob.addColumns(5);
            try testing.expectEqual(@as(usize, 5), prob.getColumnCount());
            
            // Delete single column
            try prob.deleteColumn(2);
            try testing.expectEqual(@as(usize, 4), prob.getColumnCount());
            
            // Delete multiple columns
            // Note: After deleting column 2, indices shift
            const cols_to_delete = [_]usize{ 0, 2 };
            try prob.deleteColumns(&cols_to_delete);
            try testing.expectEqual(@as(usize, 2), prob.getColumnCount());
        }
        
        test "unit: ColumnBounds: validation" {
            // Valid free bounds
            const free = Problem.ColumnBounds{ .type = .free, .lower = 0, .upper = 0 };
            try free.validate();
            
            // Valid double bounds
            const double = Problem.ColumnBounds{ .type = .double, .lower = 1, .upper = 10 };
            try double.validate();
            
            // Invalid double bounds (lower > upper)
            const invalid_double = Problem.ColumnBounds{ .type = .double, .lower = 10, .upper = 1 };
            try testing.expectError(error.InvalidBoundRange, invalid_double.validate());
            
            // Valid fixed bounds
            const fixed = Problem.ColumnBounds{ .type = .fixed, .lower = 5, .upper = 5 };
            try fixed.validate();
            
            // Invalid fixed bounds (lower != upper)
            const invalid_fixed = Problem.ColumnBounds{ .type = .fixed, .lower = 5, .upper = 6 };
            try testing.expectError(error.InconsistentFixedBounds, invalid_fixed.validate());
            
            // Invalid NaN bounds
            const nan_bounds = Problem.ColumnBounds{ .type = .lower, .lower = std.math.nan(f64), .upper = 0 };
            try testing.expectError(error.InvalidLowerBound, nan_bounds.validate());
            
            // Invalid infinite bounds
            const inf_bounds = Problem.ColumnBounds{ .type = .upper, .lower = 0, .upper = std.math.inf(f64) };
            try testing.expectError(error.InvalidUpperBound, inf_bounds.validate());
        }
        
        test "integration: Problem: complete column workflow" {
            var prob = try Problem.init(testing.allocator);
            defer prob.deinit();
            
            // Create a problem with 4 columns and 3 rows
            _ = try prob.addColumns(4);
            _ = try prob.addRows(3);
            
            // Configure column 0: x₁ ≥ 0
            try prob.setColumnName(0, "x1");
            try prob.setColumnLowerBound(0, 0.0);
            prob.setObjectiveCoefficient(0, 3.0);
            const col0_rows = [_]usize{ 0, 1 };
            const col0_values = [_]f64{ 2.0, 1.0 };
            try prob.setColumnCoefficients(0, &col0_rows, &col0_values);
            
            // Configure column 1: x₂ ∈ [0, 10]
            try prob.setColumnName(1, "x2");
            try prob.setColumnRangeBounds(1, 0.0, 10.0);
            prob.setObjectiveCoefficient(1, 5.0);
            const col1_rows = [_]usize{ 0, 2 };
            const col1_values = [_]f64{ 3.0, 1.0 };
            try prob.setColumnCoefficients(1, &col1_rows, &col1_values);
            
            // Configure column 2: x₃ binary
            try prob.setColumnName(2, "x3");
            try prob.setColumnBinary(2);
            prob.setObjectiveCoefficient(2, -2.0);
            const col2_rows = [_]usize{ 0, 1, 2 };
            const col2_values = [_]f64{ -1.0, 1.0, 2.0 };
            try prob.setColumnCoefficients(2, &col2_rows, &col2_values);
            
            // Configure column 3: x₄ integer ∈ [1, 5]
            try prob.setColumnName(3, "x4");
            try prob.setColumnRangeBounds(3, 1.0, 5.0);
            prob.setColumnInteger(3);
            prob.setObjectiveCoefficient(3, 1.0);
            const col3_rows = [_]usize{ 1 };
            const col3_values = [_]f64{ 1.0 };
            try prob.setColumnCoefficients(3, &col3_rows, &col3_values);
            
            // Verify configuration
            try testing.expectEqual(@as(usize, 4), prob.getColumnCount());
            
            // Check column 0
            const name0 = prob.getColumnName(0);
            try testing.expect(name0 != null);
            try testing.expectEqualStrings("x1", name0.?);
            
            const bounds0 = try prob.getColumnBounds(0);
            try testing.expectEqual(types.BoundType.lower, bounds0.type);
            try testing.expectApproxEqAbs(@as(f64, 0.0), bounds0.lower, 1e-10);
            try testing.expectApproxEqAbs(@as(f64, 3.0), prob.getObjectiveCoefficient(0), 1e-10);
            
            var coeffs0 = try prob.getColumnCoefficients(0);
            defer coeffs0.deinit();
            try testing.expectEqual(@as(usize, 2), coeffs0.indices.len);
            
            // Check column 1
            const name1 = prob.getColumnName(1);
            try testing.expect(name1 != null);
            try testing.expectEqualStrings("x2", name1.?);
            
            const bounds1 = try prob.getColumnBounds(1);
            try testing.expectEqual(types.BoundType.double, bounds1.type);
            try testing.expectApproxEqAbs(@as(f64, 0.0), bounds1.lower, 1e-10);
            try testing.expectApproxEqAbs(@as(f64, 10.0), bounds1.upper, 1e-10);
            
            // Check column 2
            try testing.expectEqual(types.VariableKind.binary, prob.getColumnKind(2));
            const bounds2 = try prob.getColumnBounds(2);
            try testing.expectEqual(types.BoundType.double, bounds2.type);
            try testing.expectApproxEqAbs(@as(f64, 0.0), bounds2.lower, 1e-10);
            try testing.expectApproxEqAbs(@as(f64, 1.0), bounds2.upper, 1e-10);
            
            // Check column 3
            try testing.expectEqual(types.VariableKind.integer, prob.getColumnKind(3));
            const bounds3 = try prob.getColumnBounds(3);
            try testing.expectEqual(types.BoundType.double, bounds3.type);
            try testing.expectApproxEqAbs(@as(f64, 1.0), bounds3.lower, 1e-10);
            try testing.expectApproxEqAbs(@as(f64, 5.0), bounds3.upper, 1e-10);
            
            // Delete column 0 and verify
            try prob.deleteColumn(0);
            try testing.expectEqual(@as(usize, 3), prob.getColumnCount());
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════╝