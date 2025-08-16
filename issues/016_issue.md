# Issue #016: Implement MIPSolver with solve method

## Priority
🔴 Critical

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#43-mip-solver-implementation)
- [Issue #011](011_issue.md) - SimplexSolver pattern
- [Issue #014](014_issue.md) - MIP extensions
- [Issue #015](015_issue.md) - MIPOptions

## Description
Implement the MIPSolver struct that uses GLPK's branch-and-cut algorithm to solve Mixed Integer Programming problems. This solver handles problems with integer and binary variables in addition to continuous variables.

## Requirements

### File Location
- Continue in `lib/core/utils/solver/solver.zig`

### MIPSolver Implementation
```zig
/// Mixed Integer Programming solver
pub const MIPSolver = struct {
    options: MIPOptions,
    stats: ?MIPStats = null,
    callbacks: ?MIPCallback = null,
    
    /// Create a new MIP solver with given options
    pub fn init(options: MIPOptions) MIPSolver {
        return .{
            .options = options,
            .stats = null,
            .callbacks = null,
        };
    }
    
    /// Create with default options
    pub fn initDefault() MIPSolver {
        return init(MIPOptions.default());
    }
    
    /// Set callbacks for solver events
    pub fn setCallbacks(self: *MIPSolver, callbacks: MIPCallback) void {
        self.callbacks = callbacks;
    }
    
    /// Solve the MIP problem
    pub fn solve(self: *MIPSolver, problem: *Problem) !SolutionStatus {
        // Validate that problem has integer variables
        if (!problem.hasIntegerVariables()) {
            return error.NotMIPProblem;
        }
        
        // Validate options
        try self.options.validate();
        
        // First solve LP relaxation with simplex
        var simplex_params = glpk.c.glp_smcp{};
        glpk.c.glp_init_smcp(&simplex_params);
        simplex_params.msg_lev = glpk.GLP_MSG_OFF; // Quiet during relaxation
        
        const lp_ret = glpk.c.glp_simplex(problem.ptr, &simplex_params);
        if (lp_ret != 0) {
            // LP relaxation failed
            switch (lp_ret) {
                glpk.GLP_EBOUND => return error.InvalidBounds,
                glpk.GLP_EROOT => return error.LPRelaxationInfeasible,
                glpk.GLP_ENOPFS => return error.NoPrimalFeasible,
                glpk.GLP_ENODFS => return error.NoDualFeasible,
                else => return error.LPRelaxationFailed,
            }
        }
        
        // Check LP relaxation status
        const lp_status = glpk.c.glp_get_status(problem.ptr);
        if (lp_status == glpk.GLP_NOFEAS) {
            self.stats = MIPStats{
                .status = .infeasible,
                .nodes_explored = 0,
                .gap = 0,
                .solve_time = 0,
                .lp_relaxation_value = null,
                .best_bound = null,
                .best_integer = null,
            };
            return .infeasible;
        }
        
        if (lp_status == glpk.GLP_UNBND) {
            self.stats = MIPStats{
                .status = .unbounded,
                .nodes_explored = 0,
                .gap = 0,
                .solve_time = 0,
                .lp_relaxation_value = null,
                .best_bound = null,
                .best_integer = null,
            };
            return .unbounded;
        }
        
        const lp_value = glpk.c.glp_get_obj_val(problem.ptr);
        
        // Convert options to GLPK format
        var params = self.options.toGLPK();
        
        // Set up callback if provided
        if (self.callbacks) |cb| {
            // Note: GLPK callback API is complex
            // Would need to set glp_ios_callback here
        }
        
        // Solve MIP with branch-and-cut
        const mip_ret = glpk.c.glp_intopt(problem.ptr, &params);
        
        // Handle return codes
        switch (mip_ret) {
            0 => {}, // Success or stopped by limits
            glpk.GLP_EBOUND => return error.InvalidBounds,
            glpk.GLP_EROOT => return error.NoIntegerFeasible,
            glpk.GLP_ENOPFS => return error.NoPrimalFeasible,
            glpk.GLP_ENODFS => return error.NoDualFeasible,
            glpk.GLP_EFAIL => return error.SolverFailed,
            glpk.GLP_EMIPGAP => {}, // Gap limit reached (not an error)
            glpk.GLP_ETMLIM => {}, // Time limit reached (not an error)
            glpk.GLP_ESTOP => {}, // Stopped by callback (not an error)
            else => return error.UnknownError,
        }
        
        // Get MIP solution status
        const mip_status = glpk.c.glp_mip_status(problem.ptr);
        const solution_status = types.SolutionStatus.fromGLPKMIP(mip_status);
        
        // Collect statistics
        const obj_val = if (solution_status != .undefined) 
            glpk.c.glp_mip_obj_val(problem.ptr) else null;
        
        self.stats = MIPStats{
            .status = solution_status,
            .nodes_explored = 0, // TODO: Get from GLPK if available
            .gap = if (obj_val) |val| self.computeGap(val, lp_value) else 0,
            .solve_time = 0, // TODO: Get actual time
            .lp_relaxation_value = lp_value,
            .best_bound = lp_value, // TODO: Get actual bound from tree
            .best_integer = obj_val,
        };
        
        return solution_status;
    }
    
    /// Compute MIP gap
    fn computeGap(self: *const MIPSolver, integer_obj: f64, bound: f64) f64 {
        if (@abs(integer_obj) < 1e-10) {
            return @abs(bound - integer_obj);
        }
        return @abs(bound - integer_obj) / @abs(integer_obj);
    }
    
    /// Get solver statistics
    pub fn getStats(self: *const MIPSolver) ?MIPStats {
        return self.stats;
    }
    
    /// Check if solution is optimal
    pub fn isOptimal(self: *const MIPSolver) bool {
        if (self.stats) |stats| {
            return stats.status == .optimal;
        }
        return false;
    }
    
    /// Check if solution meets gap tolerance
    pub fn isWithinGap(self: *const MIPSolver) bool {
        if (self.stats) |stats| {
            return stats.gap <= self.options.mip_gap;
        }
        return false;
    }
};
```

### MIP Statistics
```zig
/// Statistics specific to MIP solving
pub const MIPStats = struct {
    status: types.SolutionStatus,
    nodes_explored: usize,
    gap: f64,                    // Current MIP gap
    solve_time: f64,             // Total time in seconds
    lp_relaxation_value: ?f64,   // LP relaxation objective
    best_bound: ?f64,            // Best bound from tree
    best_integer: ?f64,          // Best integer solution found
    
    pub fn print(self: MIPStats, writer: anytype) !void {
        try writer.print("MIP Solver Statistics:\n", .{});
        try writer.print("  Status: {s}\n", .{@tagName(self.status)});
        try writer.print("  Nodes explored: {}\n", .{self.nodes_explored});
        
        if (self.lp_relaxation_value) |lp| {
            try writer.print("  LP relaxation: {d:.6}\n", .{lp});
        }
        
        if (self.best_integer) |best| {
            try writer.print("  Best integer: {d:.6}\n", .{best});
            try writer.print("  MIP gap: {d:.2%}\n", .{self.gap});
        }
        
        try writer.print("  Time: {d:.3}s\n", .{self.solve_time});
    }
};
```

### Solution Pool (Advanced)
```zig
/// Pool of integer feasible solutions
pub const SolutionPool = struct {
    solutions: std.ArrayList(MIPSolution),
    max_solutions: usize,
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator, max_solutions: usize) SolutionPool {
        return .{
            .solutions = std.ArrayList(MIPSolution).init(allocator),
            .max_solutions = max_solutions,
            .allocator = allocator,
        };
    }
    
    pub fn deinit(self: *SolutionPool) void {
        for (self.solutions.items) |*sol| {
            sol.deinit();
        }
        self.solutions.deinit();
    }
    
    pub fn addSolution(self: *SolutionPool, problem: *const Problem) !void {
        if (self.solutions.items.len >= self.max_solutions) {
            // Remove worst solution or skip
            return;
        }
        
        var solution = try MIPSolution.fromProblem(problem, self.allocator);
        try self.solutions.append(solution);
    }
    
    pub fn getBestSolution(self: *const SolutionPool) ?*const MIPSolution {
        if (self.solutions.items.len == 0) return null;
        
        var best: *const MIPSolution = &self.solutions.items[0];
        for (self.solutions.items[1..]) |*sol| {
            if (sol.objective_value < best.objective_value) { // Assuming minimization
                best = sol;
            }
        }
        return best;
    }
};

pub const MIPSolution = struct {
    objective_value: f64,
    variable_values: []f64,
    allocator: std.mem.Allocator,
    
    pub fn fromProblem(problem: *const Problem, allocator: std.mem.Allocator) !MIPSolution {
        const n_cols = problem.getColumnCount();
        var values = try allocator.alloc(f64, n_cols);
        
        for (1..n_cols + 1) |i| {
            values[i - 1] = problem.getMIPColumnValue(i);
        }
        
        return .{
            .objective_value = problem.getMIPObjectiveValue(),
            .variable_values = values,
            .allocator = allocator,
        };
    }
    
    pub fn deinit(self: *MIPSolution) void {
        self.allocator.free(self.variable_values);
    }
};
```

## Implementation Notes
- MIP solving is a two-phase process: LP relaxation then branch-and-cut
- LP relaxation must be feasible for MIP to proceed
- Branch-and-cut explores a tree of subproblems
- Early termination is common (gap tolerance, time limit)
- Solution quality depends heavily on options
- Callbacks would allow custom cuts and heuristics

## Testing Requirements
- Test pure binary problems
- Test pure integer problems
- Test mixed integer problems
- Test infeasible MIP problems
- Test unbounded MIP problems
- Test gap tolerance termination
- Test time limit termination
- Test solution quality with different options
- Compare with known optimal solutions

## Dependencies
- [#011](011_issue.md) - Need simplex for LP relaxation
- [#014](014_issue.md) - MIP problem setup
- [#015](015_issue.md) - MIPOptions configuration

## Acceptance Criteria
- [ ] MIPSolver struct implemented
- [ ] solve() handles LP relaxation phase
- [ ] solve() handles branch-and-cut phase
- [ ] All GLPK return codes handled
- [ ] MIP statistics collected
- [ ] Gap computation correct
- [ ] Solution status determined correctly
- [ ] Tests cover various MIP types
- [ ] Documentation explains MIP solving
- [ ] Performance acceptable for test problems

## Status
🔴 Not Started