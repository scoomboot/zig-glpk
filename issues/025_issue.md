# Issue #025: Performance benchmarking and optimization

## Priority
🟡 Medium

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#63-performance-considerations)
- [Issue #020](020_issue.md) - LP integration tests
- [Issue #021](021_issue.md) - MIP integration tests

## Description
Implement comprehensive performance benchmarks, identify bottlenecks, and optimize the wrapper to minimize overhead compared to direct C API usage. Ensure the wrapper adds minimal performance penalty.

## Requirements

### Benchmark Framework
Create `bench/benchmark.zig`:
```zig
//! Performance benchmarking framework

const std = @import("std");
const glpk = @import("zig-glpk");

pub const BenchmarkResult = struct {
    name: []const u8,
    iterations: usize,
    total_time_ns: u64,
    mean_time_ns: u64,
    min_time_ns: u64,
    max_time_ns: u64,
    std_dev_ns: u64,
    operations_per_second: f64,
    
    pub fn print(self: BenchmarkResult) void {
        std.debug.print("{s}:\n", .{self.name});
        std.debug.print("  Iterations: {}\n", .{self.iterations});
        std.debug.print("  Mean time: {d:.3} ms\n", .{@as(f64, @floatFromInt(self.mean_time_ns)) / 1_000_000});
        std.debug.print("  Min time: {d:.3} ms\n", .{@as(f64, @floatFromInt(self.min_time_ns)) / 1_000_000});
        std.debug.print("  Max time: {d:.3} ms\n", .{@as(f64, @floatFromInt(self.max_time_ns)) / 1_000_000});
        std.debug.print("  Std dev: {d:.3} ms\n", .{@as(f64, @floatFromInt(self.std_dev_ns)) / 1_000_000});
        std.debug.print("  Ops/sec: {d:.0}\n", .{self.operations_per_second});
    }
};

pub fn benchmark(
    comptime name: []const u8,
    comptime func: anytype,
    args: anytype,
    iterations: usize,
) !BenchmarkResult {
    var times = try std.ArrayList(u64).initCapacity(std.heap.page_allocator, iterations);
    defer times.deinit();
    
    // Warmup
    for (0..@min(10, iterations / 10)) |_| {
        _ = try @call(.auto, func, args);
    }
    
    // Actual benchmark
    var total_time: u64 = 0;
    var min_time: u64 = std.math.maxInt(u64);
    var max_time: u64 = 0;
    
    for (0..iterations) |_| {
        const start = std.time.nanoTimestamp();
        _ = try @call(.auto, func, args);
        const end = std.time.nanoTimestamp();
        
        const elapsed = @intCast(u64, end - start);
        try times.append(elapsed);
        
        total_time += elapsed;
        min_time = @min(min_time, elapsed);
        max_time = @max(max_time, elapsed);
    }
    
    const mean_time = total_time / iterations;
    
    // Calculate standard deviation
    var variance: u64 = 0;
    for (times.items) |time| {
        const diff = if (time > mean_time) time - mean_time else mean_time - time;
        variance += diff * diff;
    }
    const std_dev = std.math.sqrt(@as(f64, @floatFromInt(variance / iterations)));
    
    return BenchmarkResult{
        .name = name,
        .iterations = iterations,
        .total_time_ns = total_time,
        .mean_time_ns = mean_time,
        .min_time_ns = min_time,
        .max_time_ns = max_time,
        .std_dev_ns = @intFromFloat(std_dev),
        .operations_per_second = @as(f64, @floatFromInt(iterations)) / (@as(f64, @floatFromInt(total_time)) / 1_000_000_000),
    };
}
```

### Core Operation Benchmarks
Create `bench/core_bench.zig`:
```zig
const std = @import("std");
const glpk = @import("zig-glpk");
const bench = @import("benchmark.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    std.debug.print("=== GLPK Wrapper Performance Benchmarks ===\n\n", .{});
    
    // Benchmark problem creation
    const create_result = try bench.benchmark(
        "Problem creation",
        benchProblemCreation,
        .{allocator},
        1000,
    );
    create_result.print();
    
    // Benchmark row/column addition
    const row_result = try bench.benchmark(
        "Add 100 rows",
        benchRowAddition,
        .{allocator},
        100,
    );
    row_result.print();
    
    // Benchmark matrix loading
    const matrix_result = try bench.benchmark(
        "Load 10000 element matrix",
        benchMatrixLoading,
        .{allocator},
        100,
    );
    matrix_result.print();
    
    // Compare with C API
    try compareWithCAPI(allocator);
}

fn benchProblemCreation(allocator: std.mem.Allocator) !void {
    var problem = try glpk.Problem.init(allocator);
    defer problem.deinit();
}

fn benchRowAddition(allocator: std.mem.Allocator) !void {
    var problem = try glpk.Problem.init(allocator);
    defer problem.deinit();
    
    try problem.addRows(100);
    for (1..101) |i| {
        try problem.setRowBounds(i, .double, 0, 100);
    }
}

fn benchMatrixLoading(allocator: std.mem.Allocator) !void {
    var problem = try glpk.Problem.init(allocator);
    defer problem.deinit();
    
    try problem.addRows(100);
    try problem.addColumns(100);
    
    // Create sparse matrix
    const nnz = 10000;
    var rows = try allocator.alloc(usize, nnz);
    defer allocator.free(rows);
    var cols = try allocator.alloc(usize, nnz);
    defer allocator.free(cols);
    var values = try allocator.alloc(f64, nnz);
    defer allocator.free(values);
    
    // Fill with diagonal pattern
    for (0..100) |i| {
        for (0..100) |j| {
            const idx = i * 100 + j;
            rows[idx] = i + 1;
            cols[idx] = j + 1;
            values[idx] = if (i == j) 1.0 else 0.0;
        }
    }
    
    const matrix = glpk.SparseMatrix{
        .rows = rows,
        .cols = cols,
        .values = values,
    };
    try problem.loadMatrix(matrix);
}

fn compareWithCAPI(allocator: std.mem.Allocator) !void {
    std.debug.print("\n=== Wrapper vs C API Comparison ===\n", .{});
    
    // Benchmark Zig wrapper
    const zig_start = std.time.nanoTimestamp();
    {
        var problem = try glpk.Problem.init(allocator);
        defer problem.deinit();
        
        try problem.addRows(1000);
        try problem.addColumns(1000);
        // ... setup problem
        
        var solver = glpk.SimplexSolver.initDefault();
        _ = try solver.solve(&problem);
    }
    const zig_end = std.time.nanoTimestamp();
    const zig_time = @intCast(u64, zig_end - zig_start);
    
    // Benchmark C API directly
    const c_start = std.time.nanoTimestamp();
    {
        const prob = glpk.c.glp_create_prob();
        defer glpk.c.glp_delete_prob(prob);
        
        _ = glpk.c.glp_add_rows(prob, 1000);
        _ = glpk.c.glp_add_cols(prob, 1000);
        // ... setup problem
        
        var params: glpk.c.glp_smcp = undefined;
        glpk.c.glp_init_smcp(&params);
        _ = glpk.c.glp_simplex(prob, &params);
    }
    const c_end = std.time.nanoTimestamp();
    const c_time = @intCast(u64, c_end - c_start);
    
    const overhead = @as(f64, @floatFromInt(zig_time - c_time)) / @as(f64, @floatFromInt(c_time)) * 100;
    
    std.debug.print("Zig wrapper: {d:.3} ms\n", .{@as(f64, @floatFromInt(zig_time)) / 1_000_000});
    std.debug.print("C API: {d:.3} ms\n", .{@as(f64, @floatFromInt(c_time)) / 1_000_000});
    std.debug.print("Overhead: {d:.1}%\n", .{overhead});
}
```

### Solver Performance Benchmarks
Create `bench/solver_bench.zig`:
```zig
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    std.debug.print("=== Solver Performance Benchmarks ===\n\n", .{});
    
    // Test different problem sizes
    const sizes = [_]usize{ 10, 50, 100, 500, 1000 };
    
    for (sizes) |size| {
        const result = try benchmarkSolverSize(allocator, size);
        std.debug.print("Problem size {}x{}: {d:.3} ms\n", 
                       .{ size, size, @as(f64, @floatFromInt(result)) / 1_000_000 });
    }
    
    // Test different solver options
    try benchmarkSolverOptions(allocator);
    
    // Test MIP vs LP
    try benchmarkMIPvsLP(allocator);
}

fn benchmarkSolverSize(allocator: std.mem.Allocator, size: usize) !u64 {
    var problem = try createRandomLP(allocator, size, size);
    defer problem.deinit();
    
    const start = std.time.nanoTimestamp();
    var solver = glpk.SimplexSolver.initDefault();
    _ = try solver.solve(&problem);
    const end = std.time.nanoTimestamp();
    
    return @intCast(u64, end - start);
}

fn benchmarkSolverOptions(allocator: std.mem.Allocator) !void {
    std.debug.print("\n=== Solver Options Impact ===\n", .{});
    
    var problem = try createRandomLP(allocator, 100, 100);
    defer problem.deinit();
    
    // Default options
    {
        var solver = glpk.SimplexSolver.initDefault();
        const start = std.time.nanoTimestamp();
        _ = try solver.solve(&problem);
        const end = std.time.nanoTimestamp();
        const time = @intCast(u64, end - start);
        std.debug.print("Default options: {d:.3} ms\n", .{@as(f64, @floatFromInt(time)) / 1_000_000});
    }
    
    // Fast options
    {
        var solver = glpk.SimplexSolver.init(glpk.SimplexOptions.fast());
        const start = std.time.nanoTimestamp();
        _ = try solver.solve(&problem);
        const end = std.time.nanoTimestamp();
        const time = @intCast(u64, end - start);
        std.debug.print("Fast options: {d:.3} ms\n", .{@as(f64, @floatFromInt(time)) / 1_000_000});
    }
    
    // With presolve disabled
    {
        var solver = glpk.SimplexSolver.init(.{ .presolve = false });
        const start = std.time.nanoTimestamp();
        _ = try solver.solve(&problem);
        const end = std.time.nanoTimestamp();
        const time = @intCast(u64, end - start);
        std.debug.print("No presolve: {d:.3} ms\n", .{@as(f64, @floatFromInt(time)) / 1_000_000});
    }
}

fn createRandomLP(allocator: std.mem.Allocator, rows: usize, cols: usize) !glpk.Problem {
    var problem = try glpk.Problem.init(allocator);
    
    try problem.addRows(rows);
    try problem.addColumns(cols);
    
    // Set random objective
    var rng = std.rand.DefaultPrng.init(42);
    const random = rng.random();
    
    for (1..cols + 1) |i| {
        problem.setObjectiveCoefficient(i, random.float(f64) * 100);
        try problem.setColumnLowerBound(i, 0);
    }
    
    // Set random constraints
    for (1..rows + 1) |i| {
        try problem.setRowUpperBound(i, random.float(f64) * 1000 + 100);
        
        // Random sparse coefficients
        var col_indices: [10]usize = undefined;
        var coeffs: [10]f64 = undefined;
        for (0..10) |j| {
            col_indices[j] = random.intRangeAtMost(usize, 1, cols);
            coeffs[j] = random.float(f64) * 10;
        }
        try problem.setRowCoefficients(i, &col_indices, &coeffs);
    }
    
    return problem;
}
```

### Profiling Integration
Create `bench/profile.zig`:
```zig
//! Profiling utilities for performance analysis

const std = @import("std");

pub const Profiler = struct {
    sections: std.StringHashMap(Section),
    allocator: std.mem.Allocator,
    
    const Section = struct {
        name: []const u8,
        call_count: usize,
        total_time: u64,
        min_time: u64,
        max_time: u64,
    };
    
    pub fn init(allocator: std.mem.Allocator) Profiler {
        return .{
            .sections = std.StringHashMap(Section).init(allocator),
            .allocator = allocator,
        };
    }
    
    pub fn deinit(self: *Profiler) void {
        self.sections.deinit();
    }
    
    pub fn beginSection(self: *Profiler, name: []const u8) Timer {
        return Timer{
            .profiler = self,
            .name = name,
            .start = std.time.nanoTimestamp(),
        };
    }
    
    pub fn endSection(self: *Profiler, timer: Timer) void {
        const elapsed = @intCast(u64, std.time.nanoTimestamp() - timer.start);
        
        if (self.sections.get(timer.name)) |*section| {
            section.call_count += 1;
            section.total_time += elapsed;
            section.min_time = @min(section.min_time, elapsed);
            section.max_time = @max(section.max_time, elapsed);
        } else {
            self.sections.put(timer.name, .{
                .name = timer.name,
                .call_count = 1,
                .total_time = elapsed,
                .min_time = elapsed,
                .max_time = elapsed,
            }) catch {};
        }
    }
    
    pub fn report(self: *const Profiler) void {
        std.debug.print("\n=== Profiler Report ===\n", .{});
        std.debug.print("{s:<30} {s:>10} {s:>12} {s:>12} {s:>12}\n", 
                       .{ "Section", "Calls", "Total (ms)", "Mean (ms)", "Max (ms)" });
        std.debug.print("{s:-<78}\n", .{""});
        
        var iter = self.sections.iterator();
        while (iter.next()) |entry| {
            const section = entry.value_ptr.*;
            const mean = section.total_time / section.call_count;
            
            std.debug.print("{s:<30} {d:>10} {d:>12.3} {d:>12.3} {d:>12.3}\n", .{
                section.name,
                section.call_count,
                @as(f64, @floatFromInt(section.total_time)) / 1_000_000,
                @as(f64, @floatFromInt(mean)) / 1_000_000,
                @as(f64, @floatFromInt(section.max_time)) / 1_000_000,
            });
        }
    }
    
    const Timer = struct {
        profiler: *Profiler,
        name: []const u8,
        start: i128,
    };
};

// Usage in Problem struct:
// const timer = profiler.beginSection("addRows");
// defer profiler.endSection(timer);
```

### Optimization Opportunities
```zig
// 1. Inline hot functions
pub inline fn getRowCount(self: *const Problem) usize {
    return @intCast(glpk.c.glp_get_num_rows(self.ptr));
}

// 2. Cache frequently accessed values
pub const Problem = struct {
    ptr: *glpk.c.glp_prob,
    allocator: std.mem.Allocator,
    // Cache these values
    row_count: usize,
    col_count: usize,
    
    pub fn addRows(self: *Problem, count: usize) !void {
        const result = glpk.c.glp_add_rows(self.ptr, @intCast(count));
        if (result > 0) {
            self.row_count += count; // Update cache
        }
    }
};

// 3. Batch operations
pub fn setMultipleObjectiveCoefficients(
    self: *Problem,
    start_col: usize,
    coeffs: []const f64,
) void {
    // Single loop instead of multiple function calls
    for (coeffs, start_col..) |coef, col| {
        glpk.c.glp_set_obj_coef(self.ptr, @intCast(col), coef);
    }
}

// 4. Use appropriate data structures
pub const SparseMatrixBuilder = struct {
    // Use ArrayList for dynamic growth
    rows: std.ArrayList(usize),
    cols: std.ArrayList(usize),
    values: std.ArrayList(f64),
    
    // Pre-allocate capacity
    pub fn initCapacity(allocator: std.mem.Allocator, capacity: usize) !SparseMatrixBuilder {
        return .{
            .rows = try std.ArrayList(usize).initCapacity(allocator, capacity),
            .cols = try std.ArrayList(usize).initCapacity(allocator, capacity),
            .values = try std.ArrayList(f64).initCapacity(allocator, capacity),
        };
    }
};
```

## Implementation Notes
- Minimize wrapper overhead to < 5%
- Profile hot paths and optimize them
- Use inline for small functions
- Cache frequently accessed values
- Batch operations where possible
- Compare with C API performance

## Testing Requirements
- Benchmark all major operations
- Compare with direct C API
- Profile hot paths
- Test with various problem sizes
- Measure memory usage
- Test solver option impact

## Dependencies
- [#020](020_issue.md) - LP test problems
- [#021](021_issue.md) - MIP test problems

## Acceptance Criteria
- [ ] Benchmark framework implemented
- [ ] Core operation benchmarks created
- [ ] Solver performance benchmarks done
- [ ] Profiler integrated
- [ ] Wrapper overhead < 5%
- [ ] Hot paths optimized
- [ ] Caching implemented where beneficial
- [ ] Batch operations available
- [ ] Performance regression tests
- [ ] Documentation includes performance tips

## Status
🟡 Not Started