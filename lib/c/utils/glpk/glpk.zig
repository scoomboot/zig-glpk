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
    
    // ┌──────────────────────────── Preprocessing Options ────────────────────────────┐
    
        /// Preprocessing: off
        pub const GLP_OFF = c.GLP_OFF;
        
        /// Preprocessing: on
        pub const GLP_ON = c.GLP_ON;
    
    // └──────────────────────────────────────────────────────────────────────────────┘

    
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
        
        /// Set row of the constraint matrix
        pub fn setMatrixRow(prob: ?*c.glp_prob, i: c_int, len: c_int, ind: [*c]const c_int, val: [*c]const f64) void {
            c.glp_set_mat_row(prob, i, len, ind, val);
        }
        
        /// Set column of the constraint matrix
        pub fn setMatrixCol(prob: ?*c.glp_prob, j: c_int, len: c_int, ind: [*c]const c_int, val: [*c]const f64) void {
            c.glp_set_mat_col(prob, j, len, ind, val);
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

// ╚══════════════════════════════════════════════════════════════════════════════════════╝