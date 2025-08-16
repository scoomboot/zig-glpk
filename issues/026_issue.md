# Issue #026: Write comprehensive documentation

## Priority
🟢 Low

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#64-documentation)
- [Issue #022](022_issue.md) - Example programs

## Description
Create comprehensive documentation including API reference, user guide, tutorials, and migration guide from C API. Documentation should be clear, complete, and include practical examples.

## Requirements

### Main README
Create/update `README.md`:
```markdown
# GLPK Zig Wrapper

A safe, idiomatic Zig wrapper for the GNU Linear Programming Kit (GLPK), providing easy-to-use interfaces for solving linear programming (LP) and mixed integer programming (MIP) problems.

## Features

- 🔧 **Safe API**: Memory-safe wrapper with proper error handling
- 🚀 **High Performance**: Minimal overhead compared to C API
- 📚 **Well Documented**: Comprehensive docs and examples
- 🧪 **Thoroughly Tested**: Extensive test coverage
- 🎯 **Type Safe**: Leverage Zig's type system for correctness
- 💡 **Intuitive**: Clean, idiomatic Zig interface

## Quick Start

```zig
const std = @import("std");
const glpk = @import("zig-glpk");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Create a problem
    var problem = try glpk.Problem.init(allocator);
    defer problem.deinit();
    
    // Maximize: 3x + 2y
    problem.setObjectiveDirection(.maximize);
    try problem.addColumns(2);
    problem.setObjectiveCoefficient(1, 3);
    problem.setObjectiveCoefficient(2, 2);
    
    // Subject to: x + y <= 10
    try problem.addRows(1);
    try problem.setRowUpperBound(1, 10);
    try problem.setRowCoefficients(1, &[_]usize{1, 2}, &[_]f64{1, 1});
    
    // Solve
    var solver = glpk.SimplexSolver.initDefault();
    const status = try solver.solve(&problem);
    
    if (status == .optimal) {
        std.debug.print("Optimal value: {}\n", .{problem.getObjectiveValue()});
    }
}
```

## Installation

### Prerequisites

1. Install GLPK:
   - Ubuntu/Debian: `apt-get install libglpk-dev`
   - macOS: `brew install glpk`
   - Windows: Download from [GLPK website](https://www.gnu.org/software/glpk/)

2. Zig 0.11.0 or later

### Adding to Your Project

Add to your `build.zig.zon`:
```zig
.dependencies = .{
    .@"zig-glpk" = .{
        .url = "https://github.com/yourusername/zig-glpk/archive/v0.1.0.tar.gz",
        .hash = "...",
    },
},
```

In your `build.zig`:
```zig
const glpk = b.dependency("zig-glpk", .{});
exe.root_module.addImport("zig-glpk", glpk.module("zig-glpk"));
exe.linkSystemLibrary("glpk");
```

## Documentation

- [API Reference](docs/API.md)
- [User Guide](docs/GUIDE.md)
- [Examples](examples/)
- [Migration from C](docs/MIGRATION.md)

## License

MIT License - See [LICENSE](LICENSE) for details.
```

