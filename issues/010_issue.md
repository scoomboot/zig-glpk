# Issue #010: Define SimplexOptions configuration structure

## Priority
🔴 Critical

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#31-simplex-solver-configuration)
- [Issue #005](005_issue.md) - Type definitions

## Description
Create a comprehensive configuration structure for the Simplex solver that allows users to control various algorithmic parameters and solver behavior. This provides a clean, type-safe interface for configuring GLPK's simplex method.

## Requirements

### File Location
- Implement in `lib/core/utils/solver/solver.zig`

### Core SimplexOptions Structure
```zig
/// Configuration options for the Simplex LP solver
pub const SimplexOptions = struct {
    /// Enable/disable presolver
    presolve: bool = true,
    
    /// Simplex method variant
    method: SimplexMethod = .dual_primal,
    
    /// Pricing rule for selecting entering variable
    pricing: PricingRule = .steepest_edge,
    
    /// Ratio test method for selecting leaving variable
    ratio_test: RatioTest = .harris,
    
    /// Time limit in seconds (null = no limit)
    time_limit: ?f64 = null,
    
    /// Iteration limit (null = no limit)
    iteration_limit: ?usize = null,
    
    /// Output level
    message_level: MessageLevel = .errors_only,
    
    /// Output frequency (iterations between messages)
    output_frequency: usize = 200,
    
    /// Feasibility tolerance
    feasibility_tolerance: f64 = 1e-7,
    
    /// Optimality tolerance
    optimality_tolerance: f64 = 1e-7,
    
    /// Pivot tolerance
    pivot_tolerance: f64 = 1e-10,
    
    /// Perturbation for degenerate problems
    perturbation: f64 = 1e-6,
    
    /// Scaling options
    scaling: ScalingOption = .geometric_mean,
    
    /// Convert to GLPK parameter structure
    pub fn toGLPK(self: SimplexOptions) glpk.c.glp_smcp {
        var params: glpk.c.glp_smcp = undefined;
        glpk.c.glp_init_smcp(&params);
        
        // Map options to GLPK parameters
        params.msg_lev = self.message_level.toGLPK();
        params.meth = self.method.toGLPK();
        params.pricing = self.pricing.toGLPK();
        params.r_test = self.ratio_test.toGLPK();
        
        if (self.time_limit) |limit| {
            params.tm_lim = @intFromFloat(limit * 1000); // Convert to milliseconds
        }
        
        if (self.iteration_limit) |limit| {
            params.it_lim = @intCast(limit);
        }
        
        params.presolve = if (self.presolve) glpk.GLP_ON else glpk.GLP_OFF;
        params.tol_bnd = self.feasibility_tolerance;
        params.tol_dj = self.optimality_tolerance;
        params.tol_piv = self.pivot_tolerance;
        
        return params;
    }
    
    /// Create default options for production use
    pub fn default() SimplexOptions {
        return .{};
    }
    
    /// Create options optimized for speed
    pub fn fast() SimplexOptions {
        return .{
            .presolve = true,
            .method = .dual,
            .pricing = .steepest_edge,
            .message_level = .none,
        };
    }
    
    /// Create options for debugging
    pub fn debug() SimplexOptions {
        return .{
            .message_level = .all,
            .output_frequency = 1,
        };
    }
};
```

### Supporting Enums
```zig
pub const SimplexMethod = enum {
    primal,      // Primal simplex
    dual,        // Dual simplex
    dual_primal, // Dual, then primal if that fails
    
    pub fn toGLPK(self: @This()) c_int {
        return switch (self) {
            .primal => glpk.GLP_PRIMAL,
            .dual => glpk.GLP_DUAL,
            .dual_primal => glpk.GLP_DUALP,
        };
    }
};

pub const PricingRule = enum {
    standard,      // Standard (textbook)
    steepest_edge, // Steepest edge (recommended)
    
    pub fn toGLPK(self: @This()) c_int {
        return switch (self) {
            .standard => glpk.GLP_PT_STD,
            .steepest_edge => glpk.GLP_PT_PSE,
        };
    }
};

pub const RatioTest = enum {
    standard, // Standard (textbook)
    harris,   // Harris' two-pass ratio test
    
    pub fn toGLPK(self: @This()) c_int {
        return switch (self) {
            .standard => glpk.GLP_RT_STD,
            .harris => glpk.GLP_RT_HAR,
        };
    }
};

pub const MessageLevel = enum {
    none,        // No output
    errors_only, // Error messages only
    normal,      // Normal output
    all,         // Full output
    
    pub fn toGLPK(self: @This()) c_int {
        return switch (self) {
            .none => glpk.GLP_MSG_OFF,
            .errors_only => glpk.GLP_MSG_ERR,
            .normal => glpk.GLP_MSG_ON,
            .all => glpk.GLP_MSG_ALL,
        };
    }
};

pub const ScalingOption = enum {
    none,           // No scaling
    equilibration,  // Equilibration scaling
    geometric_mean, // Geometric mean scaling
    auto,          // Automatic choice
    
    pub fn toGLPK(self: @This()) c_int {
        return switch (self) {
            .none => glpk.GLP_SF_SKIP,
            .equilibration => glpk.GLP_SF_EQ,
            .geometric_mean => glpk.GLP_SF_GM,
            .auto => glpk.GLP_SF_AUTO,
        };
    }
};
```

### Validation Methods
```zig
impl SimplexOptions {
    /// Validate options for correctness
    pub fn validate(self: SimplexOptions) !void {
        if (self.feasibility_tolerance <= 0) {
            return error.InvalidFeasibilityTolerance;
        }
        if (self.optimality_tolerance <= 0) {
            return error.InvalidOptimalityTolerance;
        }
        if (self.pivot_tolerance <= 0 or self.pivot_tolerance >= 1) {
            return error.InvalidPivotTolerance;
        }
        if (self.time_limit) |limit| {
            if (limit <= 0) return error.InvalidTimeLimit;
        }
        if (self.iteration_limit) |limit| {
            if (limit == 0) return error.InvalidIterationLimit;
        }
    }
}
```

## Implementation Notes
- Default values should match GLPK's recommended settings
- Provide convenience constructors for common use cases
- Consider adding a builder pattern for complex configurations
- Document which options are most important for performance
- Some GLPK parameters may not need to be exposed initially

## Testing Requirements
- Test default options creation
- Test conversion to GLPK parameter structure
- Test validation of invalid parameters
- Test preset configurations (fast, debug)
- Verify all enums convert correctly to GLPK constants
- Test that options are properly applied when solving

## Dependencies
- [#005](005_issue.md) - Need type definitions for enums

## Acceptance Criteria
- [ ] SimplexOptions struct defined with all fields
- [ ] Supporting enums defined with GLPK conversions
- [ ] toGLPK() method properly maps all options
- [ ] Preset configurations available (default, fast, debug)
- [ ] Validation method catches invalid parameters
- [ ] Tests cover all option combinations
- [ ] Documentation explains each option's effect
- [ ] Default values are sensible
- [ ] All GLPK simplex parameters mapped

## Status
🔴 Not Started