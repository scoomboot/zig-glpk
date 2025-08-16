# Issue #004: Implement C bindings layer for GLPK

## Priority
🔴 Critical

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#21-c-bindings-layer)
- [Issue #002](002_issue.md) - Project structure
- [Issue #003](003_issue.md) - Build configuration

## Description
Create the foundational C bindings layer that imports the GLPK C API and re-exports commonly used constants and functions. This layer provides the low-level interface that the rest of the wrapper will build upon.

## Requirements

### File Location
- Implement in `lib/c/utils/glpk/glpk.zig`

### Core Implementation
```zig
// Import GLPK C API
pub const c = @cImport({
    @cInclude("glpk.h");
});

// Re-export common constants for optimization direction
pub const GLP_MIN = c.GLP_MIN;  // Minimization
pub const GLP_MAX = c.GLP_MAX;  // Maximization

// Re-export variable bound types
pub const GLP_FR = c.GLP_FR;   // Free variable (-∞ < x < +∞)
pub const GLP_LO = c.GLP_LO;   // Lower bound (lb ≤ x < +∞)
pub const GLP_UP = c.GLP_UP;   // Upper bound (-∞ < x ≤ ub)
pub const GLP_DB = c.GLP_DB;   // Double bound (lb ≤ x ≤ ub)
pub const GLP_FX = c.GLP_FX;   // Fixed variable (x = lb = ub)

// Re-export variable kinds
pub const GLP_CV = c.GLP_CV;   // Continuous variable
pub const GLP_IV = c.GLP_IV;   // Integer variable
pub const GLP_BV = c.GLP_BV;   // Binary variable

// Re-export solution status codes
pub const GLP_OPT = c.GLP_OPT;     // Optimal
pub const GLP_FEAS = c.GLP_FEAS;   // Feasible
pub const GLP_INFEAS = c.GLP_INFEAS; // Infeasible
pub const GLP_NOFEAS = c.GLP_NOFEAS; // No feasible solution
pub const GLP_UNBND = c.GLP_UNBND;   // Unbounded
pub const GLP_UNDEF = c.GLP_UNDEF;   // Undefined
```

### Additional Constants to Export
- Solver method options (primal, dual, etc.)
- Message level constants for output control
- Basis status indicators
- MIP-specific constants
- Error codes

### Type Definitions
- Re-export the `glp_prob` opaque type
- Document any GLPK structs that need to be exposed
- Consider wrapping complex C structs if needed

### Safety Considerations
- Document which GLPK functions are thread-safe
- Note any global state in GLPK
- Identify functions that can fail and their error conditions
- Document memory ownership rules for GLPK objects

## Implementation Notes
- This is a thin wrapper - avoid adding logic here
- Focus on making C constants and types available to Zig
- Document the purpose of each exported constant
- Group related constants together
- Use Zig's `@cImport` mechanism properly
- Consider compile-time verification of constant values

## Testing Requirements
- Create `lib/c/utils/glpk/glpk.test.zig`
- Verify all constants are properly imported
- Test that `@cImport` succeeds
- Verify constant values match GLPK documentation
- Test creating and destroying a basic `glp_prob`
- Ensure no compilation errors when importing the module

## Dependencies
- [#002](002_issue.md) - Project structure must exist
- [#003](003_issue.md) - Build must be configured for GLPK

## Acceptance Criteria
- [ ] C bindings file created at correct location
- [ ] GLPK C API successfully imported via `@cImport`
- [ ] All optimization direction constants exported
- [ ] All variable bound type constants exported
- [ ] All variable kind constants exported
- [ ] Solution status constants exported
- [ ] Test file created with basic validation
- [ ] Module can be imported without errors
- [ ] Documentation comments for all exports
- [ ] Thread safety notes documented

## Status
✅ Completed

## Resolution Summary

### Implementation Completed
Successfully implemented comprehensive GLPK C bindings in `lib/c/utils/glpk/glpk.zig` during the resolution of Issue #001.

### Delivered Features
1. **Complete C API Import**: Using `@cImport` to include glpk.h
2. **All Required Constants Exported**: 
   - Optimization directions (GLP_MIN, GLP_MAX)
   - Variable bounds (GLP_FR, GLP_LO, GLP_UP, GLP_DB, GLP_FX)
   - Variable kinds (GLP_CV, GLP_IV, GLP_BV)
   - Solution status codes (all variants)
   - Solver parameters and preprocessing options
3. **Core Functions Wrapped**: All essential GLPK functions properly wrapped
4. **Type Aliases**: Problem, SimplexParams, InteriorParams, MIPParams
5. **Version Utilities**: getVersion(), getMajorVersion(), getMinorVersion()
6. **MCS Compliant**: Full compliance with Maysara Code Style guidelines

### Test Coverage
Comprehensive test suite implemented in `glpk.test.zig` with 11 test categories covering:
- Library linkage verification
- Version function testing
- Problem management operations
- Integration tests with LP solving
- Memory management validation
- Constants verification

All tests passing successfully.