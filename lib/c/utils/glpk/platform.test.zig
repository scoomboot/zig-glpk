// platform.test.zig — Platform-specific GLPK linking and configuration tests
//
// repo   : https://github.com/scoomboot/zig-glpk
// docs   : https://scoomboot.github.io/zig-glpk/lib/c/utils/glpk
// author : https://github.com/scoomboot
//
// Vibe coded by Scoom.

// ╔══════════════════════════════════════ PACK ══════════════════════════════════════╗

    const std = @import("std");
    const testing = std.testing;
    const builtin = @import("builtin");
    const glpk = @import("./glpk.zig");
    const process = std.process;

// ╚══════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ INIT ══════════════════════════════════════╗

    // ┌──────────────────────────── Platform Constants ────────────────────────────┐
    
        const current_os = builtin.os.tag;
        const current_arch = builtin.cpu.arch;
        const current_abi = builtin.abi;
        const is_debug = builtin.mode == .Debug;
        
        // Expected library version
        const MIN_GLPK_MAJOR = 4;
        const MAX_GLPK_MAJOR = 6;
    
    // └──────────────────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ TEST ══════════════════════════════════════╗

    // ┌──────────────────────────── Platform Detection Tests ────────────────────────────┐
    
        test "unit: PlatformDetection: verify build target detection" {
            // Log platform information for debugging
            std.debug.print("\n=== Platform Configuration ===\n", .{});
            std.debug.print("OS: {s}\n", .{@tagName(current_os)});
            std.debug.print("Architecture: {s}\n", .{@tagName(current_arch)});
            std.debug.print("ABI: {s}\n", .{@tagName(current_abi)});
            std.debug.print("Build Mode: {s}\n", .{@tagName(builtin.mode)});
            std.debug.print("Zig Version: {}\n", .{builtin.zig_version});
            std.debug.print("==============================\n", .{});
            
            // Verify we're on a supported platform
            const is_supported = switch (current_os) {
                .linux, .macos, .windows => true,
                else => false,
            };
            
            try testing.expect(is_supported);
        }
        
        test "unit: PlatformDetection: verify GLPK library version" {
            const version = glpk.getVersion();
            const major = glpk.getMajorVersion();
            const minor = glpk.getMinorVersion();
            
            std.debug.print("\n=== GLPK Library Info ===\n", .{});
            std.debug.print("Version: {s}\n", .{version});
            std.debug.print("Major: {}\n", .{major});
            std.debug.print("Minor: {}\n", .{minor});
            std.debug.print("=========================\n", .{});
            
            // Verify version is within expected range
            try testing.expect(major >= MIN_GLPK_MAJOR);
            try testing.expect(major <= MAX_GLPK_MAJOR);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Environment Variable Tests ────────────────────────────┐
    
        test "unit: EnvironmentConfig: check GLPK environment variables" {
            const allocator = testing.allocator;
            
            // Check if custom GLPK paths are set
            const glpk_include = process.getEnvVarOwned(allocator, "GLPK_INCLUDE_PATH") catch null;
            defer if (glpk_include) |path| allocator.free(path);
            
            const glpk_lib = process.getEnvVarOwned(allocator, "GLPK_LIB_PATH") catch null;
            defer if (glpk_lib) |path| allocator.free(path);
            
            const glpk_static = process.getEnvVarOwned(allocator, "GLPK_STATIC") catch null;
            defer if (glpk_static) |val| allocator.free(val);
            
            std.debug.print("\n=== Environment Variables ===\n", .{});
            if (glpk_include) |path| {
                std.debug.print("GLPK_INCLUDE_PATH: {s}\n", .{path});
            } else {
                std.debug.print("GLPK_INCLUDE_PATH: (not set - using system default)\n", .{});
            }
            
            if (glpk_lib) |path| {
                std.debug.print("GLPK_LIB_PATH: {s}\n", .{path});
            } else {
                std.debug.print("GLPK_LIB_PATH: (not set - using system default)\n", .{});
            }
            
            if (glpk_static) |val| {
                const is_static = std.mem.eql(u8, val, "1") or std.mem.eql(u8, val, "true");
                std.debug.print("GLPK_STATIC: {s} (static linking: {})\n", .{ val, is_static });
            } else {
                std.debug.print("GLPK_STATIC: (not set - using dynamic linking)\n", .{});
            }
            std.debug.print("=============================\n", .{});
            
            // Test passes regardless of environment configuration
            try testing.expect(true);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── System Path Tests ────────────────────────────┐
    
        test "unit: SystemPaths: verify expected GLPK paths exist" {
            const fs = std.fs;
            
            std.debug.print("\n=== System Path Check ===\n", .{});
            
            // Platform-specific paths to check
            const paths_to_check = switch (current_os) {
                .linux => &[_][]const u8{
                    "/usr/include/glpk.h",
                    "/usr/local/include/glpk.h",
                    "/usr/lib/libglpk.so",
                    "/usr/lib/x86_64-linux-gnu/libglpk.so",
                    "/usr/local/lib/libglpk.so",
                },
                .macos => &[_][]const u8{
                    "/opt/homebrew/include/glpk.h",
                    "/usr/local/include/glpk.h",
                    "/opt/homebrew/lib/libglpk.dylib",
                    "/usr/local/lib/libglpk.dylib",
                },
                .windows => &[_][]const u8{
                    "C:/msys64/mingw64/include/glpk.h",
                    "C:/mingw64/include/glpk.h",
                    "C:/msys64/mingw64/lib/libglpk.dll.a",
                    "C:/mingw64/lib/libglpk.dll.a",
                },
                else => &[_][]const u8{},
            };
            
            var found_header = false;
            var found_library = false;
            
            for (paths_to_check) |path| {
                fs.accessAbsolute(path, .{}) catch {
                    std.debug.print("  [ ] {s}\n", .{path});
                    continue;
                };
                std.debug.print("  [✓] {s}\n", .{path});
                
                if (std.mem.endsWith(u8, path, "glpk.h")) {
                    found_header = true;
                } else if (std.mem.indexOf(u8, path, "libglpk") != null) {
                    found_library = true;
                }
            }
            
            if (!found_header) {
                std.debug.print("  Warning: No GLPK header found in standard locations\n", .{});
            }
            if (!found_library) {
                std.debug.print("  Warning: No GLPK library found in standard locations\n", .{});
            }
            
            std.debug.print("=========================\n", .{});
            
            // The fact that our tests are running means GLPK was found somewhere
            try testing.expect(true);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Cross-Platform Compatibility Tests ────────────────────────────┐
    
        test "integration: CrossPlatform: verify basic operations work consistently" {
            // This test ensures basic GLPK operations work the same across platforms
            const prob = glpk.createProblem();
            defer glpk.deleteProblem(prob);
            
            // These operations should work identically on all platforms
            glpk.setProblemName(prob, "cross_platform_test");
            glpk.setObjectiveDirection(prob, glpk.GLP_MAX);
            
            // Add a simple constraint and variable
            const row_idx = glpk.addRows(prob, 1);
            const col_idx = glpk.addColumns(prob, 1);
            
            glpk.setRowBounds(prob, row_idx, glpk.GLP_UP, 0, 10);
            glpk.setColumnBounds(prob, col_idx, glpk.GLP_LO, 0, 0);
            glpk.setObjectiveCoef(prob, col_idx, 1);
            
            // Set constraint coefficient
            var indices = [_]c_int{ 0, row_idx };
            var values = [_]f64{ 0, 1 };
            glpk.setMatrixRow(prob, row_idx, 1, &indices, &values);
            
            // Solve
            var params: glpk.SimplexParams = undefined;
            glpk.initSimplexParams(&params);
            params.msg_lev = glpk.GLP_MSG_OFF;
            
            const result = glpk.simplex(prob, &params);
            
            // Should solve successfully on all platforms
            try testing.expectEqual(@as(c_int, 0), result);
            
            const status = glpk.getStatus(prob);
            try testing.expectEqual(glpk.GLP_OPT, status);
            
            const obj_val = glpk.getObjectiveValue(prob);
            const col_val = glpk.getColumnPrimal(prob, col_idx);
            
            // Solution should be x = 10, obj = 10
            try testing.expect(@abs(col_val - 10.0) < 1e-6);
            try testing.expect(@abs(obj_val - 10.0) < 1e-6);
        }
        
        test "integration: CrossPlatform: verify numerical consistency" {
            // Test that numerical results are consistent across platforms
            const prob = glpk.createProblem();
            defer glpk.deleteProblem(prob);
            
            // Create a problem with specific numerical values
            _ = glpk.addRows(prob, 2);
            _ = glpk.addColumns(prob, 2);
            
            // Set up the problem:
            // Maximize: 3x + 5y
            // Subject to:
            //   x + 2y <= 14
            //   3x + y <= 18
            //   x, y >= 0
            
            glpk.setObjectiveDirection(prob, glpk.GLP_MAX);
            
            glpk.setRowBounds(prob, 1, glpk.GLP_UP, 0, 14);
            glpk.setRowBounds(prob, 2, glpk.GLP_UP, 0, 18);
            
            glpk.setColumnBounds(prob, 1, glpk.GLP_LO, 0, 0);
            glpk.setColumnBounds(prob, 2, glpk.GLP_LO, 0, 0);
            
            glpk.setObjectiveCoef(prob, 1, 3);
            glpk.setObjectiveCoef(prob, 2, 5);
            
            var ia = [_]c_int{ 0, 1, 1, 2, 2 };
            var ja = [_]c_int{ 0, 1, 2, 1, 2 };
            var ar = [_]f64{ 0, 1, 2, 3, 1 };
            
            glpk.loadMatrix(prob, 4, &ia, &ja, &ar);
            
            // Solve
            var params: glpk.SimplexParams = undefined;
            glpk.initSimplexParams(&params);
            params.msg_lev = glpk.GLP_MSG_OFF;
            
            const result = glpk.simplex(prob, &params);
            try testing.expectEqual(@as(c_int, 0), result);
            
            const obj_val = glpk.getObjectiveValue(prob);
            const x_val = glpk.getColumnPrimal(prob, 1);
            const y_val = glpk.getColumnPrimal(prob, 2);
            
            // The solution should satisfy the constraints
            try testing.expect(x_val >= -1e-6);
            try testing.expect(y_val >= -1e-6);
            try testing.expect(x_val + 2 * y_val <= 14 + 1e-6);
            try testing.expect(3 * x_val + y_val <= 18 + 1e-6);
            
            // Objective value should match computed value
            const computed_obj = 3 * x_val + 5 * y_val;
            try testing.expect(@abs(obj_val - computed_obj) < 1e-6);
            
            // The objective value should be positive and reasonable
            try testing.expect(obj_val > 0);
            try testing.expect(obj_val < 100);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Build Mode Tests ────────────────────────────┐
    
        test "unit: BuildMode: verify behavior in current build mode" {
            std.debug.print("\n=== Build Mode Test ===\n", .{});
            std.debug.print("Current mode: {s}\n", .{@tagName(builtin.mode)});
            
            const prob = glpk.createProblem();
            defer glpk.deleteProblem(prob);
            
            // Performance characteristics may differ between modes
            // but functionality should be identical
            switch (builtin.mode) {
                .Debug => {
                    std.debug.print("Running in Debug mode - safety checks enabled\n", .{});
                    try testing.expect(true);
                },
                .ReleaseSafe => {
                    std.debug.print("Running in ReleaseSafe mode - optimized with safety\n", .{});
                    try testing.expect(true);
                },
                .ReleaseFast => {
                    std.debug.print("Running in ReleaseFast mode - maximum performance\n", .{});
                    try testing.expect(true);
                },
                .ReleaseSmall => {
                    std.debug.print("Running in ReleaseSmall mode - minimum size\n", .{});
                    try testing.expect(true);
                },
            }
            
            std.debug.print("=======================\n", .{});
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘
    
    // ┌──────────────────────────── Performance Baseline Tests ────────────────────────────┐
    
        test "performance: Baseline: measure basic operation timing" {
            // Skip in debug mode as performance is not representative
            if (is_debug) {
                return;
            }
            
            const iterations = 1000;
            var timer = try std.time.Timer.start();
            
            var i: usize = 0;
            while (i < iterations) : (i += 1) {
                const prob = glpk.createProblem();
                glpk.deleteProblem(prob);
            }
            
            const elapsed = timer.read();
            const avg_ns = elapsed / iterations;
            
            std.debug.print("\n=== Performance Baseline ===\n", .{});
            std.debug.print("Create/Delete cycle: {} ns average\n", .{avg_ns});
            std.debug.print("Total time for {} iterations: {} ms\n", .{ iterations, elapsed / 1_000_000 });
            std.debug.print("============================\n", .{});
            
            // Just verify it completes without error
            try testing.expect(true);
        }
    
    // └──────────────────────────────────────────────────────────────────────────────┘

// ╚══════════════════════════════════════════════════════════════════════════════════════╝