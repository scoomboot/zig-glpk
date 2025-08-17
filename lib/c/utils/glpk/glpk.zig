// glpk.zig — GLPK C bindings and low-level interface
//
// repo   : https://github.com/scoomboot/zig-glpk
// docs   : https://scoomboot.github.io/zig-glpk/lib/c/utils/glpk
// author : https://github.com/scoomboot
//
// Vibe coded by Scoom.

// ╔══════════════════════════════════════ PACK ══════════════════════════════════════╗

    const std = @import("std");
    
    // Import GLPK C API
    pub const c = @cImport({
        @cInclude("glpk.h");
    });

// ╚══════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ INIT ══════════════════════════════════════╗

    // ┌──────────────────────────── Optimization Direction ────────────────────────────┐
    
        /// Minimize objective function
        pub const GLP_MIN = c.GLP_MIN;
        
        /// Maximize objective function
        pub const GLP_MAX = c.GLP_MAX;
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Variable Bounds ────────────────────────────┐
    
        /// Free variable: -∞ < x < +∞
        pub const GLP_FR = c.GLP_FR;
        
        /// Variable with lower bound: lb ≤ x < +∞
        pub const GLP_LO = c.GLP_LO;
        
        /// Variable with upper bound: -∞ < x ≤ ub
        pub const GLP_UP = c.GLP_UP;
        
        /// Variable with double bounds: lb ≤ x ≤ ub
        pub const GLP_DB = c.GLP_DB;
        
        /// Fixed variable: x = lb = ub
        pub const GLP_FX = c.GLP_FX;
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Variable Kinds ────────────────────────────┐
    
        /// Continuous variable
        pub const GLP_CV = c.GLP_CV;
        
        /// Integer variable
        pub const GLP_IV = c.GLP_IV;
        
        /// Binary variable (0 or 1)
        pub const GLP_BV = c.GLP_BV;
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Solution Status ────────────────────────────┐
    
        /// Solution is undefined
        pub const GLP_UNDEF = c.GLP_UNDEF;
        
        /// Solution is feasible
        pub const GLP_FEAS = c.GLP_FEAS;
        
        /// Solution is infeasible
        pub const GLP_INFEAS = c.GLP_INFEAS;
        
        /// No feasible solution exists
        pub const GLP_NOFEAS = c.GLP_NOFEAS;
        
        /// Solution is optimal
        pub const GLP_OPT = c.GLP_OPT;
        
        /// Solution is unbounded
        pub const GLP_UNBND = c.GLP_UNBND;
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Solver Parameters ────────────────────────────┐
    
        /// Primal simplex
        pub const GLP_PRIMAL = c.GLP_PRIMAL;
        
        /// Dual simplex
        pub const GLP_DUAL = c.GLP_DUAL;
        
        /// Dual, then primal simplex
        pub const GLP_DUALP = c.GLP_DUALP;
        
        /// Message level: off
        pub const GLP_MSG_OFF = c.GLP_MSG_OFF;
        
        /// Message level: error messages only
        pub const GLP_MSG_ERR = c.GLP_MSG_ERR;
        
        /// Message level: normal output
        pub const GLP_MSG_ON = c.GLP_MSG_ON;
        
        /// Message level: full output
        pub const GLP_MSG_ALL = c.GLP_MSG_ALL;
        
        /// Message level: debug output
        pub const GLP_MSG_DBG = c.GLP_MSG_DBG;
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Pricing Rules ────────────────────────────┐
    
        /// Standard pricing (Dantzig's rule)
        pub const GLP_PT_STD = 0x11;
        
        /// Projected steepest edge
        pub const GLP_PT_PSE = 0x22;
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Ratio Test ────────────────────────────┐
    
        /// Standard (textbook) ratio test
        pub const GLP_RT_STD = 0x11;
        
        /// Harris' two-pass ratio test
        pub const GLP_RT_HAR = 0x22;
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Branching Rules ────────────────────────────┐
    
        /// First fractional variable
        pub const GLP_BR_FFV = 1;
        
        /// Last fractional variable
        pub const GLP_BR_LFV = 2;
        
        /// Most fractional variable
        pub const GLP_BR_MFV = 3;
        
        /// Heuristic by Driebeck and Tomlin
        pub const GLP_BR_DTH = 4;
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Backtracking Rules ────────────────────────────┐
    
        /// Depth first search
        pub const GLP_BT_DFS = 1;
        
        /// Breadth first search
        pub const GLP_BT_BFS = 2;
        
        /// Best local bound
        pub const GLP_BT_BLB = 3;
        
        /// Best projection heuristic
        pub const GLP_BT_BPH = 4;
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Preprocessing Options ────────────────────────────┐
    
        /// Preprocessing: off
        pub const GLP_OFF = c.GLP_OFF;
        
        /// Preprocessing: on
        pub const GLP_ON = c.GLP_ON;
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Type Aliases ────────────────────────────┐
    
        /// GLPK problem object (opaque pointer)
        pub const Problem = c.glp_prob;
        
        /// Simplex method control parameters
        pub const SimplexParams = c.glp_smcp;
        
        /// Interior-point method control parameters
        pub const InteriorParams = c.glp_iptcp;
        
        /// MIP control parameters
        pub const MIPParams = c.glp_iocp;
    
    // └──────────────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ CORE ══════════════════════════════════════╗

    // ┌──────────────────────────── Problem Management ────────────────────────────┐
    
        /// Create a new problem object
        pub fn createProblem() ?*c.glp_prob {
            return c.glp_create_prob();
        }
        
        /// Delete a problem object and free all memory
        pub fn deleteProblem(prob: ?*c.glp_prob) void {
            c.glp_delete_prob(prob);
        }
        
        /// Set problem name
        pub fn setProblemName(prob: ?*c.glp_prob, name: [*c]const u8) void {
            c.glp_set_prob_name(prob, name);
        }
        
        /// Set objective direction (GLP_MIN or GLP_MAX)
        pub fn setObjectiveDirection(prob: ?*c.glp_prob, dir: c_int) void {
            c.glp_set_obj_dir(prob, dir);
        }
        
        /// Get objective direction
        pub fn getObjectiveDirection(prob: ?*c.glp_prob) c_int {
            return c.glp_get_obj_dir(prob);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Row (Constraint) Management ────────────────────────────┐
    
        /// Add new rows (constraints) to the problem
        pub fn addRows(prob: ?*c.glp_prob, nrs: c_int) c_int {
            return c.glp_add_rows(prob, nrs);
        }
        
        /// Set row name
        pub fn setRowName(prob: ?*c.glp_prob, i: c_int, name: [*c]const u8) void {
            c.glp_set_row_name(prob, i, name);
        }
        
        /// Set row bounds
        pub fn setRowBounds(prob: ?*c.glp_prob, i: c_int, type_: c_int, lb: f64, ub: f64) void {
            c.glp_set_row_bnds(prob, i, type_, lb, ub);
        }
        
        /// Get number of rows
        pub fn getNumRows(prob: ?*c.glp_prob) c_int {
            return c.glp_get_num_rows(prob);
        }
        
        /// Delete rows from the problem
        pub fn deleteRows(prob: ?*c.glp_prob, nrs: c_int, num: [*c]const c_int) void {
            c.glp_del_rows(prob, nrs, num);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Column (Variable) Management ────────────────────────────┐
    
        /// Add new columns (variables) to the problem
        pub fn addColumns(prob: ?*c.glp_prob, ncs: c_int) c_int {
            return c.glp_add_cols(prob, ncs);
        }
        
        /// Set column name
        pub fn setColumnName(prob: ?*c.glp_prob, j: c_int, name: [*c]const u8) void {
            c.glp_set_col_name(prob, j, name);
        }
        
        /// Set column bounds
        pub fn setColumnBounds(prob: ?*c.glp_prob, j: c_int, type_: c_int, lb: f64, ub: f64) void {
            c.glp_set_col_bnds(prob, j, type_, lb, ub);
        }
        
        /// Set objective coefficient for a column
        pub fn setObjectiveCoef(prob: ?*c.glp_prob, j: c_int, coef: f64) void {
            c.glp_set_obj_coef(prob, j, coef);
        }
        
        /// Set column kind (continuous, integer, or binary)
        pub fn setColumnKind(prob: ?*c.glp_prob, j: c_int, kind: c_int) void {
            c.glp_set_col_kind(prob, j, kind);
        }
        
        /// Get number of columns
        pub fn getNumColumns(prob: ?*c.glp_prob) c_int {
            return c.glp_get_num_cols(prob);
        }
        
        /// Delete columns from the problem
        pub fn deleteColumns(prob: ?*c.glp_prob, ncs: c_int, num: [*c]const c_int) void {
            c.glp_del_cols(prob, ncs, num);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Matrix Loading ────────────────────────────┐
    
        /// Load constraint matrix in sparse format
        pub fn loadMatrix(prob: ?*c.glp_prob, ne: c_int, ia: [*c]const c_int, ja: [*c]const c_int, ar: [*c]const f64) void {
            c.glp_load_matrix(prob, ne, ia, ja, ar);
        }
        
        /// Set row of the constraint matrix (expects 1-based arrays with dummy element at index 0)
        /// Direct wrapper for GLPK's glp_set_mat_row - use safeSetMatrixRow for 0-based arrays
        pub fn setMatrixRow(prob: ?*c.glp_prob, i: c_int, len: c_int, ind: [*c]const c_int, val: [*c]const f64) void {
            c.glp_set_mat_row(prob, i, len, ind, val);
        }
        
        /// Set column of the constraint matrix (expects 1-based arrays with dummy element at index 0)
        /// Direct wrapper for GLPK's glp_set_mat_col - use safeSetMatrixCol for 0-based arrays
        pub fn setMatrixCol(prob: ?*c.glp_prob, j: c_int, len: c_int, ind: [*c]const c_int, val: [*c]const f64) void {
            c.glp_set_mat_col(prob, j, len, ind, val);
        }
        
        /// Safe wrapper for setMatrixRow that handles 0-based array conversion to 1-based GLPK format
        /// Takes 0-based arrays and converts them to 1-based arrays with dummy element at index 0
        pub fn safeSetMatrixRow(
            allocator: std.mem.Allocator,
            prob: ?*c.glp_prob,
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
        
        /// Safe wrapper for setMatrixCol that handles 0-based array conversion to 1-based GLPK format
        /// Takes 0-based arrays and converts them to 1-based arrays with dummy element at index 0
        pub fn safeSetMatrixCol(
            allocator: std.mem.Allocator,
            prob: ?*c.glp_prob,
            j: c_int,
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
            setMatrixCol(prob, j, @intCast(ind.len), ind_1based.ptr, val_1based.ptr);
        }
        
        // Note: glp_set_aij doesn't exist in GLPK 5.0
        // Use setMatrixRow or setMatrixCol instead
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Solver Functions ────────────────────────────┐
    
        /// Initialize simplex control parameters with defaults
        pub fn initSimplexParams(parm: *c.glp_smcp) void {
            c.glp_init_smcp(parm);
        }
        
        /// Solve LP with simplex method
        pub fn simplex(prob: ?*c.glp_prob, parm: ?*const c.glp_smcp) c_int {
            return c.glp_simplex(prob, parm);
        }
        
        /// Initialize interior-point control parameters with defaults
        pub fn initInteriorParams(parm: *c.glp_iptcp) void {
            c.glp_init_iptcp(parm);
        }
        
        /// Solve LP with interior-point method
        pub fn interior(prob: ?*c.glp_prob, parm: ?*const c.glp_iptcp) c_int {
            return c.glp_interior(prob, parm);
        }
        
        /// Initialize MIP control parameters with defaults
        pub fn initMIPParams(parm: *c.glp_iocp) void {
            c.glp_init_iocp(parm);
        }
        
        /// Solve MIP with branch-and-cut method
        pub fn intopt(prob: ?*c.glp_prob, parm: ?*const c.glp_iocp) c_int {
            return c.glp_intopt(prob, parm);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Solution Retrieval (Simplex) ────────────────────────────┐
    
        /// Get status of basic solution
        pub fn getStatus(prob: ?*c.glp_prob) c_int {
            return c.glp_get_status(prob);
        }
        
        /// Get status of primal basic solution
        pub fn getPrimalStatus(prob: ?*c.glp_prob) c_int {
            return c.glp_get_prim_stat(prob);
        }
        
        /// Get status of dual basic solution
        pub fn getDualStatus(prob: ?*c.glp_prob) c_int {
            return c.glp_get_dual_stat(prob);
        }
        
        /// Get objective value
        pub fn getObjectiveValue(prob: ?*c.glp_prob) f64 {
            return c.glp_get_obj_val(prob);
        }
        
        /// Get row primal value
        pub fn getRowPrimal(prob: ?*c.glp_prob, i: c_int) f64 {
            return c.glp_get_row_prim(prob, i);
        }
        
        /// Get row dual value
        pub fn getRowDual(prob: ?*c.glp_prob, i: c_int) f64 {
            return c.glp_get_row_dual(prob, i);
        }
        
        /// Get column primal value
        pub fn getColumnPrimal(prob: ?*c.glp_prob, j: c_int) f64 {
            return c.glp_get_col_prim(prob, j);
        }
        
        /// Get column dual value
        pub fn getColumnDual(prob: ?*c.glp_prob, j: c_int) f64 {
            return c.glp_get_col_dual(prob, j);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Solution Retrieval (MIP) ────────────────────────────┐
    
        /// Get MIP solution status
        pub fn getMIPStatus(prob: ?*c.glp_prob) c_int {
            return c.glp_mip_status(prob);
        }
        
        /// Get MIP objective value
        pub fn getMIPObjectiveValue(prob: ?*c.glp_prob) f64 {
            return c.glp_mip_obj_val(prob);
        }
        
        /// Get MIP row value
        pub fn getMIPRowValue(prob: ?*c.glp_prob, i: c_int) f64 {
            return c.glp_mip_row_val(prob, i);
        }
        
        /// Get MIP column value
        pub fn getMIPColumnValue(prob: ?*c.glp_prob, j: c_int) f64 {
            return c.glp_mip_col_val(prob, j);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Solution Retrieval (Interior) ────────────────────────────┐
    
        /// Get interior-point solution status
        pub fn getInteriorStatus(prob: ?*c.glp_prob) c_int {
            return c.glp_ipt_status(prob);
        }
        
        /// Get interior-point objective value
        pub fn getInteriorObjectiveValue(prob: ?*c.glp_prob) f64 {
            return c.glp_ipt_obj_val(prob);
        }
        
        /// Get interior-point row primal value
        pub fn getInteriorRowPrimal(prob: ?*c.glp_prob, i: c_int) f64 {
            return c.glp_ipt_row_prim(prob, i);
        }
        
        /// Get interior-point row dual value
        pub fn getInteriorRowDual(prob: ?*c.glp_prob, i: c_int) f64 {
            return c.glp_ipt_row_dual(prob, i);
        }
        
        /// Get interior-point column primal value
        pub fn getInteriorColumnPrimal(prob: ?*c.glp_prob, j: c_int) f64 {
            return c.glp_ipt_col_prim(prob, j);
        }
        
        /// Get interior-point column dual value
        pub fn getInteriorColumnDual(prob: ?*c.glp_prob, j: c_int) f64 {
            return c.glp_ipt_col_dual(prob, j);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── File I/O Functions ────────────────────────────┐
    
        /// Read problem in MPS format
        pub fn readMPS(prob: ?*c.glp_prob, fmt: c_int, parm: ?*const c.glp_mpscp, fname: [*c]const u8) c_int {
            return c.glp_read_mps(prob, fmt, parm, fname);
        }
        
        /// Write problem in MPS format
        pub fn writeMPS(prob: ?*c.glp_prob, fmt: c_int, parm: ?*const c.glp_mpscp, fname: [*c]const u8) c_int {
            return c.glp_write_mps(prob, fmt, parm, fname);
        }
        
        /// Read problem in CPLEX LP format
        pub fn readLP(prob: ?*c.glp_prob, parm: ?*const c.glp_cpxcp, fname: [*c]const u8) c_int {
            return c.glp_read_lp(prob, parm, fname);
        }
        
        /// Write problem in CPLEX LP format
        pub fn writeLP(prob: ?*c.glp_prob, parm: ?*const c.glp_cpxcp, fname: [*c]const u8) c_int {
            return c.glp_write_lp(prob, parm, fname);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Utility Functions ────────────────────────────┐
    
        /// Get GLPK library version string.
        ///
        /// Returns the version of the GLPK library as a string (e.g., "5.0").
        ///
        /// __Return__
        ///
        /// - String slice containing the GLPK version
        pub fn getVersion() [:0]const u8 {
            // glp_version returns a null-terminated C string
            const version_ptr = c.glp_version();
            return std.mem.span(version_ptr);
        }
        
        /// Get GLPK library major version number.
        ///
        /// Extracts the major version number from the version string.
        ///
        /// __Return__
        ///
        /// - Major version number, or 0 if parsing fails
        pub fn getMajorVersion() u32 {
            const version = getVersion();
            var iter = std.mem.tokenizeScalar(u8, version, '.');
            if (iter.next()) |major_str| {
                return std.fmt.parseInt(u32, major_str, 10) catch 0;
            }
            return 0;
        }
        
        /// Get GLPK library minor version number.
        ///
        /// Extracts the minor version number from the version string.
        ///
        /// __Return__
        ///
        /// - Minor version number, or 0 if parsing fails
        pub fn getMinorVersion() u32 {
            const version = getVersion();
            var iter = std.mem.tokenizeScalar(u8, version, '.');
            _ = iter.next(); // Skip major version
            if (iter.next()) |minor_str| {
                return std.fmt.parseInt(u32, minor_str, 10) catch 0;
            }
            return 0;
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ TEST ══════════════════════════════════════╗

    const testing = std.testing;
    
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
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Library Linkage Tests ────────────────────────────┐
    
        test "unit: GLPKLibrary: verify library is properly linked" {
            // Test that we can call a basic GLPK function without crashing
            // Creating and immediately deleting a problem tests linkage
            const prob = createProblem();
            try testing.expect(prob != null);
            deleteProblem(prob);
        }
        
        test "unit: GLPKVersion: library version string matches expected format" {
            const version = getVersion();
            try testing.expect(version.len > 0);
            
            // Version should contain a dot separator
            const dot_index = std.mem.indexOf(u8, version, ".");
            try testing.expect(dot_index != null);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Version Function Tests ────────────────────────────┐
    
        test "unit: VersionUtils: getVersion returns expected version string" {
            const version = getVersion();
            try testing.expectEqualStrings(EXPECTED_VERSION_STRING, version);
        }
        
        test "unit: VersionUtils: getMajorVersion returns correct major version" {
            const major = getMajorVersion();
            try testing.expectEqual(EXPECTED_MAJOR_VERSION, major);
        }
        
        test "unit: VersionUtils: getMinorVersion returns correct minor version" {
            const minor = getMinorVersion();
            try testing.expectEqual(EXPECTED_MINOR_VERSION, minor);
        }
        
        test "unit: VersionUtils: version functions handle edge cases" {
            // These should not crash even if version format changes
            const version = getVersion();
            const major = getMajorVersion();
            const minor = getMinorVersion();
            
            // Basic sanity checks
            try testing.expect(version.len > 0);
            try testing.expect(major >= 0);
            try testing.expect(minor >= 0);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Problem Management Tests ────────────────────────────┐
    
        test "unit: ProblemManagement: create and delete problem" {
            const prob = createProblem();
            try testing.expect(prob != null);
            
            // Should be able to delete without issues
            deleteProblem(prob);
        }
        
        test "unit: ProblemManagement: set problem name" {
            const prob = createProblem();
            defer deleteProblem(prob);
            
            // Setting problem name should not crash
            setProblemName(prob, TEST_PROBLEM_NAME);
            
            // No direct way to get problem name in basic API,
            // but we can verify it doesn't crash
        }
        
        test "unit: ProblemManagement: set and get objective direction" {
            const prob = createProblem();
            defer deleteProblem(prob);
            
            // Test minimize
            setObjectiveDirection(prob, GLP_MIN);
            try testing.expectEqual(GLP_MIN, getObjectiveDirection(prob));
            
            // Test maximize
            setObjectiveDirection(prob, GLP_MAX);
            try testing.expectEqual(GLP_MAX, getObjectiveDirection(prob));
        }
        
        test "unit: ProblemManagement: multiple problems can coexist" {
            const prob1 = createProblem();
            const prob2 = createProblem();
            const prob3 = createProblem();
            
            try testing.expect(prob1 != null);
            try testing.expect(prob2 != null);
            try testing.expect(prob3 != null);
            try testing.expect(prob1 != prob2);
            try testing.expect(prob2 != prob3);
            try testing.expect(prob1 != prob3);
            
            deleteProblem(prob1);
            deleteProblem(prob2);
            deleteProblem(prob3);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Row Management Tests ────────────────────────────┐
    
        test "unit: RowManagement: add rows to problem" {
            const prob = createProblem();
            defer deleteProblem(prob);
            
            // Initially should have 0 rows
            try testing.expectEqual(@as(c_int, 0), getNumRows(prob));
            
            // Add 3 rows
            const row_index = addRows(prob, 3);
            try testing.expect(row_index > 0);
            try testing.expectEqual(@as(c_int, 3), getNumRows(prob));
            
            // Add 2 more rows
            _ = addRows(prob, 2);
            try testing.expectEqual(@as(c_int, 5), getNumRows(prob));
        }
        
        test "unit: RowManagement: set row properties" {
            const prob = createProblem();
            defer deleteProblem(prob);
            
            const row_idx = addRows(prob, 1);
            
            // Set row name (should not crash)
            setRowName(prob, row_idx, TEST_ROW_NAME);
            
            // Set different types of bounds
            setRowBounds(prob, row_idx, GLP_FX, 10.0, 10.0);  // Fixed
            setRowBounds(prob, row_idx, GLP_LO, 5.0, 0.0);    // Lower bound
            setRowBounds(prob, row_idx, GLP_UP, 0.0, 15.0);   // Upper bound
            setRowBounds(prob, row_idx, GLP_DB, 5.0, 15.0);   // Double bound
            setRowBounds(prob, row_idx, GLP_FR, 0.0, 0.0);    // Free
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Column Management Tests ────────────────────────────┐
    
        test "unit: ColumnManagement: add columns to problem" {
            const prob = createProblem();
            defer deleteProblem(prob);
            
            // Initially should have 0 columns
            try testing.expectEqual(@as(c_int, 0), getNumColumns(prob));
            
            // Add 4 columns
            const col_index = addColumns(prob, 4);
            try testing.expect(col_index > 0);
            try testing.expectEqual(@as(c_int, 4), getNumColumns(prob));
            
            // Add 3 more columns
            _ = addColumns(prob, 3);
            try testing.expectEqual(@as(c_int, 7), getNumColumns(prob));
        }
        
        test "unit: ColumnManagement: set column properties" {
            const prob = createProblem();
            defer deleteProblem(prob);
            
            const col_idx = addColumns(prob, 1);
            
            // Set column name (should not crash)
            setColumnName(prob, col_idx, TEST_COL_NAME);
            
            // Set objective coefficient
            setObjectiveCoef(prob, col_idx, 3.5);
            
            // Set different types of bounds
            setColumnBounds(prob, col_idx, GLP_FX, 10.0, 10.0);  // Fixed
            setColumnBounds(prob, col_idx, GLP_LO, 0.0, 0.0);    // Lower bound
            setColumnBounds(prob, col_idx, GLP_UP, 0.0, 100.0);  // Upper bound
            setColumnBounds(prob, col_idx, GLP_DB, 0.0, 100.0);  // Double bound
            setColumnBounds(prob, col_idx, GLP_FR, 0.0, 0.0);    // Free
            
            // Set column kind
            setColumnKind(prob, col_idx, GLP_CV);  // Continuous
            setColumnKind(prob, col_idx, GLP_IV);  // Integer
            setColumnKind(prob, col_idx, GLP_BV);  // Binary
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Matrix Coefficient Tests ────────────────────────────┐
    
        test "unit: MatrixOperations: set matrix row with 1-based arrays" {
            const prob = createProblem();
            defer deleteProblem(prob);
            
            _ = addRows(prob, 1);
            _ = addColumns(prob, 3);
            
            // Set entire row at once with 1-based arrays (dummy element at index 0)
            var indices = [_]c_int{ 0, 1, 2, 3 };  // 1-based indexing
            var values = [_]f64{ 0, 2.5, 3.0, 1.5 };
            
            setMatrixRow(prob, 1, 3, &indices, &values);
        }
        
        test "unit: MatrixOperations: set matrix column with 1-based arrays" {
            const prob = createProblem();
            defer deleteProblem(prob);
            
            _ = addRows(prob, 3);
            _ = addColumns(prob, 1);
            
            // Set entire column at once with 1-based arrays (dummy element at index 0)
            var indices = [_]c_int{ 0, 1, 2, 3 };  // 1-based indexing
            var values = [_]f64{ 0, 4.0, 2.0, 5.0 };
            
            setMatrixCol(prob, 1, 3, &indices, &values);
        }
        
        test "unit: MatrixOperations: safe set matrix row with 0-based arrays" {
            const prob = createProblem();
            defer deleteProblem(prob);
            
            _ = addRows(prob, 1);
            _ = addColumns(prob, 3);
            
            // Use 0-based arrays with safe wrapper
            const indices = [_]c_int{ 1, 2, 3 };  // 0-based column indices
            const values = [_]f64{ 2.5, 3.0, 1.5 };
            
            try safeSetMatrixRow(testing.allocator, prob, 1, &indices, &values);
        }
        
        test "unit: MatrixOperations: safe set matrix column with 0-based arrays" {
            const prob = createProblem();
            defer deleteProblem(prob);
            
            _ = addRows(prob, 3);
            _ = addColumns(prob, 1);
            
            // Use 0-based arrays with safe wrapper
            const indices = [_]c_int{ 1, 2, 3 };  // 0-based row indices
            const values = [_]f64{ 4.0, 2.0, 5.0 };
            
            try safeSetMatrixCol(testing.allocator, prob, 1, &indices, &values);
        }
        
        test "unit: MatrixOperations: safe wrappers validate array lengths" {
            const prob = createProblem();
            defer deleteProblem(prob);
            
            _ = addRows(prob, 1);
            _ = addColumns(prob, 3);
            
            // Mismatched array lengths should return error
            const indices = [_]c_int{ 1, 2, 3 };
            const values = [_]f64{ 2.5, 3.0 };  // One less value than indices
            
            const result = safeSetMatrixRow(testing.allocator, prob, 1, &indices, &values);
            try testing.expectError(error.MismatchedArrayLengths, result);
        }
        
        test "unit: MatrixOperations: safe wrappers handle empty arrays" {
            const prob = createProblem();
            defer deleteProblem(prob);
            
            _ = addRows(prob, 1);
            _ = addColumns(prob, 3);
            
            // Empty arrays should work
            const indices = [_]c_int{};
            const values = [_]f64{};
            
            try safeSetMatrixRow(testing.allocator, prob, 1, &indices, &values);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Parameter Initialization Tests ────────────────────────────┐
    
        test "unit: Parameters: initialize simplex parameters" {
            var params: SimplexParams = undefined;
            initSimplexParams(&params);
            
            // Check some default values are set
            try testing.expect(params.msg_lev >= GLP_MSG_OFF);
            try testing.expect(params.msg_lev <= GLP_MSG_DBG);
        }
        
        test "unit: Parameters: initialize interior point parameters" {
            var params: InteriorParams = undefined;
            initInteriorParams(&params);
            
            // Just verify it doesn't crash
            try testing.expect(params.msg_lev >= GLP_MSG_OFF);
            try testing.expect(params.msg_lev <= GLP_MSG_DBG);
        }
        
        test "unit: Parameters: initialize MIP parameters" {
            var params: MIPParams = undefined;
            initMIPParams(&params);
            
            // Just verify it doesn't crash
            try testing.expect(params.msg_lev >= GLP_MSG_OFF);
            try testing.expect(params.msg_lev <= GLP_MSG_DBG);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Constants Verification Tests ────────────────────────────┐
    
        test "unit: Constants: optimization direction constants are distinct" {
            try testing.expect(GLP_MIN != GLP_MAX);
        }
        
        test "unit: Constants: variable bound types are distinct" {
            const bounds = [_]c_int{ 
                GLP_FR, 
                GLP_LO, 
                GLP_UP, 
                GLP_DB, 
                GLP_FX 
            };
            
            // Check all bound types are unique
            for (bounds, 0..) |bound1, i| {
                for (bounds[i + 1..]) |bound2| {
                    try testing.expect(bound1 != bound2);
                }
            }
        }
        
        test "unit: Constants: variable kinds are distinct" {
            try testing.expect(GLP_CV != GLP_IV);
            try testing.expect(GLP_CV != GLP_BV);
            try testing.expect(GLP_IV != GLP_BV);
        }
        
        test "unit: Constants: solution status constants are distinct" {
            const statuses = [_]c_int{
                GLP_UNDEF,
                GLP_FEAS,
                GLP_INFEAS,
                GLP_NOFEAS,
                GLP_OPT,
                GLP_UNBND
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
                GLP_MSG_OFF,
                GLP_MSG_ERR,
                GLP_MSG_ON,
                GLP_MSG_ALL,
                GLP_MSG_DBG
            };
            
            // Check all message levels are unique
            for (levels, 0..) |level1, i| {
                for (levels[i + 1..]) |level2| {
                    try testing.expect(level1 != level2);
                }
            }
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════╝