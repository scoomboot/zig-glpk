// build.zig — Build configuration for zig-glpk library
//
// repo   : https://github.com/scoomboot/zig-glpk
// docs   : https://scoomboot.github.io/zig-glpk/build
// author : https://github.com/scoomboot
//
// Vibe coded by Scoom.

// ╔══════════════════════════════════════ PACK ══════════════════════════════════════╗

    const std = @import("std");
    const Build = std.Build;
    const fs = std.fs;
    const builtin = @import("builtin");

// ╚════════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ INIT ══════════════════════════════════════╗

    // Platform-specific default paths for GLPK
    const linux_paths = [_][]const u8{
        "/usr/include",
        "/usr/local/include",
    };

    const macos_paths = [_][]const u8{
        "/opt/homebrew/include",  // ARM Macs (M1/M2)
        "/usr/local/include",      // Intel Macs via Homebrew
        "/usr/include",            // System headers
    };

    const windows_paths = [_][]const u8{
        "C:/msys64/mingw64/include",
        "C:/mingw64/include",
        "C:/glpk/include",
    };

    const linux_lib_paths = [_][]const u8{
        "/usr/lib",
        "/usr/lib/x86_64-linux-gnu",
        "/usr/local/lib",
    };

    const macos_lib_paths = [_][]const u8{
        "/opt/homebrew/lib",       // ARM Macs (M1/M2)
        "/usr/local/lib",          // Intel Macs via Homebrew
        "/usr/lib",                // System libraries
    };

    const windows_lib_paths = [_][]const u8{
        "C:/msys64/mingw64/lib",
        "C:/mingw64/lib",
        "C:/glpk/lib",
    };

// ╚════════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ CORE ══════════════════════════════════════╗

    pub fn build(b: *Build) void {
        // ┌──────────────────────────── TARGET & OPTIMIZATION ────────────────────────────┐
        
            const target = b.standardTargetOptions(.{});
            const optimize = b.standardOptimizeOption(.{});
        
        // └────────────────────────────────────────────────────────────────────────────────┘
        
        // ┌──────────────────────────── MODULE CONFIGURATION ─────────────────────────────┐
        
            const lib_mod = b.createModule(.{
                .root_source_file = b.path("lib/lib.zig"),
                .target = target,
                .optimize = optimize,
            });
            
            // Configure GLPK linkage with cross-platform support
            configureGlpkLinkage(b, lib_mod, target);
            lib_mod.link_libc = true;
        
        // └────────────────────────────────────────────────────────────────────────────────┘
        
        // ┌──────────────────────────── LIBRARY BUILD ────────────────────────────────────┐
        
            const lib = b.addStaticLibrary(.{
                .name = "zig-glpk",
                .root_module = lib_mod,
            });
            
            b.installArtifact(lib);
        
        // └────────────────────────────────────────────────────────────────────────────────┘
        
        // ┌──────────────────────────── TEST CONFIGURATION ───────────────────────────────┐
        
            const lib_tests = b.addTest(.{
                .root_module = lib_mod,
            });
            
            const run_lib_tests = b.addRunArtifact(lib_tests);
            
            const test_step = b.step("test", "Run unit tests");
            test_step.dependOn(&run_lib_tests.step);
        
        // └────────────────────────────────────────────────────────────────────────────────┘
    }

