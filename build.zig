// build.zig — Build configuration for zig-glpk library
//
// repo   : https://github.com/scoomboot/zig-glpk
// docs   : https://scoomboot.github.io/zig-glpk/build
// author : https://github.com/scoomboot
//
// Vibe coded by Scoom.

// ╔══════════════════════════════════════ PACK ══════════════════════════════════════════╗

const Build = @import("std").Build;

// ╚════════════════════════════════════════════════════════════════════════════════════════╝

// ╔══════════════════════════════════════ BUILD ═════════════════════════════════════════╗

pub fn build(b: *Build) void {
    const lib_mod = b.createModule(.{
        .root_source_file = b.path("lib/lib.zig"),
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "lib",
        .root_module = lib_mod,
    });

    b.installArtifact(lib);

    const lib_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const run_lib_tests = b.addRunArtifact(lib_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_tests.step);
}

// ╚════════════════════════════════════════════════════════════════════════════════════════╝
