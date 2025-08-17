# Issue #006: Implement Problem struct with basic management

## Priority
🔴 Critical

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#23-problem-structure)
- [Issue #004](004_issue.md) - C bindings layer
- [Issue #005](005_issue.md) - Type definitions

## Description
Create the core `Problem` struct that wraps a GLPK problem instance and provides basic management functionality. This is the central data structure users will interact with to define and solve optimization problems.

## Requirements

### File Location
- Implement in `lib/core/utils/problem/problem.zig`

### Core Problem Structure
```zig
const std = @import("std");
const glpk = @import("../../c/utils/glpk/glpk.zig");
const types = @import("../types/types.zig");

pub const Problem = struct {
    ptr: *glpk.c.glp_prob,
    allocator: std.mem.Allocator,
    name: ?[]const u8,
    
    /// Create a new optimization problem
    pub fn init(allocator: std.mem.Allocator) !Problem {
        const ptr = glpk.c.glp_create_prob() orelse return error.OutOfMemory;
        return Problem{
            .ptr = ptr,
            .allocator = allocator,
            .name = null,
        };
    }
    
    /// Free all resources associated with the problem
    pub fn deinit(self: *Problem) void {
        glpk.c.glp_delete_prob(self.ptr);
        if (self.name) |n| {
            self.allocator.free(n);
        }
    }
    
    /// Set the problem name
    pub fn setName(self: *Problem, name: []const u8) !void {
        // Duplicate string and store
        // Call glp_set_prob_name
    }
    
    /// Set optimization direction (minimize/maximize)
    pub fn setObjectiveDirection(self: *Problem, dir: types.OptimizationDirection) void {
        glpk.c.glp_set_obj_dir(self.ptr, dir.toGLPK());
    }
    
    /// Get the current number of rows (constraints)
    pub fn getRowCount(self: *const Problem) usize {
        return @intCast(glpk.c.glp_get_num_rows(self.ptr));
    }
    
    /// Get the current number of columns (variables)
    pub fn getColumnCount(self: *const Problem) usize {
        return @intCast(glpk.c.glp_get_num_cols(self.ptr));
    }
    
    /// Get the current number of non-zero coefficients
    pub fn getNonZeroCount(self: *const Problem) usize {
        return @intCast(glpk.c.glp_get_num_nz(self.ptr));
    }
    
    /// Clear the problem (remove all rows and columns)
    pub fn clear(self: *Problem) void {
        glpk.c.glp_erase_prob(self.ptr);
    }
    
    /// Set the objective function name
    pub fn setObjectiveName(self: *Problem, name: []const u8) !void {
        // Convert to C string and call glp_set_obj_name
    }
    
    /// Set the constant term in the objective function
    pub fn setObjectiveConstant(self: *Problem, value: f64) void {
        glpk.c.glp_set_obj_coef(self.ptr, 0, value);
    }
    
    /// Enable/disable terminal output
    pub fn setTerminalOutput(self: *Problem, enabled: bool) void {
        const level = if (enabled) glpk.c.GLP_MSG_ALL else glpk.c.GLP_MSG_OFF;
        glpk.c.glp_term_out(level);
    }
};
```

### Memory Management
- Properly handle allocation and deallocation
- Store allocator for dynamic allocations
- Ensure GLPK problem is always freed in deinit
- Handle string duplication for names

### Error Handling
- Check for null returns from GLPK functions
- Convert GLPK errors to Zig errors
- Validate inputs where appropriate

### Utility Methods
```zig
/// Create a copy of the problem
pub fn clone(self: *const Problem, allocator: std.mem.Allocator) !Problem {
    // Use glp_copy_prob
}

/// Write problem to file in various formats
pub fn writeToFile(self: *const Problem, path: []const u8, format: FileFormat) !void {
    // Support MPS, CPLEX LP, GLPK formats
}

/// Get problem statistics
pub fn getStats(self: *const Problem) ProblemStats {
    return .{
        .rows = self.getRowCount(),
        .columns = self.getColumnCount(),
        .non_zeros = self.getNonZeroCount(),
        // ... other statistics
    };
}
```

## Implementation Notes
- The Problem struct owns the GLPK problem pointer
- Use RAII pattern - init/deinit for resource management
- Keep the initial implementation simple
- Add more methods in subsequent issues
- Consider thread safety implications
- Document GLPK function mappings

## Testing Requirements
- Create `lib/core/utils/problem/problem.test.zig`
- Test problem creation and destruction
- Test name setting and retrieval
- Test objective direction setting
- Test row/column count methods
- Test memory management (no leaks)
- Test error conditions
- Test clearing problems

## Dependencies
- [#004](004_issue.md) - Need GLPK C bindings
- [#005](005_issue.md) - Need type definitions

## Acceptance Criteria
- [x] Problem struct defined with core fields
- [x] init() creates GLPK problem successfully
- [x] deinit() properly frees resources
- [x] Basic configuration methods work
- [x] Count methods return correct values
- [x] Terminal output control works
- [x] Tests cover all basic functionality
- [x] No memory leaks in tests
- [x] Documentation for all public methods
- [x] Error handling for all failure cases

## Status
✅ Completed

## Resolution Summary

Successfully implemented the Problem struct with comprehensive functionality and testing.

### Implementation Details

**Main Implementation:** `lib/core/utils/problem/problem.zig`
- Full RAII pattern with init/deinit
- Name management with string duplication
- Objective direction control (minimize/maximize)
- Row/column/non-zero counting methods
- Problem clearing functionality
- Objective function configuration
- Terminal output control
- Clone functionality for copying problems
- File export (CPLEX LP, MPS, GLPK formats)
- Comprehensive statistics retrieval

**Test Coverage:** `lib/core/utils/problem/problem.test.zig`
- 44 comprehensive tests covering all functionality
- Categories: unit, integration, stress, performance
- Memory leak testing
- Edge case handling
- Stress testing with 1000x1000 problems
- File I/O verification

### Key Features Delivered
✅ Problem struct with GLPK pointer and allocator
✅ init() creates GLPK problem successfully
✅ deinit() properly frees all resources
✅ Basic configuration methods work
✅ Count methods return correct values
✅ Terminal output control works
✅ Comprehensive test coverage
✅ No memory leaks in tests
✅ Documentation for all public methods
✅ Error handling for all failure cases

### MCS Compliance
- Follows all MCS formatting rules
- Proper section headers and indentation
- Test naming convention strictly followed
- Code organization matches existing project structure

### Additional Enhancements
Beyond the basic requirements, the implementation includes:
- `ProblemStats` struct for comprehensive statistics
- `ExportFormat` enum for file export options
- Clone functionality for problem duplication
- Multiple file format export support
- Unicode name support
- Stress and performance testing