// ╚════════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ HELPERS ═══════════════════════════════════╗

    /// Configure GLPK linkage with cross-platform support
    fn configureGlpkLinkage(b: *Build, module: *std.Build.Module, target: std.Build.ResolvedTarget) void {
        // ┌──────────────────────────── ENVIRONMENT VARIABLES ────────────────────────────┐
        
            // Check for custom paths from environment
            const custom_include = std.process.getEnvVarOwned(b.allocator, "GLPK_INCLUDE_PATH") catch null;
            const custom_lib = std.process.getEnvVarOwned(b.allocator, "GLPK_LIB_PATH") catch null;
            const use_static = std.process.getEnvVarOwned(b.allocator, "GLPK_STATIC") catch null;
            
            // Determine if we should link statically
            const link_static = if (use_static) |val| std.mem.eql(u8, val, "1") or std.mem.eql(u8, val, "true") else false;
        
        // └────────────────────────────────────────────────────────────────────────────────┘
        
        // ┌──────────────────────────── ADD INCLUDE PATHS ────────────────────────────────┐
        
            var include_added = false;
            
            // First try custom include path
            if (custom_include) |path| {
                defer b.allocator.free(path);
                if (pathExists(path)) {
                    module.addIncludePath(.{ .cwd_relative = path });
                    include_added = true;
                } else {
                    std.log.warn("GLPK_INCLUDE_PATH '{s}' does not exist", .{path});
                }
            }
            
            // If no custom path or it failed, try platform defaults
            if (!include_added) {
                const paths = getPlatformIncludePaths(target);
                for (paths) |path| {
                    if (pathExists(path)) {
                        module.addIncludePath(.{ .cwd_relative = path });
                        include_added = true;
                        break;
                    }
                }
            }
            
            // Warn if no include path was found
            if (!include_added) {
                std.log.warn("No GLPK include path found. Build may fail.", .{});
                std.log.warn("Set GLPK_INCLUDE_PATH environment variable or install GLPK", .{});
            }
        
        // └────────────────────────────────────────────────────────────────────────────────┘
        
        // ┌──────────────────────────── ADD LIBRARY PATHS ────────────────────────────────┐
        
            var lib_added = false;
            
            // First try custom library path
            if (custom_lib) |path| {
                defer b.allocator.free(path);
                if (pathExists(path)) {
                    module.addLibraryPath(.{ .cwd_relative = path });
                    lib_added = true;
                } else {
                    std.log.warn("GLPK_LIB_PATH '{s}' does not exist", .{path});
                }
            }
            
            // If no custom path or it failed, try platform defaults
            if (!lib_added) {
                const paths = getPlatformLibPaths(target);
                for (paths) |path| {
                    if (pathExists(path)) {
                        module.addLibraryPath(.{ .cwd_relative = path });
                        lib_added = true;
                        break;
                    }
                }
            }
        
        // └────────────────────────────────────────────────────────────────────────────────┘
        
        // ┌──────────────────────────── LINK GLPK LIBRARY ────────────────────────────────┐
        
            if (link_static) {
                // Static linking - look for libglpk.a
                module.linkSystemLibrary("glpk", .{ .preferred_link_mode = .static });
            } else {
                // Dynamic linking - look for libglpk.so/dylib/dll
                module.linkSystemLibrary("glpk", .{ .preferred_link_mode = .dynamic });
            }
        
        // └────────────────────────────────────────────────────────────────────────────────┘
    }
    
    /// Get platform-specific include paths
    fn getPlatformIncludePaths(target: std.Build.ResolvedTarget) []const []const u8 {
        const os_tag = target.result.os.tag;
        
        return switch (os_tag) {
            .linux => &linux_paths,
            .macos => &macos_paths,
            .windows => &windows_paths,
            else => &linux_paths,  // Default to Linux paths for other Unix-like systems
        };
    }
    
    /// Get platform-specific library paths
    fn getPlatformLibPaths(target: std.Build.ResolvedTarget) []const []const u8 {
        const os_tag = target.result.os.tag;
        
        return switch (os_tag) {
            .linux => &linux_lib_paths,
            .macos => &macos_lib_paths,
            .windows => &windows_lib_paths,
            else => &linux_lib_paths,  // Default to Linux paths for other Unix-like systems
        };
    }
    
    /// Check if a path exists and is accessible
    fn pathExists(path: []const u8) bool {
        fs.accessAbsolute(path, .{}) catch return false;
        return true;
    }

// ╚════════════════════════════════════════════════════════════════════════════════════════╝