### API Reference
Create `docs/API.md`:
```markdown
# API Reference

## Core Types

### Problem

The main problem structure representing an optimization problem.

#### Creation and Destruction

```zig
pub fn init(allocator: std.mem.Allocator) !Problem
```
Creates a new optimization problem.

**Parameters:**
- `allocator`: Memory allocator to use

**Returns:** New Problem instance

**Errors:**
- `OutOfMemory`: Failed to allocate problem

---

```zig
pub fn deinit(self: *Problem) void
```
Frees all resources associated with the problem.

#### Problem Configuration

```zig
pub fn setName(self: *Problem, name: []const u8) !void
```
Sets the problem name.

```zig
pub fn setObjectiveDirection(self: *Problem, dir: OptimizationDirection) void
```
Sets whether to minimize or maximize the objective.

**Parameters:**
- `dir`: `.minimize` or `.maximize`

#### Variables (Columns)

```zig
pub fn addColumns(self: *Problem, count: usize) !void
```
Adds decision variables to the problem.

```zig
pub fn setColumnBounds(self: *Problem, col: usize, bound_type: BoundType, lb: f64, ub: f64) !void
```
Sets bounds for a variable.

**Parameters:**
- `col`: Column index (1-based)
- `bound_type`: Type of bounds (`.free`, `.lower`, `.upper`, `.double`, `.fixed`)
- `lb`: Lower bound
- `ub`: Upper bound

```zig
pub fn setObjectiveCoefficient(self: *Problem, col: usize, coef: f64) void
```
Sets the objective function coefficient for a variable.

#### Constraints (Rows)

```zig
pub fn addRows(self: *Problem, count: usize) !void
```
Adds constraints to the problem.

```zig
pub fn setRowBounds(self: *Problem, row: usize, bound_type: BoundType, lb: f64, ub: f64) !void
```
Sets bounds for a constraint.

```zig
pub fn setRowCoefficients(self: *Problem, row: usize, cols: []const usize, values: []const f64) !void
```
Sets the coefficients for a constraint (sparse format).

### SimplexSolver

Solver for linear programming problems using the simplex method.

```zig
pub fn init(options: SimplexOptions) SimplexSolver
```
Creates a solver with specified options.

```zig
pub fn solve(self: *SimplexSolver, problem: *Problem) !SolutionStatus
```
Solves the LP problem.

**Returns:** Solution status (`.optimal`, `.feasible`, `.infeasible`, `.unbounded`, etc.)

### MIPSolver

Solver for mixed integer programming problems.

```zig
pub fn init(options: MIPOptions) MIPSolver
```
Creates a MIP solver with specified options.

```zig
pub fn solve(self: *MIPSolver, problem: *Problem) !SolutionStatus
```
Solves the MIP problem.

## Enumerations

### OptimizationDirection
```zig
pub const OptimizationDirection = enum {
    minimize,
    maximize,
};
```

### BoundType
```zig
pub const BoundType = enum {
    free,    // -∞ < x < +∞
    lower,   // lb ≤ x < +∞
    upper,   // -∞ < x ≤ ub
    double,  // lb ≤ x ≤ ub
    fixed,   // x = lb = ub
};
```

### VariableKind
```zig
pub const VariableKind = enum {
    continuous,
    integer,
    binary,
};
```

### SolutionStatus
```zig
pub const SolutionStatus = enum {
    optimal,
    feasible,
    infeasible,
    no_feasible,
    unbounded,
    undefined,
};
```

## Options Structures

### SimplexOptions
```zig
pub const SimplexOptions = struct {
    presolve: bool = true,
    method: SimplexMethod = .dual_primal,
    pricing: PricingRule = .steepest_edge,
    time_limit: ?f64 = null,
    // ... more options
};
```

### MIPOptions
```zig
pub const MIPOptions = struct {
    presolve: bool = true,
    branching: BranchingTechnique = .driebeek_tomlin,
    mip_gap: f64 = 0.0,
    time_limit: ?f64 = null,
    // ... more options
};
```

## Solution Retrieval

```zig
// Get objective value
pub fn getObjectiveValue(self: *const Problem) f64

// Get variable values
pub fn getColumnPrimal(self: *const Problem, col: usize) f64

// Get constraint values
pub fn getRowPrimal(self: *const Problem, row: usize) f64

// Get shadow prices (dual values)
pub fn getRowDual(self: *const Problem, row: usize) f64

// Get reduced costs
pub fn getColumnDual(self: *const Problem, col: usize) f64
```

## Error Handling

All errors are defined in the `GLPKError` error set:

```zig
pub const GLPKError = error{
    OutOfMemory,
    InvalidRowIndex,
    InvalidColumnIndex,
    InvalidBounds,
    Infeasible,
    Unbounded,
    TimeLimit,
    // ... more errors
};
```
```

### User Guide
Create `docs/GUIDE.md`:
```markdown
# User Guide

## Table of Contents
1. [Introduction](#introduction)
2. [Problem Formulation](#problem-formulation)
3. [Linear Programming](#linear-programming)
4. [Mixed Integer Programming](#mixed-integer-programming)
5. [Advanced Topics](#advanced-topics)
6. [Best Practices](#best-practices)

## Introduction

This guide walks you through using the GLPK Zig wrapper to solve optimization problems.

## Problem Formulation

### Understanding Optimization Problems

An optimization problem consists of:
- **Objective Function**: What to minimize or maximize
- **Decision Variables**: Values to determine
- **Constraints**: Restrictions on variables

### Example: Production Planning

A factory produces products A and B:
- Product A yields $3 profit per unit
- Product B yields $5 profit per unit
- Constraint: Total production ≤ 100 units
- Constraint: Product A requires 2 hours, B requires 3 hours, total ≤ 240 hours

Mathematical formulation:
```
Maximize: 3*A + 5*B
Subject to:
  A + B ≤ 100
  2*A + 3*B ≤ 240
  A, B ≥ 0
```

### Implementing in Zig

```zig
var problem = try glpk.Problem.init(allocator);
defer problem.deinit();

// Variables
try problem.addColumns(2);
try problem.setColumnName(1, "A");
try problem.setColumnName(2, "B");
try problem.setColumnLowerBound(1, 0);
try problem.setColumnLowerBound(2, 0);

