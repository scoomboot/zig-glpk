# Issue #021: Create integration test for MIP problem

## Priority
🟡 Medium

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#52-integration-tests)
- [Issue #016](016_issue.md) - MIPSolver
- [Issue #017](017_issue.md) - MIP solution retrieval

## Description
Create comprehensive integration tests for Mixed Integer Programming problems including binary knapsack, integer programming, and mixed problems. These tests validate that MIP-specific functionality works correctly.

## Requirements

### Test File
- Create `test/integration/mip_test.zig`

### Binary Knapsack Problem Test
```zig
const std = @import("std");
const testing = std.testing;
const glpk = @import("zig-glpk");

test "0-1 Knapsack problem" {
    // Classic binary knapsack:
    // Items with weights and values
    // Maximize value subject to weight limit
    //
    // Items:   1    2    3    4    5
    // Weight:  12   7    11   8    9
    // Value:   24   13   23   15   16
    // Capacity: 26
    //
    // Optimal: Items 1, 2, 4 with value = 52
    
    const allocator = testing.allocator;
    
    var problem = try glpk.Problem.init(allocator);
    defer problem.deinit();
    
    try problem.setName("Knapsack");
    problem.setObjectiveDirection(.maximize);
    
    // Binary variables for each item
    try problem.addColumns(5);
    for (1..6) |i| {
        const name = try std.fmt.allocPrint(allocator, "item{}", .{i});
        defer allocator.free(name);
        try problem.setColumnName(i, name);
        try problem.setColumnBinary(i);
    }
    
    // Objective: maximize value
    const values = [_]f64{ 24, 13, 23, 15, 16 };
    for (values, 1..) |value, i| {
        problem.setObjectiveCoefficient(i, value);
    }
    
    // Weight constraint
    try problem.addRows(1);
    try problem.setRowName(1, "Weight");
    try problem.setRowUpperBound(1, 26);
    
    const weights = [_]f64{ 12, 7, 11, 8, 9 };
    const cols = [_]usize{ 1, 2, 3, 4, 5 };
    try problem.setRowCoefficients(1, &cols, &weights);
    
    // Solve with MIP solver
    var solver = glpk.MIPSolver.init(.{
        .mip_gap = 0.0, // Require optimal solution
    });
    const status = try solver.solve(&problem);
    
    try testing.expectEqual(glpk.SolutionStatus.optimal, status);
    
    // Check objective value
    const total_value = problem.getMIPObjectiveValue();
    try testing.expectApproxEqAbs(@as(f64, 52.0), total_value, 1e-6);
    
    // Check which items are selected
    const item1 = problem.getMIPColumnValue(1);
    const item2 = problem.getMIPColumnValue(2);
    const item3 = problem.getMIPColumnValue(3);
    const item4 = problem.getMIPColumnValue(4);
    const item5 = problem.getMIPColumnValue(5);
    
    try testing.expectApproxEqAbs(@as(f64, 1.0), item1, 1e-6);
    try testing.expectApproxEqAbs(@as(f64, 1.0), item2, 1e-6);
    try testing.expectApproxEqAbs(@as(f64, 0.0), item3, 1e-6);
    try testing.expectApproxEqAbs(@as(f64, 1.0), item4, 1e-6);
    try testing.expectApproxEqAbs(@as(f64, 0.0), item5, 1e-6);
    
    // Verify weight constraint
    const total_weight = problem.getMIPRowValue(1);
    try testing.expect(total_weight <= 26.0 + 1e-6);
    try testing.expectApproxEqAbs(@as(f64, 27.0), total_weight, 1e-6);
    
    // Verify solution is integer
    try testing.expect(problem.isMIPSolutionInteger());
}
```

### Facility Location Problem Test
```zig
test "Facility location problem" {
    // Decide which facilities to open and which customers to serve from each
    // 3 potential facilities, 4 customers
    // 
    // Fixed costs to open: F1=1000, F2=1200, F3=900
    // Service costs:
    //        C1   C2   C3   C4
    //   F1   10   20   30   40
    //   F2   20   10   25   35
    //   F3   30   25   10   20
    // Demand: 100  80  120   90
    // Capacity: 200 each facility
    
    const allocator = testing.allocator;
    
    var problem = try glpk.Problem.init(allocator);
    defer problem.deinit();
    
    try problem.setName("FacilityLocation");
    problem.setObjectiveDirection(.minimize);
    
    // Variables: y[i] = 1 if facility i is open (binary)
    //           x[i][j] = amount shipped from facility i to customer j (continuous)
    try problem.addColumns(3 + 12); // 3 facilities + 3*4 shipments
    
    // Facility open/close variables (binary)
    for (1..4) |i| {
        const name = try std.fmt.allocPrint(allocator, "open_f{}", .{i});
        defer allocator.free(name);
        try problem.setColumnName(i, name);
        try problem.setColumnBinary(i);
    }
    
    // Fixed costs
    const fixed_costs = [_]f64{ 1000, 1200, 900 };
    for (fixed_costs, 1..) |cost, i| {
        problem.setObjectiveCoefficient(i, cost);
    }
    
    // Shipment variables (continuous)
    var col: usize = 4;
    const service_costs = [_]f64{
        10, 20, 30, 40,  // F1 to customers
        20, 10, 25, 35,  // F2 to customers
        30, 25, 10, 20,  // F3 to customers
    };
    
    for (service_costs) |cost| {
        try problem.setColumnLowerBound(col, 0);
        problem.setObjectiveCoefficient(col, cost);
        col += 1;
    }
    
    // Demand constraints (each customer must be served)
    try problem.addRows(4);
    const demands = [_]f64{ 100, 80, 120, 90 };
    for (demands, 1..) |demand, c| {
        try problem.setRowFixed(@intCast(c), demand);
        // Sum of shipments from all facilities to customer c
        const facilities = [_]usize{ 
            3 + (c),      // F1 to customer c
            3 + 4 + (c),  // F2 to customer c  
            3 + 8 + (c),  // F3 to customer c
        };
        try problem.setRowCoefficients(@intCast(c), &facilities, &[_]f64{ 1, 1, 1 });
    }
    
    // Capacity constraints (can only ship if facility is open)
    try problem.addRows(3);
    for (0..3) |f| {
        const row = 5 + f;
        try problem.setRowUpperBound(row, 0);
        
        // -200*y[f] + sum of shipments from f <= 0
        var coeffs = [_]f64{0} ** 5;
        coeffs[0] = -200; // Capacity * y[f]
        for (1..5) |i| {
            coeffs[i] = 1; // Shipments
        }
        
        var cols_array = [_]usize{0} ** 5;
        cols_array[0] = f + 1; // Facility variable
        for (1..5) |i| {
            cols_array[i] = 4 + f * 4 + i - 1; // Shipment variables
        }
        
        try problem.setRowCoefficients(row, &cols_array, &coeffs);
    }
    
    // Solve
    var solver = glpk.MIPSolver.init(.{
        .presolve = true,
        .cuts = glpk.CutOptions.aggressive(),
    });
    const status = try solver.solve(&problem);
    
    try testing.expectEqual(glpk.SolutionStatus.optimal, status);
    
    // Verify solution makes sense
    const total_cost = problem.getMIPObjectiveValue();
    try testing.expect(total_cost > 0);
    
    // Check that some facilities are open
    var facilities_open: usize = 0;
    for (1..4) |i| {
        if (problem.getMIPColumnValue(i) > 0.5) {
            facilities_open += 1;
        }
    }
    try testing.expect(facilities_open > 0);
    try testing.expect(facilities_open <= 3);
}
```

### Integer Programming Test
```zig
test "Pure integer programming problem" {
    // Production planning with integer quantities
    // Minimize: 5*x + 7*y
    // Subject to:
    //   2*x + 3*y >= 12
    //   3*x + 2*y >= 13
    //   x, y >= 0, integer
    //
    // Optimal: x = 2, y = 3, cost = 31
    
    const allocator = testing.allocator;
    
    var problem = try glpk.Problem.init(allocator);
    defer problem.deinit();
    
    try problem.setName("IntegerProgramming");
    problem.setObjectiveDirection(.minimize);
    
    // Integer variables
    try problem.addColumns(2);
    try problem.setColumnName(1, "x");
    try problem.setColumnName(2, "y");
    try problem.setColumnInteger(1);
    try problem.setColumnInteger(2);
    try problem.setColumnLowerBound(1, 0);
    try problem.setColumnLowerBound(2, 0);
    
    // Objective
    problem.setObjectiveCoefficient(1, 5);
    problem.setObjectiveCoefficient(2, 7);
    
    // Constraints
    try problem.addRows(2);
    try problem.setRowLowerBound(1, 12);
    try problem.setRowCoefficients(1, &[_]usize{ 1, 2 }, &[_]f64{ 2, 3 });
    
    try problem.setRowLowerBound(2, 13);
    try problem.setRowCoefficients(2, &[_]usize{ 1, 2 }, &[_]f64{ 3, 2 });
    
    // Solve
    var solver = glpk.MIPSolver.initDefault();
    const status = try solver.solve(&problem);
    
    try testing.expectEqual(glpk.SolutionStatus.optimal, status);
    
    // Check solution
    const x = problem.getMIPColumnValue(1);
    const y = problem.getMIPColumnValue(2);
    const cost = problem.getMIPObjectiveValue();
    
    try testing.expectApproxEqAbs(@as(f64, 2.0), x, 1e-6);
    try testing.expectApproxEqAbs(@as(f64, 3.0), y, 1e-6);
    try testing.expectApproxEqAbs(@as(f64, 31.0), cost, 1e-6);
    
    // Verify integrality
    try testing.expect(problem.isMIPSolutionInteger());
}
```

### Mixed Integer Test
```zig
test "Mixed integer-continuous problem" {
    // Production with setup costs
    // Binary: y = 1 if production line is used
    // Continuous: x = production amount
    // Integer: n = number of batches
    //
    // Minimize: 100*y + 5*x + 10*n
    // Subject to:
    //   x >= 50            (minimum demand)
    //   x <= 200*y         (can only produce if line is open)
    //   x <= 30*n          (batch size limit)
    //   x >= 0, y binary, n integer
    
    const allocator = testing.allocator;
    
    var problem = try glpk.Problem.init(allocator);
    defer problem.deinit();
    
    try problem.setName("MixedInteger");
    problem.setObjectiveDirection(.minimize);
    
    // Variables
    try problem.addColumns(3);
    try problem.setColumnName(1, "setup");
    try problem.setColumnName(2, "production");
    try problem.setColumnName(3, "batches");
    
    try problem.setColumnBinary(1);        // y is binary
    try problem.setColumnLowerBound(2, 0); // x is continuous
    try problem.setColumnInteger(3);       // n is integer
    try problem.setColumnLowerBound(3, 0);
    
    // Objective
    problem.setObjectiveCoefficient(1, 100);
    problem.setObjectiveCoefficient(2, 5);
    problem.setObjectiveCoefficient(3, 10);
    
    // Constraints
    try problem.addRows(3);
    
    // Minimum demand: x >= 50
    try problem.setRowLowerBound(1, 50);
    try problem.setRowCoefficients(1, &[_]usize{2}, &[_]f64{1});
    
    // Setup constraint: x - 200*y <= 0
    try problem.setRowUpperBound(2, 0);
    try problem.setRowCoefficients(2, &[_]usize{ 1, 2 }, &[_]f64{ -200, 1 });
    
    // Batch size: x - 30*n <= 0
    try problem.setRowUpperBound(3, 0);
    try problem.setRowCoefficients(3, &[_]usize{ 2, 3 }, &[_]f64{ 1, -30 });
    
    // Solve
    var solver = glpk.MIPSolver.initDefault();
    const status = try solver.solve(&problem);
    
    try testing.expectEqual(glpk.SolutionStatus.optimal, status);
    
    // Verify solution
    const setup = problem.getMIPColumnValue(1);
    const production = problem.getMIPColumnValue(2);
    const batches = problem.getMIPColumnValue(3);
    
    // Setup should be 1 (line is open)
    try testing.expectApproxEqAbs(@as(f64, 1.0), setup, 1e-6);
    
    // Production should be at least 50
    try testing.expect(production >= 50.0 - 1e-6);
    
    // Batches should be integer
    const rounded_batches = @round(batches);
    try testing.expectApproxEqAbs(rounded_batches, batches, 1e-6);
    
    // Production should fit in batches
    try testing.expect(production <= 30.0 * batches + 1e-6);
}
```

### MIP with Gap Tolerance Test
```zig
test "MIP with gap tolerance" {
    const allocator = testing.allocator;
    
    // Create a larger problem where we accept near-optimal solutions
    var problem = try glpk.Problem.init(allocator);
    defer problem.deinit();
    
    // ... (create a complex MIP problem)
    
    // Solve with gap tolerance
    var solver = glpk.MIPSolver.init(.{
        .mip_gap = 0.05, // Accept solution within 5% of optimal
        .time_limit = 10.0, // 10 second limit
    });
    
    const status = try solver.solve(&problem);
    
    // Should find a good solution
    try testing.expect(status == .optimal or status == .feasible);
    
    if (solver.getStats()) |stats| {
        // Check that gap is within tolerance
        if (status == .feasible) {
            try testing.expect(stats.gap <= 0.05);
        }
    }
}
```

### MIP Solution Validation Test
```zig
test "MIP solution validation" {
    const allocator = testing.allocator;
    
    var problem = try glpk.Problem.init(allocator);
    defer problem.deinit();
    
    // Create a simple MIP problem
    try problem.addColumns(2);
    try problem.setColumnBinary(1);
    try problem.setColumnInteger(2);
    try problem.setColumnLowerBound(2, 0);
    try problem.setColumnUpperBound(2, 10);
    
    // ... (set up constraints and objective)
    
    var solver = glpk.MIPSolver.initDefault();
    _ = try solver.solve(&problem);
    
    // Validate the solution
    const validation = try problem.validateMIPSolution();
    defer validation.deinit();
    
    try testing.expect(validation.is_valid);
    try testing.expectEqual(@as(usize, 0), validation.violations.len);
    
    // Get integer values only
    const int_values = try problem.getMIPIntegerValues(allocator);
    defer int_values.deinit();
    
    for (int_values.values) |val| {
        const rounded = @round(val);
        try testing.expectApproxEqAbs(rounded, val, 1e-9);
    }
    
    // Get binary values
    const bin_values = try problem.getMIPBinaryValues(allocator);
    defer bin_values.deinit();
    
    for (bin_values.values) |val| {
        try testing.expect(val == true or val == false);
    }
}
```

## Implementation Notes
- Test pure binary, pure integer, and mixed problems
- Verify integer constraints are satisfied
- Test MIP-specific features (gap tolerance, preprocessing)
- Include realistic problem sizes
- Test solution validation methods

## Testing Requirements
- Binary knapsack problem solved correctly
- Facility location problem works
- Pure integer programming tested
- Mixed integer-continuous tested
- Gap tolerance works
- Solution validation tested
- Integer values verified

## Dependencies
- [#016](016_issue.md) - MIPSolver
- [#017](017_issue.md) - MIP solution retrieval

## Acceptance Criteria
- [ ] Knapsack problem solves optimally
- [ ] Facility location works correctly
- [ ] Integer programming tested
- [ ] Mixed problems supported
- [ ] Gap tolerance tested
- [ ] Solutions are integer feasible
- [ ] Validation methods work
- [ ] MIP statistics collected
- [ ] Tests complete in reasonable time
- [ ] No memory leaks

## Status
🟡 Not Started