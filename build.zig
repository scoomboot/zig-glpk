// build.zig — Build configuration for zig-glpk library
//
// repo   : https://github.com/scoomboot/zig-glpk
// docs   : https://scoomboot.github.io/zig-glpk/build
// author : https://github.com/scoomboot
//
// Vibe coded by Scoom.

// ╔══════════════════════════════════════ PACK ══════════════════════════════════════╗

    const Build = @import("std").Build;

// ╚════════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ CORE ══════════════════════════════════════╗

    pub fn build(b: *Build) void {
        // ┌──────────────────────────── TARGET & OPTIMIZATION ────────────────────────────┐
        
            const target = b.standardTargetOptions(.{});
            const optimize = b.standardOptimizeOption(.{});
        
        // └──────────────────────────────────────────────────────────────────────────────┘
        
        // ┌──────────────────────────── MODULE CONFIGURATION ─────────────────────────────┐
        
            const lib_mod = b.createModule(.{
                .root_source_file = b.path("lib/lib.zig"),
                .target = target,
                .optimize = optimize,
            });
            
            // Configure GLPK linkage for the module
            lib_mod.linkSystemLibrary("glpk", .{});
            lib_mod.addIncludePath(.{ .cwd_relative = "/usr/include" });
            lib_mod.link_libc = true;
        
        // └──────────────────────────────────────────────────────────────────────────────┘
        
        // ┌──────────────────────────── LIBRARY BUILD ────────────────────────────────────┐
        
            const lib = b.addStaticLibrary(.{
                .name = "zig-glpk",
                .root_module = lib_mod,
            });
            
            b.installArtifact(lib);
        
        // └──────────────────────────────────────────────────────────────────────────────┘
        
        // ┌──────────────────────────── TEST CONFIGURATION ───────────────────────────────┐
        
            const lib_tests = b.addTest(.{
                .root_module = lib_mod,
            });
            
            const run_lib_tests = b.addRunArtifact(lib_tests);
            
            const test_step = b.step("test", "Run unit tests");
            test_step.dependOn(&run_lib_tests.step);
        
        // └──────────────────────────────────────────────────────────────────────────────┘
    }

// ╚════════════════════════════════════════════════════════════════════════════════════════╝