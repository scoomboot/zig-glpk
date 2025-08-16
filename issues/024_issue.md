# Issue #024: Add memory management verification

## Priority
🟡 Medium

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#62-memory-management)
- [Issue #019](019_issue.md) - Problem management tests
- [Issue #020](020_issue.md) - LP integration tests
- [Issue #021](021_issue.md) - MIP integration tests

## Description
Implement comprehensive memory management verification to ensure all GLPK resources are properly freed, detect memory leaks, and verify safe memory usage patterns throughout the wrapper.

## Requirements

### Memory Tracking System
Create `lib/core/utils/memory/memory.zig`:
```zig
//! Memory management utilities and leak detection

const std = @import("std");

/// Tracking allocator that monitors allocations
pub const TrackingAllocator = struct {
    backing_allocator: std.mem.Allocator,
    allocations: std.hash_map.HashMap(usize, AllocationInfo, std.hash_map.AutoContext(usize), 80),
    total_allocated: usize,
    total_freed: usize,
    peak_usage: usize,
    current_usage: usize,
    allocation_count: usize,
    free_count: usize,
    
    const AllocationInfo = struct {
        size: usize,
        alignment: u8,
        stack_trace: ?[]usize,
        timestamp: i64,
    };
    
    pub fn init(backing_allocator: std.mem.Allocator) TrackingAllocator {
        return .{
            .backing_allocator = backing_allocator,
            .allocations = std.hash_map.HashMap(usize, AllocationInfo, std.hash_map.AutoContext(usize), 80).init(backing_allocator),
            .total_allocated = 0,
            .total_freed = 0,
            .peak_usage = 0,
            .current_usage = 0,
            .allocation_count = 0,
            .free_count = 0,
        };
    }
    
    pub fn deinit(self: *TrackingAllocator) void {
        if (self.allocations.count() > 0) {
            std.debug.print("Memory leak detected! {} allocations not freed\n", .{self.allocations.count()});
            
            var iter = self.allocations.iterator();
            while (iter.next()) |entry| {
                std.debug.print("  Leaked {} bytes at 0x{x}\n", .{ entry.value_ptr.size, entry.key_ptr.* });
            }
        }
        
        self.allocations.deinit();
    }
    
    pub fn allocator(self: *TrackingAllocator) std.mem.Allocator {
        return .{
            .ptr = self,
            .vtable = &.{
                .alloc = alloc,
                .resize = resize,
                .free = free,
            },
        };
    }
    
    fn alloc(ctx: *anyopaque, len: usize, ptr_align: u8, ret_addr: usize) ?[*]u8 {
        const self = @ptrCast(*TrackingAllocator, @alignCast(@alignOf(TrackingAllocator), ctx));
        
        const result = self.backing_allocator.rawAlloc(len, ptr_align, ret_addr);
        if (result) |ptr| {
            const address = @intFromPtr(ptr);
            
            const info = AllocationInfo{
                .size = len,
                .alignment = ptr_align,
                .stack_trace = null, // Could capture stack trace here
                .timestamp = std.time.milliTimestamp(),
            };
            
            self.allocations.put(address, info) catch {
                // Failed to track, but allocation succeeded
                std.debug.print("Warning: Failed to track allocation\n", .{});
            };
            
            self.total_allocated += len;
            self.current_usage += len;
            self.allocation_count += 1;
            
            if (self.current_usage > self.peak_usage) {
                self.peak_usage = self.current_usage;
            }
        }
        
        return result;
    }
    
    fn resize(ctx: *anyopaque, buf: []u8, buf_align: u8, new_len: usize, ret_addr: usize) bool {
        const self = @ptrCast(*TrackingAllocator, @alignCast(@alignOf(TrackingAllocator), ctx));
        
        const old_addr = @intFromPtr(buf.ptr);
        const result = self.backing_allocator.rawResize(buf, buf_align, new_len, ret_addr);
        
        if (result) {
            if (self.allocations.get(old_addr)) |old_info| {
                self.current_usage = self.current_usage - old_info.size + new_len;
                
                var new_info = old_info;
                new_info.size = new_len;
                self.allocations.put(old_addr, new_info) catch {};
                
                if (self.current_usage > self.peak_usage) {
                    self.peak_usage = self.current_usage;
                }
            }
        }
        
        return result;
    }
    
    fn free(ctx: *anyopaque, buf: []u8, buf_align: u8, ret_addr: usize) void {
        const self = @ptrCast(*TrackingAllocator, @alignCast(@alignOf(TrackingAllocator), ctx));
        
        const address = @intFromPtr(buf.ptr);
        
        if (self.allocations.fetchRemove(address)) |entry| {
            self.total_freed += entry.value.size;
            self.current_usage -= entry.value.size;
            self.free_count += 1;
        } else {
            std.debug.print("Warning: Freeing untracked memory at 0x{x}\n", .{address});
        }
        
        self.backing_allocator.rawFree(buf, buf_align, ret_addr);
    }
    
    pub fn report(self: *const TrackingAllocator) void {
        std.debug.print("\n=== Memory Report ===\n", .{});
        std.debug.print("Total allocated: {} bytes\n", .{self.total_allocated});
        std.debug.print("Total freed: {} bytes\n", .{self.total_freed});
        std.debug.print("Current usage: {} bytes\n", .{self.current_usage});
        std.debug.print("Peak usage: {} bytes\n", .{self.peak_usage});
        std.debug.print("Allocations: {}\n", .{self.allocation_count});
        std.debug.print("Frees: {}\n", .{self.free_count});
        std.debug.print("Active allocations: {}\n", .{self.allocations.count()});
        
        if (self.allocations.count() == 0) {
            std.debug.print("✓ No memory leaks detected\n", .{});
        } else {
            std.debug.print("✗ Potential memory leaks: {} allocations\n", .{self.allocations.count()});
        }
        std.debug.print("==================\n\n", .{});
    }
};
```

### GLPK Resource Tracking
```zig
/// Track GLPK-specific resources
pub const GLPKResourceTracker = struct {
    problems: std.ArrayList(*glpk.c.glp_prob),
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) GLPKResourceTracker {
        return .{
            .problems = std.ArrayList(*glpk.c.glp_prob).init(allocator),
            .allocator = allocator,
        };
    }
    
    pub fn deinit(self: *GLPKResourceTracker) void {
        // Clean up any leaked problems
        for (self.problems.items) |prob| {
            std.debug.print("Warning: GLPK problem not freed\n", .{});
            glpk.c.glp_delete_prob(prob);
        }
        self.problems.deinit();
    }
    
    pub fn trackProblem(self: *GLPKResourceTracker, prob: *glpk.c.glp_prob) !void {
        try self.problems.append(prob);
    }
    
    pub fn untrackProblem(self: *GLPKResourceTracker, prob: *glpk.c.glp_prob) void {
        for (self.problems.items, 0..) |p, i| {
            if (p == prob) {
                _ = self.problems.swapRemove(i);
                return;
            }
        }
        std.debug.print("Warning: Untracking unknown GLPK problem\n", .{});
    }
};
```

### Memory Leak Tests
Create `test/memory/leak_test.zig`:
```zig
const std = @import("std");
const testing = std.testing;
const glpk = @import("zig-glpk");
const memory = @import("memory");

test "Problem creation and destruction - no leaks" {
    var tracker = memory.TrackingAllocator.init(testing.allocator);
    defer {
        tracker.report();
        tracker.deinit();
    }
    const allocator = tracker.allocator();
    
    // Create and destroy multiple problems
    for (0..100) |_| {
        var problem = try glpk.Problem.init(allocator);
        defer problem.deinit();
        
        try problem.setName("TestProblem");
        try problem.addRows(10);
        try problem.addColumns(10);
    }
    
    try testing.expectEqual(@as(usize, 0), tracker.allocations.count());
}

test "Solver memory management" {
    var tracker = memory.TrackingAllocator.init(testing.allocator);
    defer {
        tracker.report();
        tracker.deinit();
    }
    const allocator = tracker.allocator();
    
    var problem = try glpk.Problem.init(allocator);
    defer problem.deinit();
    
    // Build a problem
    try problem.addColumns(50);
    try problem.addRows(30);
    // ... set up problem
    
    // Solve multiple times
    for (0..10) |_| {
        var solver = glpk.SimplexSolver.initDefault();
        _ = try solver.solve(&problem);
        
        // Get solution (allocates memory)
        const solution = try problem.getSolution(allocator);
        defer solution.deinit();
    }
    
    try testing.expectEqual(@as(usize, 0), tracker.allocations.count());
}

test "Large problem memory usage" {
    var tracker = memory.TrackingAllocator.init(testing.allocator);
    defer tracker.deinit();
    const allocator = tracker.allocator();
    
    {
        var problem = try glpk.Problem.init(allocator);
        defer problem.deinit();
        
        // Create a large problem
        try problem.addRows(1000);
        try problem.addColumns(1000);
        
        // Load sparse matrix
        const nnz = 10000;
        var rows = try allocator.alloc(usize, nnz);
        defer allocator.free(rows);
        var cols = try allocator.alloc(usize, nnz);
        defer allocator.free(cols);
        var values = try allocator.alloc(f64, nnz);
        defer allocator.free(values);
        
        // Fill with random sparse pattern
        var rng = std.rand.DefaultPrng.init(42);
        const random = rng.random();
        for (0..nnz) |i| {
            rows[i] = random.intRangeAtMost(usize, 1, 1000);
            cols[i] = random.intRangeAtMost(usize, 1, 1000);
            values[i] = random.float(f64);
        }
        
        const matrix = glpk.SparseMatrix{
            .rows = rows,
            .cols = cols,
            .values = values,
        };
        try problem.loadMatrix(matrix);
    }
    
    tracker.report();
    
    // Verify all memory was freed
    try testing.expectEqual(@as(usize, 0), tracker.allocations.count());
    try testing.expectEqual(tracker.total_allocated, tracker.total_freed);
}
```

### Valgrind Integration
Create `test/memory/valgrind_test.sh`:
```bash
#!/bin/bash
# Run tests under valgrind to detect memory issues

echo "Running memory leak detection with valgrind..."

# Build test executable
zig build test -Doptimize=Debug

# Run under valgrind
valgrind \
    --leak-check=full \
    --show-leak-kinds=all \
    --track-origins=yes \
    --verbose \
    --log-file=valgrind.log \
    ./zig-out/bin/test

# Check results
if grep -q "ERROR SUMMARY: 0 errors" valgrind.log; then
    echo "✓ No memory errors detected"
    
    if grep -q "All heap blocks were freed" valgrind.log; then
        echo "✓ No memory leaks detected"
        exit 0
    else
        echo "✗ Memory leaks detected"
        grep "definitely lost\|indirectly lost" valgrind.log
        exit 1
    fi
else
    echo "✗ Memory errors detected"
    grep "ERROR SUMMARY" valgrind.log
    exit 1
fi
```

### Arena Allocator Pattern
```zig
/// Use arena allocator for temporary allocations
pub fn solveWithArena(problem: *Problem, base_allocator: std.mem.Allocator) !Solution {
    var arena = std.heap.ArenaAllocator.init(base_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    // All allocations in this scope will be freed together
    var solver = SimplexSolver.initDefault();
    const status = try solver.solve(problem);
    
    // Get solution using arena
    const temp_solution = try problem.getSolution(allocator);
    
    // Copy to persistent solution using base allocator
    const solution = try Solution.copy(temp_solution, base_allocator);
    
    // Arena cleanup happens automatically
    return solution;
}
```

### RAII Patterns
```zig
/// Ensure cleanup with defer
pub const ScopedProblem = struct {
    problem: *Problem,
    
    pub fn init(allocator: std.mem.Allocator) !ScopedProblem {
        const problem = try Problem.init(allocator);
        return .{ .problem = problem };
    }
    
    pub fn deinit(self: *ScopedProblem) void {
        self.problem.deinit();
    }
    
    pub fn get(self: *ScopedProblem) *Problem {
        return self.problem;
    }
};

// Usage:
// var scoped = try ScopedProblem.init(allocator);
// defer scoped.deinit();
// var problem = scoped.get();
```

### Memory Benchmarks
```zig
test "Memory usage benchmarks" {
    const sizes = [_]usize{ 10, 100, 1000, 10000 };
    
    for (sizes) |size| {
        var tracker = memory.TrackingAllocator.init(testing.allocator);
        defer tracker.deinit();
        const allocator = tracker.allocator();
        
        {
            var problem = try glpk.Problem.init(allocator);
            defer problem.deinit();
            
            try problem.addRows(size);
            try problem.addColumns(size);
        }
        
        std.debug.print("Problem size {}x{}: peak memory = {} KB\n", 
                       .{ size, size, tracker.peak_usage / 1024 });
    }
}
```

## Implementation Notes
- Use tracking allocator in debug builds
- Run valgrind in CI pipeline
- Document memory ownership rules
- Use arena allocators for temporary data
- Implement RAII patterns where appropriate
- Monitor peak memory usage

## Testing Requirements
- No memory leaks in any test
- Valgrind reports no errors
- Peak memory usage is reasonable
- Memory is freed promptly
- Large problems don't exhaust memory

## Dependencies
- [#019](019_issue.md) - Problem management tests
- [#020](020_issue.md) - LP integration tests
- [#021](021_issue.md) - MIP integration tests

## Acceptance Criteria
- [ ] Tracking allocator implemented
- [ ] GLPK resource tracker created
- [ ] Memory leak tests written
- [ ] Valgrind integration working
- [ ] No leaks in all tests
- [ ] Arena allocator patterns documented
- [ ] RAII patterns implemented
- [ ] Memory benchmarks created
- [ ] CI includes memory checking
- [ ] Documentation explains memory model

## Status
🟡 Not Started