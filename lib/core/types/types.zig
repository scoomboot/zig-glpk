// types.zig — Zig-friendly type definitions for GLPK wrapper
//
// repo   : https://github.com/scoomboot/zig-glpk
// docs   : https://scoomboot.github.io/zig-glpk/lib/core/utils/types
// author : https://github.com/scoomboot
//
// Vibe coded by Scoom.

// ╔══════════════════════════════════════ PACK ══════════════════════════════════════╗

    const std = @import("std");
    const glpk = @import("../../c/utils/glpk/glpk.zig");

// ╚══════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ CORE ══════════════════════════════════════╗

    // ┌──────────────────────────── Optimization Direction ────────────────────────────┐
    
        /// Optimization direction for the objective function
        pub const OptimizationDirection = enum {
            minimize,
            maximize,
            
            /// Convert to GLPK constant
            ///
            /// __Return__
            /// - The corresponding GLPK constant value
            pub fn toGLPK(self: OptimizationDirection) c_int {
                return switch (self) {
                    .minimize => glpk.GLP_MIN,
                    .maximize => glpk.GLP_MAX,
                };
            }
            
            /// Convert from GLPK constant
            ///
            /// __Parameters__
            /// - `value`: GLPK constant value to convert
            ///
            /// __Return__
            /// - The corresponding OptimizationDirection or InvalidOptimizationDirection error
            pub fn fromGLPK(value: c_int) !OptimizationDirection {
                return switch (value) {
                    glpk.GLP_MIN => .minimize,
                    glpk.GLP_MAX => .maximize,
                    else => error.InvalidOptimizationDirection,
                };
            }
        };
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Variable Bound Type ────────────────────────────┐
    
        /// Type of bounds for variables and constraints
        pub const BoundType = enum {
            free,       // -∞ < x < +∞
            lower,      // lb ≤ x < +∞
            upper,      // -∞ < x ≤ ub
            double,     // lb ≤ x ≤ ub
            fixed,      // x = lb = ub
            
            /// Convert to GLPK constant
            ///
            /// __Return__
            /// - The corresponding GLPK constant value
            pub fn toGLPK(self: BoundType) c_int {
                return switch (self) {
                    .free => glpk.GLP_FR,
                    .lower => glpk.GLP_LO,
                    .upper => glpk.GLP_UP,
                    .double => glpk.GLP_DB,
                    .fixed => glpk.GLP_FX,
                };
            }
            
            /// Convert from GLPK constant
            ///
            /// __Parameters__
            /// - `value`: GLPK constant value to convert
            ///
            /// __Return__
            /// - The corresponding BoundType or InvalidBoundType error
            pub fn fromGLPK(value: c_int) !BoundType {
                return switch (value) {
                    glpk.GLP_FR => .free,
                    glpk.GLP_LO => .lower,
                    glpk.GLP_UP => .upper,
                    glpk.GLP_DB => .double,
                    glpk.GLP_FX => .fixed,
                    else => error.InvalidBoundType,
                };
            }
        };
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Variable Kind ────────────────────────────┐
    
        /// Kind of decision variable
        pub const VariableKind = enum {
            continuous,  // Real-valued variable
            integer,     // Integer variable
            binary,      // Binary variable (0 or 1)
            
            /// Convert to GLPK constant
            ///
            /// __Return__
            /// - The corresponding GLPK constant value
            pub fn toGLPK(self: VariableKind) c_int {
                return switch (self) {
                    .continuous => glpk.GLP_CV,
                    .integer => glpk.GLP_IV,
                    .binary => glpk.GLP_BV,
                };
            }
            
            /// Convert from GLPK constant
            ///
            /// __Parameters__
            /// - `value`: GLPK constant value to convert
            ///
            /// __Return__
            /// - The corresponding VariableKind or InvalidVariableKind error
            pub fn fromGLPK(value: c_int) !VariableKind {
                return switch (value) {
                    glpk.GLP_CV => .continuous,
                    glpk.GLP_IV => .integer,
                    glpk.GLP_BV => .binary,
                    else => error.InvalidVariableKind,
                };
            }
        };
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Solution Status ────────────────────────────┐
    
        /// Status of the solution
        pub const SolutionStatus = enum {
            optimal,     // Optimal solution found
            feasible,    // Feasible solution found
            infeasible,  // No feasible solution exists
            no_feasible, // No feasible solution exists (proven)
            unbounded,   // Objective unbounded
            undefined,   // Solution undefined
            
            /// Convert to GLPK constant
            ///
            /// __Return__
            /// - The corresponding GLPK constant value
            pub fn toGLPK(self: SolutionStatus) c_int {
                return switch (self) {
                    .optimal => glpk.GLP_OPT,
                    .feasible => glpk.GLP_FEAS,
                    .infeasible => glpk.GLP_INFEAS,
                    .no_feasible => glpk.GLP_NOFEAS,
                    .unbounded => glpk.GLP_UNBND,
                    .undefined => glpk.GLP_UNDEF,
                };
            }
            
            /// Convert from GLPK constant
            ///
            /// __Parameters__
            /// - `value`: GLPK constant value to convert
            ///
            /// __Return__
            /// - The corresponding SolutionStatus or InvalidSolutionStatus error
            pub fn fromGLPK(value: c_int) !SolutionStatus {
                return switch (value) {
                    glpk.GLP_OPT => .optimal,
                    glpk.GLP_FEAS => .feasible,
                    glpk.GLP_INFEAS => .infeasible,
                    glpk.GLP_NOFEAS => .no_feasible,
                    glpk.GLP_UNBND => .unbounded,
                    glpk.GLP_UNDEF => .undefined,
                    else => error.InvalidSolutionStatus,
                };
            }
            
            /// Check if the solution represents a successful state
            ///
            /// __Return__
            /// - true if the status represents optimal or feasible solution
            pub fn isSuccess(self: SolutionStatus) bool {
                return switch (self) {
                    .optimal, .feasible => true,
                    .infeasible, .no_feasible, .unbounded, .undefined => false,
                };
            }
            
            /// Check if the solution represents an error state
            ///
            /// __Return__
            /// - true if the status represents an error condition
            pub fn isError(self: SolutionStatus) bool {
                return switch (self) {
                    .optimal, .feasible => false,
                    .infeasible, .no_feasible, .unbounded, .undefined => true,
                };
            }
        };
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Simplex Method ────────────────────────────┐
    
        /// Simplex method variant
        pub const SimplexMethod = enum {
            primal,      // Primal simplex
            dual,        // Dual simplex
            dual_primal, // Dual then primal
            
            /// Convert to GLPK constant
            ///
            /// __Return__
            /// - The corresponding GLPK constant value
            pub fn toGLPK(self: SimplexMethod) c_int {
                return switch (self) {
                    .primal => glpk.GLP_PRIMAL,
                    .dual => glpk.GLP_DUAL,
                    .dual_primal => glpk.GLP_DUALP,
                };
            }
            
            /// Convert from GLPK constant
            ///
            /// __Parameters__
            /// - `value`: GLPK constant value to convert
            ///
            /// __Return__
            /// - The corresponding SimplexMethod or InvalidSimplexMethod error
            pub fn fromGLPK(value: c_int) !SimplexMethod {
                return switch (value) {
                    glpk.GLP_PRIMAL => .primal,
                    glpk.GLP_DUAL => .dual,
                    glpk.GLP_DUALP => .dual_primal,
                    else => error.InvalidSimplexMethod,
                };
            }
        };
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Pricing Rule ────────────────────────────┐
    
        /// Pricing rule for simplex method
        pub const PricingRule = enum {
            standard,        // Standard (Dantzig's rule)
            steepest_edge,   // Projected steepest edge
            
            /// Convert to GLPK constant
            ///
            /// __Return__
            /// - The corresponding GLPK constant value
            pub fn toGLPK(self: PricingRule) c_int {
                return switch (self) {
                    .standard => glpk.GLP_PT_STD,
                    .steepest_edge => glpk.GLP_PT_PSE,
                };
            }
            
            /// Convert from GLPK constant
            ///
            /// __Parameters__
            /// - `value`: GLPK constant value to convert
            ///
            /// __Return__
            /// - The corresponding PricingRule or InvalidPricingRule error
            pub fn fromGLPK(value: c_int) !PricingRule {
                return switch (value) {
                    glpk.GLP_PT_STD => .standard,
                    glpk.GLP_PT_PSE => .steepest_edge,
                    else => error.InvalidPricingRule,
                };
            }
        };
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Ratio Test ────────────────────────────┐
    
        /// Ratio test technique for simplex method
        pub const RatioTest = enum {
            standard,  // Standard textbook ratio test
            harris,    // Harris' two-pass ratio test
            
            /// Convert to GLPK constant
            ///
            /// __Return__
            /// - The corresponding GLPK constant value
            pub fn toGLPK(self: RatioTest) c_int {
                return switch (self) {
                    .standard => glpk.GLP_RT_STD,
                    .harris => glpk.GLP_RT_HAR,
                };
            }
            
            /// Convert from GLPK constant
            ///
            /// __Parameters__
            /// - `value`: GLPK constant value to convert
            ///
            /// __Return__
            /// - The corresponding RatioTest or InvalidRatioTest error
            pub fn fromGLPK(value: c_int) !RatioTest {
                return switch (value) {
                    glpk.GLP_RT_STD => .standard,
                    glpk.GLP_RT_HAR => .harris,
                    else => error.InvalidRatioTest,
                };
            }
        };
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Branching Rule ────────────────────────────┐
    
        /// Branching rule for MIP solver
        pub const BranchingRule = enum {
            first_fractional,  // First fractional variable
            last_fractional,   // Last fractional variable
            most_fractional,   // Most fractional variable
            driebeek_tomlin,   // Heuristic by Driebeck and Tomlin
            
            /// Convert to GLPK constant
            ///
            /// __Return__
            /// - The corresponding GLPK constant value
            pub fn toGLPK(self: BranchingRule) c_int {
                return switch (self) {
                    .first_fractional => glpk.GLP_BR_FFV,
                    .last_fractional => glpk.GLP_BR_LFV,
                    .most_fractional => glpk.GLP_BR_MFV,
                    .driebeek_tomlin => glpk.GLP_BR_DTH,
                };
            }
            
            /// Convert from GLPK constant
            ///
            /// __Parameters__
            /// - `value`: GLPK constant value to convert
            ///
            /// __Return__
            /// - The corresponding BranchingRule or InvalidBranchingRule error
            pub fn fromGLPK(value: c_int) !BranchingRule {
                return switch (value) {
                    glpk.GLP_BR_FFV => .first_fractional,
                    glpk.GLP_BR_LFV => .last_fractional,
                    glpk.GLP_BR_MFV => .most_fractional,
                    glpk.GLP_BR_DTH => .driebeek_tomlin,
                    else => error.InvalidBranchingRule,
                };
            }
        };
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Backtracking Rule ────────────────────────────┐
    
        /// Backtracking rule for MIP solver
        pub const BacktrackingRule = enum {
            depth_first,      // Depth first search
            breadth_first,    // Breadth first search
            best_local,       // Best local bound
            best_projection,  // Best projection heuristic
            
            /// Convert to GLPK constant
            ///
            /// __Return__
            /// - The corresponding GLPK constant value
            pub fn toGLPK(self: BacktrackingRule) c_int {
                return switch (self) {
                    .depth_first => glpk.GLP_BT_DFS,
                    .breadth_first => glpk.GLP_BT_BFS,
                    .best_local => glpk.GLP_BT_BLB,
                    .best_projection => glpk.GLP_BT_BPH,
                };
            }
            
            /// Convert from GLPK constant
            ///
            /// __Parameters__
            /// - `value`: GLPK constant value to convert
            ///
            /// __Return__
            /// - The corresponding BacktrackingRule or InvalidBacktrackingRule error
            pub fn fromGLPK(value: c_int) !BacktrackingRule {
                return switch (value) {
                    glpk.GLP_BT_DFS => .depth_first,
                    glpk.GLP_BT_BFS => .breadth_first,
                    glpk.GLP_BT_BLB => .best_local,
                    glpk.GLP_BT_BPH => .best_projection,
                    else => error.InvalidBacktrackingRule,
                };
            }
        };
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Sparse Matrix ────────────────────────────┐
    
        /// Sparse matrix representation for constraint coefficients
        pub const SparseMatrix = struct {
            /// Row indices (1-based for GLPK compatibility)
            rows: []const i32,
            /// Column indices (1-based for GLPK compatibility)
            cols: []const i32,
            /// Non-zero values
            values: []const f64,
            
            /// Validate that the sparse matrix is well-formed
            ///
            /// __Return__
            /// - void on success, or error if validation fails
            pub fn validate(self: SparseMatrix) !void {
                // Check that all arrays have the same length
                if (self.rows.len != self.cols.len or self.rows.len != self.values.len) {
                    return error.InconsistentArrayLengths;
                }
                
                // Check that indices are positive (1-based)
                for (self.rows) |row| {
                    if (row <= 0) {
                        return error.InvalidRowIndex;
                    }
                }
                
                for (self.cols) |col| {
                    if (col <= 0) {
                        return error.InvalidColumnIndex;
                    }
                }
                
                // Check for NaN or infinite values
                for (self.values) |val| {
                    if (std.math.isNan(val) or std.math.isInf(val)) {
                        return error.InvalidValue;
                    }
                }
            }
            
            /// Convert a dense matrix to sparse format
            ///
            /// __Parameters__
            /// - `allocator`: Memory allocator for sparse arrays
            /// - `dense`: Dense matrix as 2D array of f64 values
            /// - `tolerance`: Absolute value threshold for considering values as non-zero
            ///
            /// __Return__
            /// - A new SparseMatrix or allocation error
            pub fn fromDense(allocator: std.mem.Allocator, dense: []const []const f64, tolerance: f64) !SparseMatrix {
                var row_list = std.ArrayList(i32).init(allocator);
                defer row_list.deinit();
                var col_list = std.ArrayList(i32).init(allocator);
                defer col_list.deinit();
                var val_list = std.ArrayList(f64).init(allocator);
                defer val_list.deinit();
                
                for (dense, 0..) |row, i| {
                    for (row, 0..) |val, j| {
                        if (@abs(val) > tolerance) {
                            try row_list.append(@intCast(i + 1)); // 1-based
                            try col_list.append(@intCast(j + 1)); // 1-based
                            try val_list.append(val);
                        }
                    }
                }
                
                return SparseMatrix{
                    .rows = try row_list.toOwnedSlice(),
                    .cols = try col_list.toOwnedSlice(),
                    .values = try val_list.toOwnedSlice(),
                };
            }
            
            /// Free allocated memory
            ///
            /// __Parameters__
            /// - `allocator`: The allocator used to create the sparse arrays
            pub fn deinit(self: *SparseMatrix, allocator: std.mem.Allocator) void {
                allocator.free(self.rows);
                allocator.free(self.cols);
                allocator.free(self.values);
            }
        };
    
    // └──────────────────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ TEST ══════════════════════════════════════╗

    const testing = std.testing;
    
    // ┌──────────────────────────── OptimizationDirection Tests ────────────────────────────┐
    
        test "unit: OptimizationDirection: toGLPK conversion" {
            try testing.expectEqual(glpk.GLP_MIN, OptimizationDirection.minimize.toGLPK());
            try testing.expectEqual(glpk.GLP_MAX, OptimizationDirection.maximize.toGLPK());
        }
        
        test "unit: OptimizationDirection: fromGLPK conversion" {
            try testing.expectEqual(OptimizationDirection.minimize, try OptimizationDirection.fromGLPK(glpk.GLP_MIN));
            try testing.expectEqual(OptimizationDirection.maximize, try OptimizationDirection.fromGLPK(glpk.GLP_MAX));
        }
        
        test "unit: OptimizationDirection: invalid fromGLPK value" {
            try testing.expectError(error.InvalidOptimizationDirection, OptimizationDirection.fromGLPK(999));
        }
        
        test "unit: OptimizationDirection: round-trip conversion" {
            const values = [_]OptimizationDirection{ .minimize, .maximize };
            for (values) |val| {
                const glpk_val = val.toGLPK();
                const back = try OptimizationDirection.fromGLPK(glpk_val);
                try testing.expectEqual(val, back);
            }
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── BoundType Tests ────────────────────────────┐
    
        test "unit: BoundType: toGLPK conversion" {
            try testing.expectEqual(glpk.GLP_FR, BoundType.free.toGLPK());
            try testing.expectEqual(glpk.GLP_LO, BoundType.lower.toGLPK());
            try testing.expectEqual(glpk.GLP_UP, BoundType.upper.toGLPK());
            try testing.expectEqual(glpk.GLP_DB, BoundType.double.toGLPK());
            try testing.expectEqual(glpk.GLP_FX, BoundType.fixed.toGLPK());
        }
        
        test "unit: BoundType: fromGLPK conversion" {
            try testing.expectEqual(BoundType.free, try BoundType.fromGLPK(glpk.GLP_FR));
            try testing.expectEqual(BoundType.lower, try BoundType.fromGLPK(glpk.GLP_LO));
            try testing.expectEqual(BoundType.upper, try BoundType.fromGLPK(glpk.GLP_UP));
            try testing.expectEqual(BoundType.double, try BoundType.fromGLPK(glpk.GLP_DB));
            try testing.expectEqual(BoundType.fixed, try BoundType.fromGLPK(glpk.GLP_FX));
        }
        
        test "unit: BoundType: invalid fromGLPK value" {
            try testing.expectError(error.InvalidBoundType, BoundType.fromGLPK(999));
        }
        
        test "unit: BoundType: round-trip conversion" {
            const values = [_]BoundType{ .free, .lower, .upper, .double, .fixed };
            for (values) |val| {
                const glpk_val = val.toGLPK();
                const back = try BoundType.fromGLPK(glpk_val);
                try testing.expectEqual(val, back);
            }
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── VariableKind Tests ────────────────────────────┐
    
        test "unit: VariableKind: toGLPK conversion" {
            try testing.expectEqual(glpk.GLP_CV, VariableKind.continuous.toGLPK());
            try testing.expectEqual(glpk.GLP_IV, VariableKind.integer.toGLPK());
            try testing.expectEqual(glpk.GLP_BV, VariableKind.binary.toGLPK());
        }
        
        test "unit: VariableKind: fromGLPK conversion" {
            try testing.expectEqual(VariableKind.continuous, try VariableKind.fromGLPK(glpk.GLP_CV));
            try testing.expectEqual(VariableKind.integer, try VariableKind.fromGLPK(glpk.GLP_IV));
            try testing.expectEqual(VariableKind.binary, try VariableKind.fromGLPK(glpk.GLP_BV));
        }
        
        test "unit: VariableKind: invalid fromGLPK value" {
            try testing.expectError(error.InvalidVariableKind, VariableKind.fromGLPK(999));
        }
        
        test "unit: VariableKind: round-trip conversion" {
            const values = [_]VariableKind{ .continuous, .integer, .binary };
            for (values) |val| {
                const glpk_val = val.toGLPK();
                const back = try VariableKind.fromGLPK(glpk_val);
                try testing.expectEqual(val, back);
            }
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── SolutionStatus Tests ────────────────────────────┐
    
        test "unit: SolutionStatus: toGLPK conversion" {
            try testing.expectEqual(glpk.GLP_OPT, SolutionStatus.optimal.toGLPK());
            try testing.expectEqual(glpk.GLP_FEAS, SolutionStatus.feasible.toGLPK());
            try testing.expectEqual(glpk.GLP_INFEAS, SolutionStatus.infeasible.toGLPK());
            try testing.expectEqual(glpk.GLP_NOFEAS, SolutionStatus.no_feasible.toGLPK());
            try testing.expectEqual(glpk.GLP_UNBND, SolutionStatus.unbounded.toGLPK());
            try testing.expectEqual(glpk.GLP_UNDEF, SolutionStatus.undefined.toGLPK());
        }
        
        test "unit: SolutionStatus: fromGLPK conversion" {
            try testing.expectEqual(SolutionStatus.optimal, try SolutionStatus.fromGLPK(glpk.GLP_OPT));
            try testing.expectEqual(SolutionStatus.feasible, try SolutionStatus.fromGLPK(glpk.GLP_FEAS));
            try testing.expectEqual(SolutionStatus.infeasible, try SolutionStatus.fromGLPK(glpk.GLP_INFEAS));
            try testing.expectEqual(SolutionStatus.no_feasible, try SolutionStatus.fromGLPK(glpk.GLP_NOFEAS));
            try testing.expectEqual(SolutionStatus.unbounded, try SolutionStatus.fromGLPK(glpk.GLP_UNBND));
            try testing.expectEqual(SolutionStatus.undefined, try SolutionStatus.fromGLPK(glpk.GLP_UNDEF));
        }
        
        test "unit: SolutionStatus: invalid fromGLPK value" {
            try testing.expectError(error.InvalidSolutionStatus, SolutionStatus.fromGLPK(999));
        }
        
        test "unit: SolutionStatus: round-trip conversion" {
            const values = [_]SolutionStatus{ 
                .optimal, .feasible, .infeasible, 
                .no_feasible, .unbounded, .undefined 
            };
            for (values) |val| {
                const glpk_val = val.toGLPK();
                const back = try SolutionStatus.fromGLPK(glpk_val);
                try testing.expectEqual(val, back);
            }
        }
        
        test "unit: SolutionStatus: isSuccess helper" {
            // Success states
            try testing.expect(SolutionStatus.optimal.isSuccess());
            try testing.expect(SolutionStatus.feasible.isSuccess());
            
            // Non-success states
            try testing.expect(!SolutionStatus.infeasible.isSuccess());
            try testing.expect(!SolutionStatus.no_feasible.isSuccess());
            try testing.expect(!SolutionStatus.unbounded.isSuccess());
            try testing.expect(!SolutionStatus.undefined.isSuccess());
        }
        
        test "unit: SolutionStatus: isError helper" {
            // Non-error states
            try testing.expect(!SolutionStatus.optimal.isError());
            try testing.expect(!SolutionStatus.feasible.isError());
            
            // Error states
            try testing.expect(SolutionStatus.infeasible.isError());
            try testing.expect(SolutionStatus.no_feasible.isError());
            try testing.expect(SolutionStatus.unbounded.isError());
            try testing.expect(SolutionStatus.undefined.isError());
        }
        
        test "unit: SolutionStatus: isSuccess and isError are mutually exclusive" {
            const values = [_]SolutionStatus{ 
                .optimal, .feasible, .infeasible, 
                .no_feasible, .unbounded, .undefined 
            };
            for (values) |val| {
                // A status can't be both success and error
                try testing.expect(val.isSuccess() != val.isError());
            }
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── SimplexMethod Tests ────────────────────────────┐
    
        test "unit: SimplexMethod: toGLPK conversion" {
            try testing.expectEqual(glpk.GLP_PRIMAL, SimplexMethod.primal.toGLPK());
            try testing.expectEqual(glpk.GLP_DUAL, SimplexMethod.dual.toGLPK());
            try testing.expectEqual(glpk.GLP_DUALP, SimplexMethod.dual_primal.toGLPK());
        }
        
        test "unit: SimplexMethod: fromGLPK conversion" {
            try testing.expectEqual(SimplexMethod.primal, try SimplexMethod.fromGLPK(glpk.GLP_PRIMAL));
            try testing.expectEqual(SimplexMethod.dual, try SimplexMethod.fromGLPK(glpk.GLP_DUAL));
            try testing.expectEqual(SimplexMethod.dual_primal, try SimplexMethod.fromGLPK(glpk.GLP_DUALP));
        }
        
        test "unit: SimplexMethod: invalid fromGLPK value" {
            try testing.expectError(error.InvalidSimplexMethod, SimplexMethod.fromGLPK(999));
        }
        
        test "unit: SimplexMethod: round-trip conversion" {
            const values = [_]SimplexMethod{ .primal, .dual, .dual_primal };
            for (values) |val| {
                const glpk_val = val.toGLPK();
                const back = try SimplexMethod.fromGLPK(glpk_val);
                try testing.expectEqual(val, back);
            }
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── PricingRule Tests ────────────────────────────┐
    
        test "unit: PricingRule: toGLPK conversion" {
            try testing.expectEqual(glpk.GLP_PT_STD, PricingRule.standard.toGLPK());
            try testing.expectEqual(glpk.GLP_PT_PSE, PricingRule.steepest_edge.toGLPK());
        }
        
        test "unit: PricingRule: fromGLPK conversion" {
            try testing.expectEqual(PricingRule.standard, try PricingRule.fromGLPK(glpk.GLP_PT_STD));
            try testing.expectEqual(PricingRule.steepest_edge, try PricingRule.fromGLPK(glpk.GLP_PT_PSE));
        }
        
        test "unit: PricingRule: invalid fromGLPK value" {
            try testing.expectError(error.InvalidPricingRule, PricingRule.fromGLPK(999));
        }
        
        test "unit: PricingRule: round-trip conversion" {
            const values = [_]PricingRule{ .standard, .steepest_edge };
            for (values) |val| {
                const glpk_val = val.toGLPK();
                const back = try PricingRule.fromGLPK(glpk_val);
                try testing.expectEqual(val, back);
            }
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── RatioTest Tests ────────────────────────────┐
    
        test "unit: RatioTest: toGLPK conversion" {
            try testing.expectEqual(glpk.GLP_RT_STD, RatioTest.standard.toGLPK());
            try testing.expectEqual(glpk.GLP_RT_HAR, RatioTest.harris.toGLPK());
        }
        
        test "unit: RatioTest: fromGLPK conversion" {
            try testing.expectEqual(RatioTest.standard, try RatioTest.fromGLPK(glpk.GLP_RT_STD));
            try testing.expectEqual(RatioTest.harris, try RatioTest.fromGLPK(glpk.GLP_RT_HAR));
        }
        
        test "unit: RatioTest: invalid fromGLPK value" {
            try testing.expectError(error.InvalidRatioTest, RatioTest.fromGLPK(999));
        }
        
        test "unit: RatioTest: round-trip conversion" {
            const values = [_]RatioTest{ .standard, .harris };
            for (values) |val| {
                const glpk_val = val.toGLPK();
                const back = try RatioTest.fromGLPK(glpk_val);
                try testing.expectEqual(val, back);
            }
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── BranchingRule Tests ────────────────────────────┐
    
        test "unit: BranchingRule: toGLPK conversion" {
            try testing.expectEqual(glpk.GLP_BR_FFV, BranchingRule.first_fractional.toGLPK());
            try testing.expectEqual(glpk.GLP_BR_LFV, BranchingRule.last_fractional.toGLPK());
            try testing.expectEqual(glpk.GLP_BR_MFV, BranchingRule.most_fractional.toGLPK());
            try testing.expectEqual(glpk.GLP_BR_DTH, BranchingRule.driebeek_tomlin.toGLPK());
        }
        
        test "unit: BranchingRule: fromGLPK conversion" {
            try testing.expectEqual(BranchingRule.first_fractional, try BranchingRule.fromGLPK(glpk.GLP_BR_FFV));
            try testing.expectEqual(BranchingRule.last_fractional, try BranchingRule.fromGLPK(glpk.GLP_BR_LFV));
            try testing.expectEqual(BranchingRule.most_fractional, try BranchingRule.fromGLPK(glpk.GLP_BR_MFV));
            try testing.expectEqual(BranchingRule.driebeek_tomlin, try BranchingRule.fromGLPK(glpk.GLP_BR_DTH));
        }
        
        test "unit: BranchingRule: invalid fromGLPK value" {
            try testing.expectError(error.InvalidBranchingRule, BranchingRule.fromGLPK(999));
        }
        
        test "unit: BranchingRule: round-trip conversion" {
            const values = [_]BranchingRule{ 
                .first_fractional, .last_fractional, 
                .most_fractional, .driebeek_tomlin 
            };
            for (values) |val| {
                const glpk_val = val.toGLPK();
                const back = try BranchingRule.fromGLPK(glpk_val);
                try testing.expectEqual(val, back);
            }
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── BacktrackingRule Tests ────────────────────────────┐
    
        test "unit: BacktrackingRule: toGLPK conversion" {
            try testing.expectEqual(glpk.GLP_BT_DFS, BacktrackingRule.depth_first.toGLPK());
            try testing.expectEqual(glpk.GLP_BT_BFS, BacktrackingRule.breadth_first.toGLPK());
            try testing.expectEqual(glpk.GLP_BT_BLB, BacktrackingRule.best_local.toGLPK());
            try testing.expectEqual(glpk.GLP_BT_BPH, BacktrackingRule.best_projection.toGLPK());
        }
        
        test "unit: BacktrackingRule: fromGLPK conversion" {
            try testing.expectEqual(BacktrackingRule.depth_first, try BacktrackingRule.fromGLPK(glpk.GLP_BT_DFS));
            try testing.expectEqual(BacktrackingRule.breadth_first, try BacktrackingRule.fromGLPK(glpk.GLP_BT_BFS));
            try testing.expectEqual(BacktrackingRule.best_local, try BacktrackingRule.fromGLPK(glpk.GLP_BT_BLB));
            try testing.expectEqual(BacktrackingRule.best_projection, try BacktrackingRule.fromGLPK(glpk.GLP_BT_BPH));
        }
        
        test "unit: BacktrackingRule: invalid fromGLPK value" {
            try testing.expectError(error.InvalidBacktrackingRule, BacktrackingRule.fromGLPK(999));
        }
        
        test "unit: BacktrackingRule: round-trip conversion" {
            const values = [_]BacktrackingRule{ 
                .depth_first, .breadth_first, 
                .best_local, .best_projection 
            };
            for (values) |val| {
                const glpk_val = val.toGLPK();
                const back = try BacktrackingRule.fromGLPK(glpk_val);
                try testing.expectEqual(val, back);
            }
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── SparseMatrix Tests ────────────────────────────┐
    
        test "unit: SparseMatrix: validate with valid data" {
            const matrix = SparseMatrix{
                .rows = &[_]i32{ 1, 2, 3 },
                .cols = &[_]i32{ 1, 2, 3 },
                .values = &[_]f64{ 1.0, 2.0, 3.0 },
            };
            try matrix.validate();
        }
        
        test "unit: SparseMatrix: validate with inconsistent lengths" {
            const matrix = SparseMatrix{
                .rows = &[_]i32{ 1, 2 },
                .cols = &[_]i32{ 1, 2, 3 },
                .values = &[_]f64{ 1.0, 2.0 },
            };
            try testing.expectError(error.InconsistentArrayLengths, matrix.validate());
        }
        
        test "unit: SparseMatrix: validate with invalid row index" {
            const matrix = SparseMatrix{
                .rows = &[_]i32{ 0, 2, 3 },  // 0 is invalid (must be 1-based)
                .cols = &[_]i32{ 1, 2, 3 },
                .values = &[_]f64{ 1.0, 2.0, 3.0 },
            };
            try testing.expectError(error.InvalidRowIndex, matrix.validate());
        }
        
        test "unit: SparseMatrix: validate with invalid column index" {
            const matrix = SparseMatrix{
                .rows = &[_]i32{ 1, 2, 3 },
                .cols = &[_]i32{ 1, -1, 3 },  // -1 is invalid
                .values = &[_]f64{ 1.0, 2.0, 3.0 },
            };
            try testing.expectError(error.InvalidColumnIndex, matrix.validate());
        }
        
        test "unit: SparseMatrix: validate with NaN value" {
            const matrix = SparseMatrix{
                .rows = &[_]i32{ 1, 2, 3 },
                .cols = &[_]i32{ 1, 2, 3 },
                .values = &[_]f64{ 1.0, std.math.nan(f64), 3.0 },
            };
            try testing.expectError(error.InvalidValue, matrix.validate());
        }
        
        test "unit: SparseMatrix: validate with infinite value" {
            const matrix = SparseMatrix{
                .rows = &[_]i32{ 1, 2, 3 },
                .cols = &[_]i32{ 1, 2, 3 },
                .values = &[_]f64{ 1.0, std.math.inf(f64), 3.0 },
            };
            try testing.expectError(error.InvalidValue, matrix.validate());
        }
        
        test "unit: SparseMatrix: fromDense conversion" {
            const dense = [_][3]f64{
                .{ 1.0, 0.0, 2.0 },
                .{ 0.0, 3.0, 0.0 },
                .{ 4.0, 0.0, 5.0 },
            };
            
            // Convert 2D array to slice of slices
            var dense_slices: [3][]const f64 = undefined;
            for (&dense_slices, &dense) |*slice, *row| {
                slice.* = row;
            }
            
            var sparse = try SparseMatrix.fromDense(
                testing.allocator,
                &dense_slices,
                1e-10
            );
            defer sparse.deinit(testing.allocator);
            
            // Verify the sparse representation
            try testing.expectEqual(@as(usize, 5), sparse.values.len);
            
            // Check that all non-zero values are captured
            // Note: The exact order might vary, so we just check the count
            var non_zero_count: usize = 0;
            for (dense) |row| {
                for (row) |val| {
                    if (@abs(val) > 1e-10) {
                        non_zero_count += 1;
                    }
                }
            }
            try testing.expectEqual(non_zero_count, sparse.values.len);
            
            // Validate the sparse matrix
            try sparse.validate();
        }
        
        test "unit: SparseMatrix: fromDense with tolerance" {
            const dense = [_][3]f64{
                .{ 1.0, 0.01, 2.0 },
                .{ 0.001, 3.0, 0.0001 },
                .{ 4.0, 0.0, 5.0 },
            };
            
            // Convert 2D array to slice of slices
            var dense_slices: [3][]const f64 = undefined;
            for (&dense_slices, &dense) |*slice, *row| {
                slice.* = row;
            }
            
            // Use tolerance of 0.1 to filter out small values
            var sparse = try SparseMatrix.fromDense(
                testing.allocator,
                &dense_slices,
                0.1
            );
            defer sparse.deinit(testing.allocator);
            
            // Should only capture values > 0.1 in absolute value
            // That's 1.0, 2.0, 3.0, 4.0, 5.0 = 5 values
            try testing.expectEqual(@as(usize, 5), sparse.values.len);
            
            // Validate the sparse matrix
            try sparse.validate();
        }
        
        test "unit: SparseMatrix: fromDense empty matrix" {
            const dense = [_][2]f64{
                .{ 0.0, 0.0 },
                .{ 0.0, 0.0 },
            };
            
            // Convert 2D array to slice of slices
            var dense_slices: [2][]const f64 = undefined;
            for (&dense_slices, &dense) |*slice, *row| {
                slice.* = row;
            }
            
            var sparse = try SparseMatrix.fromDense(
                testing.allocator,
                &dense_slices,
                1e-10
            );
            defer sparse.deinit(testing.allocator);
            
            // Should have no non-zero elements
            try testing.expectEqual(@as(usize, 0), sparse.values.len);
            
            // Validate the sparse matrix (empty is valid)
            try sparse.validate();
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════╝