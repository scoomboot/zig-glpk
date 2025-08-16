# Issue #015: Define MIPOptions configuration structure

## Priority
🟡 Medium

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#42-mip-solver-configuration)
- [Issue #010](010_issue.md) - SimplexOptions pattern

## Description
Create a comprehensive configuration structure for the Mixed Integer Programming (MIP) solver. This provides control over branch-and-bound parameters, cutting planes, heuristics, and other MIP-specific solver options.

## Requirements

### File Location
- Add to `lib/core/utils/solver/solver.zig`

### Core MIPOptions Structure
```zig
/// Configuration options for the MIP solver
pub const MIPOptions = struct {
    /// Enable/disable MIP presolver
    presolve: bool = true,
    
    /// Branching technique
    branching: BranchingTechnique = .driebeek_tomlin,
    
    /// Backtracking technique
    backtracking: BacktrackingTechnique = .best_local,
    
    /// Preprocessing level
    preprocessing: PreprocessingLevel = .all,
    
    /// Enable/disable cutting planes
    cuts: CutOptions = .{},
    
    /// Enable/disable feasibility pump heuristic
    feasibility_pump: bool = false,
    
    /// Enable/disable proximity search
    proximity_search: bool = false,
    
    /// Enable/disable rounding heuristic
    rounding_heuristic: bool = true,
    
    /// Time limit in seconds (null = no limit)
    time_limit: ?f64 = null,
    
    /// Relative MIP gap tolerance
    mip_gap: f64 = 0.0,
    
    /// Absolute MIP gap tolerance
    mip_gap_abs: f64 = 0.0,
    
    /// Integer feasibility tolerance
    integer_tolerance: f64 = 1e-5,
    
    /// Upper bound cutoff
    upper_bound: ?f64 = null,
    
    /// Output level
    message_level: MessageLevel = .normal,
    
    /// Output frequency (nodes between messages)
    output_frequency: usize = 100,
    
    /// Memory limit in MB (null = no limit)
    memory_limit: ?usize = null,
    
    /// Number of solutions to find
    solution_limit: ?usize = null,
    
    /// Random seed for reproducibility
    random_seed: ?u32 = null,
    
    /// Convert to GLPK parameter structure
    pub fn toGLPK(self: MIPOptions) glpk.c.glp_iocp {
        var params: glpk.c.glp_iocp = undefined;
        glpk.c.glp_init_iocp(&params);
        
        // Map basic options
        params.presolve = if (self.presolve) glpk.GLP_ON else glpk.GLP_OFF;
        params.br_tech = self.branching.toGLPK();
        params.bt_tech = self.backtracking.toGLPK();
        params.pp_tech = self.preprocessing.toGLPK();
        
        // Map cuts
        params.gmi_cuts = self.cuts.gomory.toGLPK();
        params.mir_cuts = self.cuts.mir.toGLPK();
        params.cov_cuts = self.cuts.cover.toGLPK();
        params.clq_cuts = self.cuts.clique.toGLPK();
        
        // Map heuristics
        params.fp_heur = if (self.feasibility_pump) glpk.GLP_ON else glpk.GLP_OFF;
        params.ps_heur = if (self.proximity_search) glpk.GLP_ON else glpk.GLP_OFF;
        
        // Map gaps and tolerances
        params.mip_gap = self.mip_gap;
        params.tol_int = self.integer_tolerance;
        params.tol_obj = self.mip_gap_abs;
        
        // Map limits
        if (self.time_limit) |limit| {
            params.tm_lim = @intFromFloat(limit * 1000); // Convert to milliseconds
        }
        
        if (self.upper_bound) |bound| {
            params.ub_cutoff = bound;
        }
        
        params.msg_lev = self.message_level.toGLPK();
        params.out_frq = @intCast(self.output_frequency);
        
        return params;
    }
    
    /// Create default options
    pub fn default() MIPOptions {
        return .{};
    }
    
    /// Create options for quick solutions (may be suboptimal)
    pub fn fast() MIPOptions {
        return .{
            .presolve = true,
            .preprocessing = .all,
            .cuts = CutOptions.aggressive(),
            .feasibility_pump = true,
            .proximity_search = true,
            .mip_gap = 0.01, // 1% gap
            .message_level = .errors_only,
        };
    }
    
    /// Create options for optimal solutions
    pub fn exact() MIPOptions {
        return .{
            .presolve = true,
            .preprocessing = .all,
            .cuts = CutOptions.aggressive(),
            .mip_gap = 0.0,
            .integer_tolerance = 1e-9,
            .message_level = .normal,
        };
    }
    
    /// Create options for debugging
    pub fn debug() MIPOptions {
        return .{
            .message_level = .all,
            .output_frequency = 1,
            .random_seed = 42, // Fixed seed for reproducibility
        };
    }
};
```

### Supporting Types
```zig
pub const BranchingTechnique = enum {
    first_fractional,   // First fractional variable
    last_fractional,    // Last fractional variable
    most_fractional,    // Most fractional variable
    driebeek_tomlin,    // Driebeek-Tomlin heuristic
    hybrid,             // Hybrid pseudocost
    
    pub fn toGLPK(self: @This()) c_int {
        return switch (self) {
            .first_fractional => glpk.GLP_BR_FFV,
            .last_fractional => glpk.GLP_BR_LFV,
            .most_fractional => glpk.GLP_BR_MFV,
            .driebeek_tomlin => glpk.GLP_BR_DTH,
            .hybrid => glpk.GLP_BR_PCH,
        };
    }
};

pub const BacktrackingTechnique = enum {
    depth_first,       // Depth first search
    breadth_first,     // Breadth first search
    best_local,        // Best local bound
    best_projection,   // Best projection heuristic
    
    pub fn toGLPK(self: @This()) c_int {
        return switch (self) {
            .depth_first => glpk.GLP_BT_DFS,
            .breadth_first => glpk.GLP_BT_BFS,
            .best_local => glpk.GLP_BT_BLB,
            .best_projection => glpk.GLP_BT_BPH,
        };
    }
};

pub const PreprocessingLevel = enum {
    none,   // No preprocessing
    root,   // Only at root node
    all,    // All nodes
    
    pub fn toGLPK(self: @This()) c_int {
        return switch (self) {
            .none => glpk.GLP_PP_NONE,
            .root => glpk.GLP_PP_ROOT,
            .all => glpk.GLP_PP_ALL,
        };
    }
};

pub const CutLevel = enum {
    off,         // Disabled
    on,          // Enabled
    aggressive,  // Aggressive generation
    
    pub fn toGLPK(self: @This()) c_int {
        return switch (self) {
            .off => glpk.GLP_OFF,
            .on => glpk.GLP_ON,
            .aggressive => glpk.GLP_ON, // GLPK doesn't have aggressive mode
        };
    }
};

pub const CutOptions = struct {
    /// Gomory mixed integer cuts
    gomory: CutLevel = .on,
    
    /// Mixed integer rounding cuts
    mir: CutLevel = .on,
    
    /// Mixed cover cuts
    cover: CutLevel = .on,
    
    /// Clique cuts
    clique: CutLevel = .on,
    
    /// Create with all cuts disabled
    pub fn none() CutOptions {
        return .{
            .gomory = .off,
            .mir = .off,
            .cover = .off,
            .clique = .off,
        };
    }
    
    /// Create with aggressive cut generation
    pub fn aggressive() CutOptions {
        return .{
            .gomory = .aggressive,
            .mir = .aggressive,
            .cover = .aggressive,
            .clique = .aggressive,
        };
    }
};
```

### MIP-Specific Callbacks (Advanced)
```zig
/// Callback function types for MIP solver events
pub const MIPCallback = struct {
    /// Called when a new integer feasible solution is found
    on_solution: ?*const fn (problem: *Problem, solution: []const f64) void = null,
    
    /// Called periodically during branch-and-bound
    on_progress: ?*const fn (info: ProgressInfo) void = null,
    
    /// Called to allow user cuts
    on_cut_generation: ?*const fn (problem: *Problem) void = null,
    
    /// Called for custom branching decisions
    on_branching: ?*const fn (problem: *Problem, fractional_vars: []const usize) usize = null,
};

pub const ProgressInfo = struct {
    best_bound: f64,      // Best lower/upper bound
    best_integer: ?f64,   // Best integer solution value
    gap: f64,            // Current MIP gap
    nodes_explored: usize,
    nodes_remaining: usize,
    time_elapsed: f64,
};
```

### Validation
```zig
impl MIPOptions {
    /// Validate options for correctness
    pub fn validate(self: MIPOptions) !void {
        if (self.mip_gap < 0 or self.mip_gap >= 1) {
            return error.InvalidMIPGap;
        }
        if (self.integer_tolerance <= 0 or self.integer_tolerance >= 0.1) {
            return error.InvalidIntegerTolerance;
        }
        if (self.time_limit) |limit| {
            if (limit <= 0) return error.InvalidTimeLimit;
        }
        if (self.memory_limit) |limit| {
            if (limit == 0) return error.InvalidMemoryLimit;
        }
    }
}
```

## Implementation Notes
- MIP solving is much more complex than LP
- Branch-and-bound explores a tree of subproblems
- Cuts can significantly improve performance
- Heuristics help find good solutions quickly
- Gap tolerance allows early termination with good solutions
- Some GLPK parameters may not map exactly to our options

## Testing Requirements
- Test default options creation
- Test conversion to GLPK parameters
- Test preset configurations
- Test validation of invalid parameters
- Test cut options configuration
- Verify all enums convert correctly
- Test that options affect solver behavior

## Dependencies
- [#010](010_issue.md) - Similar pattern to SimplexOptions

## Acceptance Criteria
- [ ] MIPOptions struct defined with all fields
- [ ] Supporting enums defined with conversions
- [ ] Cut options configurable
- [ ] toGLPK() method maps all options
- [ ] Preset configurations available
- [ ] Validation catches invalid parameters
- [ ] Tests cover option combinations
- [ ] Documentation explains options
- [ ] Callbacks structure defined (even if not implemented)

## Status
🟡 Not Started