// Objective
problem.setObjectiveDirection(.maximize);
problem.setObjectiveCoefficient(1, 3);
problem.setObjectiveCoefficient(2, 5);

// Constraints
try problem.addRows(2);

// Total production constraint
try problem.setRowName(1, "TotalProduction");
try problem.setRowUpperBound(1, 100);
try problem.setRowCoefficients(1, &[_]usize{1, 2}, &[_]f64{1, 1});

// Time constraint
try problem.setRowName(2, "TimeLimit");
try problem.setRowUpperBound(2, 240);
try problem.setRowCoefficients(2, &[_]usize{1, 2}, &[_]f64{2, 3});
```

## Linear Programming

### Solving LP Problems

```zig
var solver = glpk.SimplexSolver.initDefault();
const status = try solver.solve(&problem);

if (status == .optimal) {
    const profit = problem.getObjectiveValue();
    const units_a = problem.getColumnPrimal(1);
    const units_b = problem.getColumnPrimal(2);
    
    std.debug.print("Optimal profit: ${}\n", .{profit});
    std.debug.print("Produce {} units of A\n", .{units_a});
    std.debug.print("Produce {} units of B\n", .{units_b});
}
```

### Understanding Shadow Prices

Shadow prices indicate the value of relaxing constraints:

```zig
const time_shadow = problem.getRowDual(2);
std.debug.print("Value of one additional hour: ${}\n", .{time_shadow});
```

## Mixed Integer Programming

### Setting Variable Types

```zig
// Binary variable (0 or 1)
try problem.setColumnBinary(1);

// Integer variable
try problem.setColumnInteger(2);
```

### Solving MIP Problems

```zig
var solver = glpk.MIPSolver.init(.{
    .mip_gap = 0.01, // Accept 1% gap from optimal
});

const status = try solver.solve(&problem);
```

## Advanced Topics

### Warm Starting

```zig
// Solve initial problem
var solver = glpk.SimplexSolver.initDefault();
_ = try solver.solve(&problem);

// Modify problem slightly
problem.setObjectiveCoefficient(1, 3.5);

// Solve again (uses previous basis)
_ = try solver.solveWarmStart(&problem);
```

### Large-Scale Problems

For problems with thousands of variables:

```zig
// Use sparse matrix format
var builder = glpk.MatrixBuilder.initCapacity(allocator, estimated_nonzeros);
defer builder.deinit();

// Add only non-zero entries
try builder.addEntry(row, col, value);

const matrix = builder.build();
try problem.loadMatrix(matrix);
```

### Performance Tuning

```zig
var solver = glpk.SimplexSolver.init(.{
    .presolve = true,        // Enable presolve
    .method = .dual,         // Use dual simplex
    .pricing = .steepest_edge, // Steepest edge pricing
});
```

## Best Practices

### Memory Management

Always use defer for cleanup:
```zig
var problem = try glpk.Problem.init(allocator);
defer problem.deinit();
```

### Error Handling

Check solution status:
```zig
const status = try solver.solve(&problem);
switch (status) {
    .optimal => // Handle optimal solution
    .infeasible => // Handle infeasibility
    .unbounded => // Handle unbounded problem
    else => // Handle other cases
}
```

### Numerical Stability

- Scale your problem if coefficients vary widely
- Use appropriate tolerances
- Check for near-singular matrices

### Debugging

Enable verbose output:
```zig
var solver = glpk.SimplexSolver.init(.{
    .message_level = .all,
});
```
```

