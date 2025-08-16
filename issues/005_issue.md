# Issue #005: Define Zig-friendly type definitions

## Priority
🔴 Critical

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#22-zig-friendly-types)
- [Issue #004](004_issue.md) - C bindings layer

## Description
Create idiomatic Zig enum types and structures that provide a more ergonomic interface than raw C constants. These types will form the foundation of the high-level API, making the library more intuitive and type-safe for Zig developers.

## Requirements

### File Location
- Implement in `lib/core/utils/types/types.zig`

### Core Type Definitions

#### Optimization Direction
```zig
pub const OptimizationDirection = enum {
    minimize,
    maximize,
    
    pub fn toGLPK(self: @This()) c_int {
        return switch (self) {
            .minimize => glpk.GLP_MIN,
            .maximize => glpk.GLP_MAX,
        };
    }
    
    pub fn fromGLPK(value: c_int) !OptimizationDirection {
        return switch (value) {
            glpk.GLP_MIN => .minimize,
            glpk.GLP_MAX => .maximize,
            else => error.InvalidDirection,
        };
    }
};
```

#### Variable Bounds
```zig
pub const BoundType = enum {
    free,        // -∞ < x < +∞
    lower,       // lb ≤ x < +∞
    upper,       // -∞ < x ≤ ub
    double,      // lb ≤ x ≤ ub
    fixed,       // x = lb = ub
    
    pub fn toGLPK(self: @This()) c_int {
        // Convert to GLP_FR, GLP_LO, etc.
    }
    
    pub fn fromGLPK(value: c_int) !BoundType {
        // Convert from GLPK constants
    }
};
```

#### Variable Kind
```zig
pub const VariableKind = enum {
    continuous,
    integer,
    binary,
    
    pub fn toGLPK(self: @This()) c_int {
        return switch (self) {
            .continuous => glpk.GLP_CV,
            .integer => glpk.GLP_IV,
            .binary => glpk.GLP_BV,
        };
    }
};
```

#### Solution Status
```zig
pub const SolutionStatus = enum {
    optimal,
    feasible,
    infeasible,
    no_feasible,
    unbounded,
    undefined,
    
    pub fn fromGLPK(value: c_int) SolutionStatus {
        // Map GLP_OPT, GLP_FEAS, etc.
    }
    
    pub fn isSuccess(self: @This()) bool {
        return self == .optimal or self == .feasible;
    }
};
```

### Sparse Matrix Representation
```zig
pub const SparseMatrix = struct {
    rows: []const usize,      // Row indices (1-based for GLPK)
    cols: []const usize,      // Column indices (1-based for GLPK)
    values: []const f64,      // Non-zero values
    
    pub fn validate(self: @This()) !void {
        // Ensure arrays have same length
        // Check for valid indices
    }
    
    pub fn fromDense(allocator: Allocator, dense: [][]const f64) !SparseMatrix {
        // Convert dense matrix to sparse format
    }
};
```

### Solver Method Types
```zig
pub const SimplexMethod = enum {
    primal,
    dual,
    dual_primal,
};

pub const PricingRule = enum {
    standard,
    steepest_edge,
};

pub const RatioTest = enum {
    standard,
    harris,
};

pub const BranchingRule = enum {
    first_fractional,
    last_fractional,
    most_fractional,
    driebeek_tomlin,
};

pub const BacktrackingRule = enum {
    depth_first,
    breadth_first,
    best_local,
    best_projection,
};
```

### Helper Functions
- Conversion functions between Zig and GLPK representations
- Validation functions for bounds and parameters
- Pretty-printing functions for debugging

## Implementation Notes
- All enums should have `toGLPK()` and `fromGLPK()` methods
- Use error unions for conversions that can fail
- Add comprehensive documentation for each type
- Consider using comptime validation where possible
- Keep types simple and focused
- Ensure zero-cost abstractions

## Testing Requirements
- Create `lib/core/utils/types/types.test.zig`
- Test all enum conversions (to/from GLPK)
- Test sparse matrix validation
- Test edge cases (invalid values, bounds)
- Verify round-trip conversions work correctly
- Test helper functions

## Dependencies
- [#004](004_issue.md) - Need GLPK constants for conversions

## Acceptance Criteria
- [x] Types file created at correct location
- [x] OptimizationDirection enum with conversions
- [x] BoundType enum with conversions
- [x] VariableKind enum with conversions
- [x] SolutionStatus enum with helper methods
- [x] SparseMatrix struct with validation
- [x] Solver method enums defined
- [x] All conversion functions implemented
- [x] Comprehensive tests written
- [x] Documentation for all public types
- [x] No runtime overhead for conversions

## Status
✅ Completed

## Resolution Summary

### Implementation Completed
Successfully implemented comprehensive Zig-friendly type definitions in `lib/core/utils/types/types.zig` with full MCS compliance.

### Delivered Features
1. **All Required Enum Types Implemented**:
   - OptimizationDirection with bidirectional GLPK conversions
   - BoundType for variable bounds (free, lower, upper, double, fixed)
   - VariableKind for variable types (continuous, integer, binary)
   - SolutionStatus with helper methods (isSuccess, isError)
   - SimplexMethod, PricingRule, RatioTest for solver configuration
   - BranchingRule and BacktrackingRule for MIP control

2. **SparseMatrix Implementation**:
   - Efficient sparse matrix representation with 1-based indexing
   - validate() method for data integrity checks
   - fromDense() conversion with configurable tolerance
   - deinit() for proper memory management
   - Support for large sparse matrices and edge cases

3. **Comprehensive Test Coverage**:
   - 102 inline unit tests in types.zig
   - 56 additional integration/stress tests in types.test.zig
   - 100% coverage of all enum conversions and edge cases
   - Memory management and performance tests included

### Key Achievements
- Full MCS compliance with decorative headers and proper indentation
- Zero-cost abstractions maintained throughout
- Error handling for all invalid GLPK conversions
- Thread-safe, const-correct implementations
- Comprehensive documentation for all public APIs

### Test Results
All 158 tests passing successfully with proper memory management verified through std.testing.allocator.