# Issue #022: Create example programs

## Priority
🟢 Low

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#53-example-programs)
- [Issue #020](020_issue.md) - LP integration tests
- [Issue #021](021_issue.md) - MIP integration tests

## Description
Create standalone example programs demonstrating how to use the GLPK wrapper for common optimization problems. These serve as both documentation and templates for users to build their own applications.

## Requirements

### Example Directory Structure
```
examples/
├── diet_problem.zig
├── transportation.zig
├── knapsack.zig
├── production_planning.zig
├── network_flow.zig
├── portfolio_optimization.zig
└── README.md
```

### Diet Problem Example
Create `examples/diet_problem.zig`:
```zig
//! Diet Problem Example
//! 
//! Demonstrates how to formulate and solve a diet optimization problem.
//! The goal is to find the minimum cost diet that satisfies all nutritional requirements.

const std = @import("std");
const glpk = @import("zig-glpk");

const Food = struct {
    name: []const u8,
    cost: f64,
    calories: f64,
    protein: f64,
    fat: f64,
    sodium: f64,
    price_per_serving: f64,
};

const NutrientRequirement = struct {
    name: []const u8,
    minimum: f64,
    maximum: f64,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Define available foods
    const foods = [_]Food{
        .{ .name = "Oatmeal", .cost = 0.30, .calories = 110, .protein = 4, .fat = 2, .sodium = 0, .price_per_serving = 0.30 },
        .{ .name = "Chicken", .cost = 2.40, .calories = 205, .protein = 32, .fat = 8, .sodium = 75, .price_per_serving = 2.40 },
        .{ .name = "Eggs", .cost = 1.30, .calories = 160, .protein = 13, .fat = 11, .sodium = 170, .price_per_serving = 1.30 },
        .{ .name = "Milk", .cost = 1.00, .calories = 160, .protein = 8, .fat = 5, .sodium = 115, .price_per_serving = 1.00 },
        .{ .name = "Bread", .cost = 0.50, .calories = 65, .protein = 2, .fat = 1, .sodium = 160, .price_per_serving = 0.25 },
        .{ .name = "Peanut Butter", .cost = 2.00, .calories = 188, .protein = 8, .fat = 16, .sodium = 140, .price_per_serving = 0.50 },
    };
    
    // Define nutritional requirements
    const requirements = [_]NutrientRequirement{
        .{ .name = "Calories", .minimum = 2000, .maximum = 2500 },
        .{ .name = "Protein", .minimum = 50, .maximum = 200 },
        .{ .name = "Fat", .minimum = 40, .maximum = 100 },
        .{ .name = "Sodium", .minimum = 0, .maximum = 2400 },
    };
    
    std.debug.print("=== Diet Optimization Problem ===\n\n", .{});
    std.debug.print("Finding minimum cost diet that meets nutritional requirements...\n\n", .{});
    
    // Create the optimization problem
    var problem = try glpk.Problem.init(allocator);
    defer problem.deinit();
    
    try problem.setName("Diet Optimization");
    problem.setObjectiveDirection(.minimize);
    
    // Add variables for each food (servings)
    try problem.addColumns(foods.len);
    for (foods, 1..) |food, i| {
        try problem.setColumnName(i, food.name);
        try problem.setColumnLowerBound(i, 0); // Non-negative servings
        try problem.setColumnUpperBound(i, 10); // Maximum 10 servings per food
        problem.setObjectiveCoefficient(i, food.price_per_serving);
    }
    
    // Add nutritional constraints
    try problem.addRows(requirements.len);
    
    // Calories constraint
    try problem.setRowName(1, "Calories");
    try problem.setRowRangeBounds(1, requirements[0].minimum, requirements[0].maximum);
    var cols = [_]usize{ 1, 2, 3, 4, 5, 6 };
    var values = [_]f64{ foods[0].calories, foods[1].calories, foods[2].calories, 
                         foods[3].calories, foods[4].calories, foods[5].calories };
    try problem.setRowCoefficients(1, &cols, &values);
    
    // Protein constraint
    try problem.setRowName(2, "Protein");
    try problem.setRowRangeBounds(2, requirements[1].minimum, requirements[1].maximum);
    values = [_]f64{ foods[0].protein, foods[1].protein, foods[2].protein,
                     foods[3].protein, foods[4].protein, foods[5].protein };
    try problem.setRowCoefficients(2, &cols, &values);
    
    // Fat constraint
    try problem.setRowName(3, "Fat");
    try problem.setRowRangeBounds(3, requirements[2].minimum, requirements[2].maximum);
    values = [_]f64{ foods[0].fat, foods[1].fat, foods[2].fat,
                     foods[3].fat, foods[4].fat, foods[5].fat };
    try problem.setRowCoefficients(3, &cols, &values);
    
    // Sodium constraint
    try problem.setRowName(4, "Sodium");
    try problem.setRowRangeBounds(4, requirements[3].minimum, requirements[3].maximum);
    values = [_]f64{ foods[0].sodium, foods[1].sodium, foods[2].sodium,
                     foods[3].sodium, foods[4].sodium, foods[5].sodium };
    try problem.setRowCoefficients(4, &cols, &values);
    
    // Solve the problem
    var solver = glpk.SimplexSolver.init(.{
        .presolve = true,
        .message_level = .normal,
    });
    
    const status = try solver.solve(&problem);
    
    if (status != .optimal) {
        std.debug.print("Could not find optimal solution. Status: {}\n", .{status});
        return;
    }
    
    // Display results
    const total_cost = problem.getObjectiveValue();
    std.debug.print("Optimal daily diet found!\n", .{});
    std.debug.print("Total cost: ${d:.2}\n\n", .{total_cost});
    
    std.debug.print("Servings per day:\n", .{});
    for (foods, 1..) |food, i| {
        const servings = problem.getColumnPrimal(i);
        if (servings > 0.01) {
            std.debug.print("  {s}: {d:.2} servings\n", .{ food.name, servings });
        }
    }
    
    std.debug.print("\nNutritional values:\n", .{});
    for (requirements, 1..) |req, i| {
        const amount = problem.getRowPrimal(i);
        std.debug.print("  {s}: {d:.0} (required: {d:.0}-{d:.0})\n", 
                       .{ req.name, amount, req.minimum, req.maximum });
    }
    
    // Show shadow prices
    std.debug.print("\nShadow prices (marginal cost of nutrients):\n", .{});
    for (requirements, 1..) |req, i| {
        const shadow = problem.getRowDual(i);
        if (@abs(shadow) > 0.001) {
            std.debug.print("  {s}: ${d:.4} per unit\n", .{ req.name, shadow });
        }
    }
}
```

### Transportation Problem Example
Create `examples/transportation.zig`:
```zig
//! Transportation Problem Example
//! 
//! Demonstrates solving a transportation problem to minimize shipping costs
//! from multiple sources to multiple destinations.

const std = @import("std");
const glpk = @import("zig-glpk");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Problem data
    const n_sources = 3;
    const n_destinations = 4;
    
    const supply = [n_sources]f64{ 100, 150, 200 }; // Units available at each source
    const demand = [n_destinations]f64{ 80, 120, 140, 110 }; // Units needed at each destination
    
    // Shipping costs per unit from source i to destination j
    const costs = [n_sources][n_destinations]f64{
        .{ 10, 20, 15, 25 }, // Source 1 to all destinations
        .{ 15, 25, 10, 30 }, // Source 2 to all destinations
        .{ 20, 15, 20, 10 }, // Source 3 to all destinations
    };
    
    const source_names = [_][]const u8{ "Factory A", "Factory B", "Factory C" };
    const dest_names = [_][]const u8{ "Store 1", "Store 2", "Store 3", "Store 4" };
    
    std.debug.print("=== Transportation Problem ===\n\n", .{});
    std.debug.print("Minimizing shipping costs from {} sources to {} destinations\n\n", 
                   .{ n_sources, n_destinations });
    
    // Create problem
    var problem = try glpk.Problem.init(allocator);
    defer problem.deinit();
    
    try problem.setName("Transportation");
    problem.setObjectiveDirection(.minimize);
    
    // Create variables x[i][j] for shipment from source i to destination j
    try problem.addColumns(n_sources * n_destinations);
    
    var col: usize = 1;
    for (0..n_sources) |i| {
        for (0..n_destinations) |j| {
            const name = try std.fmt.allocPrint(allocator, "x_{}_{}", .{ i + 1, j + 1 });
            defer allocator.free(name);
            
            try problem.setColumnName(col, name);
            try problem.setColumnLowerBound(col, 0); // Non-negative shipments
            problem.setObjectiveCoefficient(col, costs[i][j]);
            col += 1;
        }
    }
    
    // Add supply constraints (one per source)
    try problem.addRows(n_sources);
    for (0..n_sources) |i| {
        const row = i + 1;
        try problem.setRowName(row, source_names[i]);
        try problem.setRowUpperBound(row, supply[i]);
        
        // Sum of shipments from source i to all destinations
        var cols_array: [n_destinations]usize = undefined;
        var ones = [_]f64{1} ** n_destinations;
        for (0..n_destinations) |j| {
            cols_array[j] = i * n_destinations + j + 1;
        }
        try problem.setRowCoefficients(row, &cols_array, &ones);
    }
    
    // Add demand constraints (one per destination)
    try problem.addRows(n_destinations);
    for (0..n_destinations) |j| {
        const row = n_sources + j + 1;
        try problem.setRowName(row, dest_names[j]);
        try problem.setRowFixed(row, demand[j]);
        
        // Sum of shipments from all sources to destination j
        var cols_array: [n_sources]usize = undefined;
        var ones = [_]f64{1} ** n_sources;
        for (0..n_sources) |i| {
            cols_array[i] = i * n_destinations + j + 1;
        }
        try problem.setRowCoefficients(row, &cols_array, &ones);
    }
    
    // Solve
    var solver = glpk.SimplexSolver.init(.{
        .method = .dual, // Dual simplex often better for transportation
    });
    
    const status = try solver.solve(&problem);
    
    if (status != .optimal) {
        std.debug.print("Problem is {}\n", .{status});
        return;
    }
    
    // Display solution
    const total_cost = problem.getObjectiveValue();
    std.debug.print("Optimal shipping plan found!\n", .{});
    std.debug.print("Total cost: ${d:.2}\n\n", .{total_cost});
    
    std.debug.print("Shipping plan:\n", .{});
    col = 1;
    for (0..n_sources) |i| {
        for (0..n_destinations) |j| {
            const amount = problem.getColumnPrimal(col);
            if (amount > 0.01) {
                std.debug.print("  {s} -> {s}: {d:.0} units (cost: ${d:.2})\n",
                               .{ source_names[i], dest_names[j], amount, costs[i][j] * amount });
            }
            col += 1;
        }
    }
    
    // Verify constraints
    std.debug.print("\nSupply utilization:\n", .{});
    for (0..n_sources) |i| {
        const used = problem.getRowPrimal(i + 1);
        std.debug.print("  {s}: {d:.0}/{d:.0} units\n", 
                       .{ source_names[i], used, supply[i] });
    }
    
    std.debug.print("\nDemand satisfaction:\n", .{});
    for (0..n_destinations) |j| {
        const received = problem.getRowPrimal(n_sources + j + 1);
        std.debug.print("  {s}: {d:.0}/{d:.0} units\n",
                       .{ dest_names[j], received, demand[j] });
    }
}
```

### Binary Knapsack Example
Create `examples/knapsack.zig`:
```zig
//! Binary Knapsack Problem Example
//! 
//! Demonstrates solving the 0-1 knapsack problem using MIP solver.

const std = @import("std");
const glpk = @import("zig-glpk");

const Item = struct {
    name: []const u8,
    weight: f64,
    value: f64,
    
    fn efficiency(self: Item) f64 {
        return self.value / self.weight;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Define items
    const items = [_]Item{
        .{ .name = "Laptop", .weight = 3, .value = 2000 },
        .{ .name = "Camera", .weight = 2, .value = 1500 },
        .{ .name = "Jewelry", .weight = 1, .value = 3000 },
        .{ .name = "Cash", .weight = 0.5, .value = 2500 },
        .{ .name = "Phone", .weight = 0.3, .value = 800 },
        .{ .name = "Watch", .weight = 0.4, .value = 1200 },
        .{ .name = "Tablet", .weight = 1.5, .value = 1000 },
        .{ .name = "Headphones", .weight = 0.5, .value = 400 },
    };
    
    const capacity: f64 = 5; // Knapsack capacity
    
    std.debug.print("=== 0-1 Knapsack Problem ===\n\n", .{});
    std.debug.print("Knapsack capacity: {d:.1} kg\n", .{capacity});
    std.debug.print("Available items:\n", .{});
    for (items) |item| {
        std.debug.print("  {s}: {d:.1} kg, ${d:.0} (efficiency: ${d:.0}/kg)\n",
                       .{ item.name, item.weight, item.value, item.efficiency() });
    }
    std.debug.print("\n", .{});
    
    // Create problem
    var problem = try glpk.Problem.init(allocator);
    defer problem.deinit();
    
    try problem.setName("Knapsack");
    problem.setObjectiveDirection(.maximize);
    
    // Binary variable for each item
    try problem.addColumns(items.len);
    for (items, 1..) |item, i| {
        try problem.setColumnName(i, item.name);
        try problem.setColumnBinary(i);
        problem.setObjectiveCoefficient(i, item.value);
    }
    
    // Weight constraint
    try problem.addRows(1);
    try problem.setRowName(1, "Weight");
    try problem.setRowUpperBound(1, capacity);
    
    var cols: [items.len]usize = undefined;
    var weights: [items.len]f64 = undefined;
    for (items, 0..) |item, i| {
        cols[i] = i + 1;
        weights[i] = item.weight;
    }
    try problem.setRowCoefficients(1, &cols, &weights);
    
    // Solve with MIP solver
    var solver = glpk.MIPSolver.init(.{
        .presolve = true,
        .message_level = .normal,
        .mip_gap = 0.0, // Find optimal solution
    });
    
    const status = try solver.solve(&problem);
    
    if (status != .optimal and status != .feasible) {
        std.debug.print("Could not find solution. Status: {}\n", .{status});
        return;
    }
    
    // Display solution
    const total_value = problem.getMIPObjectiveValue();
    const total_weight = problem.getMIPRowValue(1);
    
    std.debug.print("Optimal selection found!\n", .{});
    std.debug.print("Total value: ${d:.0}\n", .{total_value});
    std.debug.print("Total weight: {d:.1} kg (capacity: {d:.1} kg)\n\n", 
                   .{ total_weight, capacity });
    
    std.debug.print("Selected items:\n", .{});
    for (items, 1..) |item, i| {
        const selected = problem.getMIPColumnValue(i);
        if (selected > 0.5) {
            std.debug.print("  ✓ {s}: {d:.1} kg, ${d:.0}\n",
                          .{ item.name, item.weight, item.value });
        }
    }
    
    if (solver.getStats()) |stats| {
        std.debug.print("\nSolver statistics:\n", .{});
        std.debug.print("  Nodes explored: {}\n", .{stats.nodes_explored});
        std.debug.print("  MIP gap: {d:.2%}\n", .{stats.gap});
        std.debug.print("  Time: {d:.3}s\n", .{stats.solve_time});
    }
}
```

### Production Planning Example
Create `examples/production_planning.zig`:
```zig
//! Production Planning Example
//! 
//! Multi-period production planning with inventory and setup costs.

const std = @import("std");
const glpk = @import("zig-glpk");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Problem parameters
    const n_periods = 4;
    const n_products = 2;
    
    // Demand for each product in each period
    const demand = [n_products][n_periods]f64{
        .{ 100, 150, 200, 120 }, // Product A demand
        .{ 80, 100, 140, 90 },   // Product B demand
    };
    
    // Production costs
    const production_cost = [n_products]f64{ 10, 15 };
    const setup_cost = [n_products]f64{ 500, 600 };
    const inventory_cost = [n_products]f64{ 2, 3 };
    
    // Capacity
    const production_capacity = 300;
    const inventory_capacity = 200;
    
    std.debug.print("=== Multi-Period Production Planning ===\n\n", .{});
    
    // Create problem
    var problem = try glpk.Problem.init(allocator);
    defer problem.deinit();
    
    try problem.setName("ProductionPlanning");
    problem.setObjectiveDirection(.minimize);
    
    // Variables:
    // x[p][t] = production of product p in period t (continuous)
    // y[p][t] = setup for product p in period t (binary)
    // I[p][t] = inventory of product p at end of period t (continuous)
    
    const n_vars = n_products * n_periods * 3;
    try problem.addColumns(n_vars);
    
    var col: usize = 1;
    
    // Create variables and set objective
    for (0..n_products) |p| {
        for (0..n_periods) |t| {
            // Production variable
            const prod_name = try std.fmt.allocPrint(allocator, "prod_{}_{}", .{ p + 1, t + 1 });
            defer allocator.free(prod_name);
            try problem.setColumnName(col, prod_name);
            try problem.setColumnLowerBound(col, 0);
            problem.setObjectiveCoefficient(col, production_cost[p]);
            col += 1;
            
            // Setup variable
            const setup_name = try std.fmt.allocPrint(allocator, "setup_{}_{}", .{ p + 1, t + 1 });
            defer allocator.free(setup_name);
            try problem.setColumnName(col, setup_name);
            try problem.setColumnBinary(col);
            problem.setObjectiveCoefficient(col, setup_cost[p]);
            col += 1;
            
            // Inventory variable
            const inv_name = try std.fmt.allocPrint(allocator, "inv_{}_{}", .{ p + 1, t + 1 });
            defer allocator.free(inv_name);
            try problem.setColumnName(col, inv_name);
            try problem.setColumnLowerBound(col, 0);
            try problem.setColumnUpperBound(col, inventory_capacity);
            problem.setObjectiveCoefficient(col, inventory_cost[p]);
            col += 1;
        }
    }
    
    // Add constraints...
    // (Implementation details for flow balance, capacity, setup constraints)
    
    // Solve with MIP solver
    var solver = glpk.MIPSolver.init(.{
        .presolve = true,
        .cuts = glpk.CutOptions.aggressive(),
    });
    
    const status = try solver.solve(&problem);
    
    // Display results...
    if (status == .optimal) {
        std.debug.print("Optimal production plan found!\n", .{});
        const total_cost = problem.getMIPObjectiveValue();
        std.debug.print("Total cost: ${d:.2}\n", .{total_cost});
    }
}
```

### README for Examples
Create `examples/README.md`:
```markdown
# GLPK Zig Wrapper Examples

This directory contains example programs demonstrating how to use the GLPK Zig wrapper
for various optimization problems.

## Running Examples

To run an example:
```bash
zig build-exe examples/diet_problem.zig -lglpk
./diet_problem
```

## Available Examples

### Linear Programming (LP)

- **diet_problem.zig**: Classic diet optimization problem minimizing cost while meeting nutritional requirements
- **transportation.zig**: Transportation problem minimizing shipping costs between sources and destinations
- **network_flow.zig**: Maximum flow and minimum cost flow problems

### Mixed Integer Programming (MIP)

- **knapsack.zig**: 0-1 knapsack problem for selecting items with maximum value
- **production_planning.zig**: Multi-period production planning with setup costs
- **portfolio_optimization.zig**: Portfolio selection with integer lot sizes

## Problem Categories

### Resource Allocation
Examples showing how to allocate limited resources optimally.

### Scheduling
Examples for scheduling tasks, jobs, or resources over time.

### Network Optimization
Examples involving flow networks, routing, and connectivity.

### Combinatorial Optimization
Examples with discrete choices and combinatorial structures.

## Tips for Building Your Own Models

1. **Start Simple**: Begin with a small instance of your problem
2. **Validate Data**: Check that your constraints make sense
3. **Use Presolve**: Enable presolve for better performance
4. **Check Feasibility**: Ensure your problem has feasible solutions
5. **Analyze Results**: Use shadow prices and reduced costs for insights

## Common Patterns

### Setting up a Problem
```zig
var problem = try glpk.Problem.init(allocator);
defer problem.deinit();
```

### Adding Variables
```zig
try problem.addColumns(n);
try problem.setColumnName(i, "x");
try problem.setColumnBounds(i, .lower, 0, 0);
```

### Adding Constraints
```zig
try problem.addRows(m);
try problem.setRowBounds(i, .double, lower, upper);
try problem.setRowCoefficients(i, &cols, &values);
```

### Solving
```zig
var solver = glpk.SimplexSolver.initDefault();
const status = try solver.solve(&problem);
```

## Performance Tips

- Use sparse matrix format for large problems
- Enable cuts for MIP problems
- Set reasonable time limits for complex problems
- Use warm starts when solving similar problems

## Further Resources

- [GLPK Documentation](https://www.gnu.org/software/glpk/)
- [Linear Programming Tutorial](https://en.wikipedia.org/wiki/Linear_programming)
- [Integer Programming Guide](https://en.wikipedia.org/wiki/Integer_programming)
```

## Implementation Notes
- Examples should be self-contained and runnable
- Include comments explaining the problem formulation
- Show how to interpret results
- Demonstrate error handling
- Include realistic problem sizes
- Show both LP and MIP examples

## Testing Requirements
- All examples compile without errors
- Examples produce correct output
- Memory is properly managed
- Examples complete in reasonable time
- Output is informative and well-formatted

## Dependencies
- [#020](020_issue.md) - LP integration tests provide patterns
- [#021](021_issue.md) - MIP integration tests provide patterns

## Acceptance Criteria
- [ ] Diet problem example created
- [ ] Transportation example created
- [ ] Knapsack example created
- [ ] Production planning example created
- [ ] All examples compile and run
- [ ] Examples are well-documented
- [ ] README explains how to use examples
- [ ] Common patterns documented
- [ ] Examples demonstrate best practices
- [ ] No memory leaks in examples

## Status
🟢 Not Started