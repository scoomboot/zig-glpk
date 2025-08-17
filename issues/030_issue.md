# Issue #030: Fix GLPK Array Pointer Handling in setMatrixRow

## Priority
🟡 Medium

## References
- [Issue Index](000_index.md)
- [Session Review #004](SESSION_REVIEW_004.md)
- [Issue #006](006_issue.md) - Problem struct implementation
- [Issue #004](004_issue.md) - C bindings layer

## Description
The GLPK C binding function `setMatrixRow()` causes segmentation faults when used with array pointers, preventing proper matrix manipulation functionality. This issue was discovered during implementation of Issue #006 when three tests had to be disabled.

## Problem Details

### Affected Function
```zig
// In lib/c/utils/glpk/glpk.zig
pub fn setMatrixRow(prob: ?*c.glp_prob, i: c_int, len: c_int, ind: [*c]const c_int, val: [*c]const f64) void {
    c.glp_set_mat_row(prob, i, len, ind, val);
}
```

### Symptom
Segmentation fault occurs when calling this function with valid array pointers.

### Affected Tests (Currently Disabled)
From `lib/core/utils/problem/problem.test.zig`:

1. **Line 379**: `"unit: Problem: getNonZeroCount with constraint matrix"`
   - Tests non-zero counting after adding matrix elements

2. **Line 620**: `"unit: Problem: clone preserves constraint matrix"`
   - Verifies constraint matrix is properly copied during clone

3. **Line 728**: `"unit: Problem: getStats counts non-zeros correctly"`
   - Validates statistics reporting for sparse matrices

All three tests are commented with:
```zig
// TODO: These tests cause segmentation faults - likely issue with GLPK array pointer handling
```

## Investigation Required

### 1. Array Indexing Issue
GLPK uses 1-based indexing for arrays. Verify:
- [ ] Are we correctly using 1-based indices?
- [ ] Is the 0th element properly ignored/set?

### 2. Memory Alignment
- [ ] Check if arrays need specific alignment for GLPK
- [ ] Verify pointer casting is correct

### 3. Array Format
Example of failing code:
```zig
var indices = [_]c_int{ 0, 1, 2, 3 };  // 1-based indexing
var values = [_]f64{ 0, 2.5, 3.0, 1.5 };
problem.setMatrixRow(1, 3, &indices, &values);
```

### 4. Alternative Approaches
- [ ] Try using `glp_load_matrix` instead
- [ ] Test with heap-allocated arrays vs stack arrays
- [ ] Consider using std.ArrayList for dynamic allocation

## Reproduction Steps
1. Uncomment any of the three disabled tests in problem.test.zig
2. Run `zig build test`
3. Observe segmentation fault

## Expected Behavior
The `setMatrixRow` function should:
- Accept array pointers without crashing
- Properly set constraint matrix coefficients
- Allow retrieval of non-zero count
- Work with clone operations

## Potential Solutions

### Option 1: Fix Array Handling
Investigate and fix the root cause of pointer handling issues.

### Option 2: Wrapper Function
Create a safe wrapper that handles array conversion:
```zig
pub fn safeSetMatrixRow(prob: *Problem, row: usize, indices: []const i32, values: []const f64) !void {
    // Ensure 1-based indexing
    // Handle memory safely
    // Call GLPK function
}
```

### Option 3: Use Alternative API
Replace with `glp_load_matrix` for batch operations.

## Testing Requirements
- [ ] Re-enable all three disabled tests
- [ ] Add additional matrix manipulation tests
- [ ] Test with various array sizes
- [ ] Verify memory safety with valgrind or similar
- [ ] Test both stack and heap allocated arrays

## Dependencies
- [#004](004_issue.md) - C bindings layer (may need updates)

## Acceptance Criteria
- [ ] setMatrixRow works without segmentation faults
- [ ] All three disabled tests pass
- [ ] No memory leaks or corruption
- [ ] Clear documentation on proper usage
- [ ] Safe wrapper if direct fix not possible

## Status
🔴 Not Started

## Notes
This issue affects core matrix manipulation functionality but has workarounds (using other matrix loading methods). Priority is medium because basic problem solving can proceed without it, but it should be fixed for full API compatibility.