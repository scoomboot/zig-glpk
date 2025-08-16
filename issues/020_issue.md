# Issue #020: Create integration test for simple LP problem

## Priority
🟡 Medium

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#52-integration-tests)
- [Issue #011](011_issue.md) - SimplexSolver
- [Issue #012](012_issue.md) - Solution retrieval

## Description
Create a comprehensive integration test that builds and solves a complete linear programming problem with known optimal solution. This validates that all components work together correctly from problem construction through solution retrieval.

## Requirements

### Test File
- Create `test/integration/simple_lp_test.zig`

### Classic LP Problem Test
```zig
const std = @import("std");
const testing = std.testing;
const glpk = @import("zig-glpk");

test "Product mix optimization problem" {
    // Classic product mix problem:
    // A factory produces two products: A and B
    // 
    // Maximize profit: 3*A + 5*B
    // Subject to:
    //   Machine time:  2*A + 4*B <= 100  (hours)
    //   Raw material:  3*A + 2*B <= 90   (units)
    //   Labor:         1*A + 1*B <= 40   (hours)
    //   A, B >= 0
    //
    // Known optimal solution:
    //   A = 20, B = 15
    //   Profit = 135
    
    const allocator = testing.allocator;
    
    // Create problem
    var problem = try glpk.Problem.init(allocator);
    defer problem.deinit();
    
    try problem.setName("Product Mix");
    problem.setObjectiveDirection(.maximize);
    
    // Add decision variables
    try problem.addColumns(2);
    try problem.setColumnName(1, "ProductA");
    try problem.setColumnName(2, "ProductB");
    try problem.setColumnLowerBound(1, 0);
    try problem.setColumnLowerBound(2, 0);
    
    // Set objective coefficients (profit)
    problem.setObjectiveCoefficient(1, 3.0);
    problem.setObjectiveCoefficient(2, 5.0);
    
    // Add constraints
    try problem.addRows(3);
    
    // Machine time constraint
    try problem.setRowName(1, "MachineTime");
    try problem.setRowUpperBound(1, 100);
    try problem.setRowCoefficients(1, &[_]usize{ 1, 2 }, &[_]f64{ 2, 4 });
    
    // Raw material constraint
    try problem.setRowName(2, "RawMaterial");
    try problem.setRowUpperBound(2, 90);
    try problem.setRowCoefficients(2, &[_]usize{ 1, 2 }, &[_]f64{ 3, 2 });
    
    // Labor constraint
    try problem.setRowName(3, "Labor");
    try problem.setRowUpperBound(3, 40);
    try problem.setRowCoefficients(3, &[_]usize{ 1, 2 }, &[_]f64{ 1, 1 });
    
    // Solve with simplex
    var solver = glpk.SimplexSolver.initDefault();
    const status = try solver.solve(&problem);
    
    // Verify solution
    try testing.expectEqual(glpk.SolutionStatus.optimal, status);
    
    // Check objective value
    const obj_value = problem.getObjectiveValue();
    try testing.expectApproxEqAbs(@as(f64, 135.0), obj_value, 1e-6);
    
    // Check variable values
    const product_a = problem.getColumnPrimal(1);
    const product_b = problem.getColumnPrimal(2);
    try testing.expectApproxEqAbs(@as(f64, 20.0), product_a, 1e-6);
    try testing.expectApproxEqAbs(@as(f64, 15.0), product_b, 1e-6);
    
    // Check shadow prices (dual values)
    const machine_shadow = problem.getRowDual(1);
    const material_shadow = problem.getRowDual(2);
    const labor_shadow = problem.getRowDual(3);
    
    // Labor should be the binding constraint with highest shadow price
    try testing.expect(labor_shadow > 0);
    
    // Verify constraint activities
    const machine_used = problem.getRowPrimal(1);
    const material_used = problem.getRowPrimal(2);
    const labor_used = problem.getRowPrimal(3);
    
    try testing.expectApproxEqAbs(@as(f64, 100.0), machine_used, 1e-6);
    try testing.expectApproxEqAbs(@as(f64, 90.0), material_used, 1e-6);
    try testing.expectApproxEqAbs(@as(f64, 35.0), labor_used, 1e-6);
}
```

### Transportation Problem Test
```zig
test "Transportation problem" {
    // Classic transportation problem:
    // Ship goods from 2 sources to 3 destinations
    // Minimize total shipping cost
    //
    // Supply: S1=30, S2=40
    // Demand: D1=20, D2=25, D3=25
    // Costs:
    //        D1  D2  D3
    //   S1   8   6   10
    //   S2   9   12  13
    
    const allocator = testing.allocator;
    
    var problem = try glpk.Problem.init(allocator);
    defer problem.deinit();
    
    try problem.setName("Transportation");
    problem.setObjectiveDirection(.minimize);
    
    // Variables: x[i][j] = amount shipped from source i to destination j
    try problem.addColumns(6); // 2 sources × 3 destinations
    
    // Set variable names and bounds
    const var_names = [_][]const u8{
        "x11", "x12", "x13",
        "x21", "x22", "x23",
    };
    for (var_names, 1..) |name, i| {
        try problem.setColumnName(i, name);
        try problem.setColumnLowerBound(i, 0);
    }
    
    // Set objective coefficients (costs)
    const costs = [_]f64{ 8, 6, 10, 9, 12, 13 };
    for (costs, 1..) |cost, i| {
        problem.setObjectiveCoefficient(i, cost);
    }
    
    // Add supply constraints (2 rows)
    try problem.addRows(2);
    try problem.setRowName(1, "Supply1");
    try problem.setRowFixed(1, 30); // Supply from source 1
    try problem.setRowCoefficients(1, &[_]usize{ 1, 2, 3 }, &[_]f64{ 1, 1, 1 });
    
    try problem.setRowName(2, "Supply2");
    try problem.setRowFixed(2, 40); // Supply from source 2
    try problem.setRowCoefficients(2, &[_]usize{ 4, 5, 6 }, &[_]f64{ 1, 1, 1 });
    
    // Add demand constraints (3 rows)
    try problem.addRows(3);
    try problem.setRowName(3, "Demand1");
    try problem.setRowFixed(3, 20); // Demand at destination 1
    try problem.setRowCoefficients(3, &[_]usize{ 1, 4 }, &[_]f64{ 1, 1 });
    
    try problem.setRowName(4, "Demand2");
    try problem.setRowFixed(4, 25); // Demand at destination 2
    try problem.setRowCoefficients(4, &[_]usize{ 2, 5 }, &[_]f64{ 1, 1 });
    
    try problem.setRowName(5, "Demand3");
    try problem.setRowFixed(5, 25); // Demand at destination 3
    try problem.setRowCoefficients(5, &[_]usize{ 3, 6 }, &[_]f64{ 1, 1 });
    
    // Solve
    var solver = glpk.SimplexSolver.init(.{
        .method = .dual, // Dual simplex often better for transportation
    });
    const status = try solver.solve(&problem);
    
    try testing.expectEqual(glpk.SolutionStatus.optimal, status);
    
    // Check optimal cost
    const total_cost = problem.getObjectiveValue();
    try testing.expectApproxEqAbs(@as(f64, 490.0), total_cost, 1e-6);
    
    // Verify solution feasibility
    const solution = try problem.getSolution(allocator);
    defer solution.deinit();
    
    // All shipments should be non-negative
    for (solution.column_primals) |shipment| {
        try testing.expect(shipment >= -1e-6);
    }
}
```

### Diet Problem Test
```zig
test "Diet problem (minimum cost)" {
    // Simplified diet problem:
    // Minimize cost while meeting nutritional requirements
    // 
    // Foods: Bread, Milk, Cheese (per unit)
    // Cost:   2.0,  3.5,   8.0
    // 
    // Nutrients required:
    //           Min  Bread  Milk  Cheese
    // Calories  2000   100   150    450
    // Protein    50     4     8     25
    // Calcium   700    15   300    400
    
    const allocator = testing.allocator;
    
    var problem = try glpk.Problem.init(allocator);
    defer problem.deinit();
    
    try problem.setName("Diet");
    problem.setObjectiveDirection(.minimize);
    
    // Food variables
    try problem.addColumns(3);
    try problem.setColumnName(1, "Bread");
    try problem.setColumnName(2, "Milk");
    try problem.setColumnName(3, "Cheese");
    
    // All foods >= 0
    for (1..4) |i| {
        try problem.setColumnLowerBound(i, 0);
    }
    
    // Cost coefficients
    problem.setObjectiveCoefficient(1, 2.0);
    problem.setObjectiveCoefficient(2, 3.5);
    problem.setObjectiveCoefficient(3, 8.0);
    
    // Nutritional constraints
    try problem.addRows(3);
    
    // Calories >= 2000
    try problem.setRowName(1, "Calories");
    try problem.setRowLowerBound(1, 2000);
    try problem.setRowCoefficients(1, &[_]usize{ 1, 2, 3 }, &[_]f64{ 100, 150, 450 });
    
    // Protein >= 50
    try problem.setRowName(2, "Protein");
    try problem.setRowLowerBound(2, 50);
    try problem.setRowCoefficients(2, &[_]usize{ 1, 2, 3 }, &[_]f64{ 4, 8, 25 });
    
    // Calcium >= 700
    try problem.setRowName(3, "Calcium");
    try problem.setRowLowerBound(3, 700);
    try problem.setRowCoefficients(3, &[_]usize{ 1, 2, 3 }, &[_]f64{ 15, 300, 400 });
    
    // Solve
    var solver = glpk.SimplexSolver.initDefault();
    const status = try solver.solve(&problem);
    
    try testing.expectEqual(glpk.SolutionStatus.optimal, status);
    
    // Check that cost is minimized
    const total_cost = problem.getObjectiveValue();
    try testing.expect(total_cost > 0);
    
    // Verify nutritional requirements are met
    for (1..4) |i| {
        const nutrient_value = problem.getRowPrimal(i);
        const bounds = try problem.getRowBounds(i);
        try testing.expect(nutrient_value >= bounds.lower - 1e-6);
    }
}
```

### Infeasible Problem Test
```zig
test "Infeasible LP problem" {
    const allocator = testing.allocator;
    
    var problem = try glpk.Problem.init(allocator);
    defer problem.deinit();
    
    // Create an infeasible problem:
    // Maximize: x + y
    // Subject to:
    //   x + y <= 1
    //   x + y >= 2  (contradicts the first constraint)
    //   x, y >= 0
    
    try problem.setName("Infeasible");
    problem.setObjectiveDirection(.maximize);
    
    try problem.addColumns(2);
    try problem.setColumnLowerBound(1, 0);
    try problem.setColumnLowerBound(2, 0);
    problem.setObjectiveCoefficient(1, 1);
    problem.setObjectiveCoefficient(2, 1);
    
    try problem.addRows(2);
    try problem.setRowUpperBound(1, 1);
    try problem.setRowCoefficients(1, &[_]usize{ 1, 2 }, &[_]f64{ 1, 1 });
    
    try problem.setRowLowerBound(2, 2);
    try problem.setRowCoefficients(2, &[_]usize{ 1, 2 }, &[_]f64{ 1, 1 });
    
    var solver = glpk.SimplexSolver.initDefault();
    const status = try solver.solve(&problem);
    
    try testing.expectEqual(glpk.SolutionStatus.infeasible, status);
}
```

### Unbounded Problem Test
```zig
test "Unbounded LP problem" {
    const allocator = testing.allocator;
    
    var problem = try glpk.Problem.init(allocator);
    defer problem.deinit();
    
    // Create an unbounded problem:
    // Maximize: x + y
    // Subject to:
    //   x - y >= 0
    //   x, y >= 0
    // (Can increase x and y indefinitely)
    
    try problem.setName("Unbounded");
    problem.setObjectiveDirection(.maximize);
    
    try problem.addColumns(2);
    try problem.setColumnLowerBound(1, 0);
    try problem.setColumnLowerBound(2, 0);
    problem.setObjectiveCoefficient(1, 1);
    problem.setObjectiveCoefficient(2, 1);
    
    try problem.addRows(1);
    try problem.setRowLowerBound(1, 0);
    try problem.setRowCoefficients(1, &[_]usize{ 1, 2 }, &[_]f64{ 1, -1 });
    
    var solver = glpk.SimplexSolver.initDefault();
    const status = try solver.solve(&problem);
    
    try testing.expectEqual(glpk.SolutionStatus.unbounded, status);
}
```

### Performance and Options Test
```zig
test "Solver options and performance" {
    const allocator = testing.allocator;
    
    var problem = try glpk.Problem.init(allocator);
    defer problem.deinit();
    
    // Build a moderate-sized problem
    try problem.addColumns(50);
    try problem.addRows(30);
    
    // ... (set up problem details)
    
    // Test different solver configurations
    const configs = [_]glpk.SimplexOptions{
        glpk.SimplexOptions.default(),
        glpk.SimplexOptions.fast(),
        glpk.SimplexOptions.exact(),
    };
    
    for (configs) |options| {
        var solver = glpk.SimplexSolver.init(options);
        const status = try solver.solve(&problem);
        
        if (solver.getStats()) |stats| {
            // Verify statistics are collected
            try testing.expect(stats.iterations > 0);
            try testing.expect(stats.solve_time >= 0);
        }
    }
}
```

## Implementation Notes
- Use problems with known optimal solutions
- Test various problem types (feasible, infeasible, unbounded)
- Verify both primal and dual solutions
- Check constraint satisfaction
- Test different solver options
- Include timing/performance checks

## Testing Requirements
- Multiple problem types tested
- Optimal solutions verified
- Infeasible problems handled
- Unbounded problems detected
- Shadow prices checked
- Solver options tested
- Performance measured

## Dependencies
- [#011](011_issue.md) - SimplexSolver
- [#012](012_issue.md) - Solution retrieval methods

## Acceptance Criteria
- [ ] Product mix problem solves correctly
- [ ] Transportation problem solves correctly
- [ ] Diet problem solves correctly
- [ ] Infeasible problem detected
- [ ] Unbounded problem detected
- [ ] Solutions match expected values
- [ ] Shadow prices computed
- [ ] Different solver options work
- [ ] No memory leaks
- [ ] Tests run in reasonable time

## Status
🟡 Not Started