### Migration Guide
Create `docs/MIGRATION.md`:
```markdown
# Migration Guide: C to Zig

This guide helps C GLPK users migrate to the Zig wrapper.

## Basic Concepts

### Memory Management

**C:**
```c
glp_prob *prob = glp_create_prob();
// ... use problem
glp_delete_prob(prob);
```

**Zig:**
```zig
var problem = try glpk.Problem.init(allocator);
defer problem.deinit();
```

### Error Handling

**C:**
```c
int ret = glp_simplex(prob, &parm);
if (ret != 0) {
    // Handle error
}
```

**Zig:**
```zig
const status = try solver.solve(&problem);
// Errors are handled via Zig's error system
```

## API Mapping

### Problem Creation

| C API | Zig API |
|-------|---------|
| `glp_create_prob()` | `Problem.init(allocator)` |
| `glp_delete_prob(prob)` | `problem.deinit()` |
| `glp_set_prob_name(prob, name)` | `problem.setName(name)` |
| `glp_set_obj_dir(prob, GLP_MAX)` | `problem.setObjectiveDirection(.maximize)` |

### Variables and Constraints

| C API | Zig API |
|-------|---------|
| `glp_add_rows(prob, n)` | `problem.addRows(n)` |
| `glp_add_cols(prob, n)` | `problem.addColumns(n)` |
| `glp_set_row_bnds(prob, i, type, lb, ub)` | `problem.setRowBounds(i, type, lb, ub)` |
| `glp_set_col_bnds(prob, j, type, lb, ub)` | `problem.setColumnBounds(j, type, lb, ub)` |
| `glp_set_obj_coef(prob, j, coef)` | `problem.setObjectiveCoefficient(j, coef)` |

### Matrix Loading

**C:**
```c
int ia[1+1000], ja[1+1000];
double ar[1+1000];
// Fill arrays...
glp_load_matrix(prob, ne, ia, ja, ar);
```

**Zig:**
```zig
const matrix = glpk.SparseMatrix{
    .rows = rows,
    .cols = cols,
    .values = values,
};
try problem.loadMatrix(matrix);
```

### Solving

**C:**
```c
glp_smcp parm;
glp_init_smcp(&parm);
int ret = glp_simplex(prob, &parm);
```

**Zig:**
```zig
var solver = glpk.SimplexSolver.initDefault();
const status = try solver.solve(&problem);
```

### Solution Retrieval

| C API | Zig API |
|-------|---------|
| `glp_get_status(prob)` | `problem.getSolutionStatus()` |
| `glp_get_obj_val(prob)` | `problem.getObjectiveValue()` |
| `glp_get_col_prim(prob, j)` | `problem.getColumnPrimal(j)` |
| `glp_get_row_prim(prob, i)` | `problem.getRowPrimal(i)` |
| `glp_get_col_dual(prob, j)` | `problem.getColumnDual(j)` |
| `glp_get_row_dual(prob, i)` | `problem.getRowDual(i)` |

## Complete Example

**C Version:**
```c
glp_prob *prob = glp_create_prob();
glp_set_obj_dir(prob, GLP_MAX);

glp_add_cols(prob, 2);
glp_set_obj_coef(prob, 1, 3.0);
glp_set_obj_coef(prob, 2, 2.0);
glp_set_col_bnds(prob, 1, GLP_LO, 0.0, 0.0);
glp_set_col_bnds(prob, 2, GLP_LO, 0.0, 0.0);

glp_add_rows(prob, 1);
glp_set_row_bnds(prob, 1, GLP_UP, 0.0, 10.0);

int ia[3] = {0, 1, 1};
int ja[3] = {0, 1, 2};
double ar[3] = {0, 1.0, 1.0};
glp_load_matrix(prob, 2, ia, ja, ar);

glp_smcp parm;
glp_init_smcp(&parm);
glp_simplex(prob, &parm);

double obj = glp_get_obj_val(prob);
glp_delete_prob(prob);
```

**Zig Version:**
```zig
var problem = try glpk.Problem.init(allocator);
defer problem.deinit();

problem.setObjectiveDirection(.maximize);

try problem.addColumns(2);
problem.setObjectiveCoefficient(1, 3.0);
problem.setObjectiveCoefficient(2, 2.0);
try problem.setColumnLowerBound(1, 0);
try problem.setColumnLowerBound(2, 0);

try problem.addRows(1);
try problem.setRowUpperBound(1, 10);
try problem.setRowCoefficients(1, &[_]usize{1, 2}, &[_]f64{1, 1});

var solver = glpk.SimplexSolver.initDefault();
_ = try solver.solve(&problem);

const obj = problem.getObjectiveValue();
```

## Key Improvements in Zig

1. **Memory Safety**: Automatic cleanup with defer
2. **Error Handling**: Explicit error propagation
3. **Type Safety**: Enums instead of integer constants
4. **Cleaner API**: Method syntax instead of function prefixes
5. **Zero-Based vs One-Based**: Note that GLPK uses 1-based indexing
```

## Implementation Notes
- Use doc comments for all public APIs
- Include examples in documentation
- Generate docs with `zig build docs`
- Keep documentation up to date
- Test all code examples

## Testing Requirements
- All examples in docs compile
- API reference is complete
- Migration guide covers common patterns
- User guide is comprehensive

## Dependencies
- [#022](022_issue.md) - Example programs provide content

## Acceptance Criteria
- [ ] README.md created with quick start
- [ ] API reference complete
- [ ] User guide written
- [ ] Migration guide from C
- [ ] All public APIs documented
- [ ] Examples in docs tested
- [ ] Installation instructions clear
- [ ] Troubleshooting section added
- [ ] Performance tips included
- [ ] Generated docs available

## Status
🟢 Not Started