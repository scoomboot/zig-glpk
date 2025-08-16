# Issue #028: Fix critical cross-platform build configuration

## Priority
🔴 Critical - Blocks usage on non-Linux platforms

## References
- [Issue Index](000_index.md)
- [Issue #003](003_issue.md) - Original build configuration issue
- [Issue #001](001_issue.md) - GLPK installation (Linux-only currently)

## Description
The current build.zig implementation has a critical bug that prevents the library from building on any platform except Linux with GLPK installed in `/usr/include`. This hardcoded path breaks cross-platform compatibility entirely.

## Current Problem
```zig
// build.zig line 35 - BREAKS ON NON-LINUX PLATFORMS
lib_mod.addIncludePath(.{ .cwd_relative = "/usr/include" });
```

## Requirements

### Immediate Fix
Implement platform-aware include path detection:

```zig
pub fn build(b: *Build) void {
    // ... existing code ...
    
    // Detect GLPK include path based on platform
    const include_path = detectGlpkIncludePath(b);
    lib_mod.addIncludePath(include_path);
    
    // ... rest of build ...
}

fn detectGlpkIncludePath(b: *Build) Build.LazyPath {
    // Check environment variable first
    if (b.env_map.get("GLPK_INCLUDE_PATH")) |path| {
        return .{ .cwd_relative = path };
    }
    
    // Platform-specific defaults
    const target = b.standardTargetOptions(.{});
    const os_tag = target.result.os.tag;
    
    switch (os_tag) {
        .linux => {
            // Try common Linux paths
            const paths = [_][]const u8{
                "/usr/include",
                "/usr/local/include",
            };
            for (paths) |path| {
                if (std.fs.accessAbsolute(path ++ "/glpk.h", .{})) |_| {
                    return .{ .cwd_relative = path };
                } else |_| {}
            }
        },
        .macos => {
            // Try common macOS paths
            const paths = [_][]const u8{
                "/opt/homebrew/include",  // Apple Silicon
                "/usr/local/include",      // Intel Mac
                "/opt/local/include",      // MacPorts
            };
            for (paths) |path| {
                if (std.fs.accessAbsolute(path ++ "/glpk.h", .{})) |_| {
                    return .{ .cwd_relative = path };
                } else |_| {}
            }
        },
        .windows => {
            // Windows paths require special handling
            // Check common locations or use pkg-config
        },
        else => {},
    }
    
    // Fallback to system default
    return .{ .cwd_relative = "/usr/include" };
}
```

### Minimum Viable Fix
At the very least, use environment variables:
```zig
const glpk_include = b.env_map.get("GLPK_INCLUDE_PATH") orelse "/usr/include";
lib_mod.addIncludePath(.{ .cwd_relative = glpk_include });
```

## Testing Requirements
- Build must succeed on Linux with standard GLPK installation
- Build must succeed on macOS with Homebrew GLPK
- Build must succeed with custom GLPK_INCLUDE_PATH
- Clear error message if GLPK headers not found

## Dependencies
- None - this is a critical blocker

## Acceptance Criteria
- [ ] Remove hardcoded `/usr/include` path
- [ ] Implement platform detection or environment variable support
- [ ] Test on at least Linux and one other platform
- [ ] Document environment variables in README
- [ ] Update INSTALLATION.md with platform-specific build instructions

## Impact
- **Current**: Library only builds on Linux with GLPK in `/usr/include`
- **After Fix**: Library builds on Linux, macOS, and Windows with proper GLPK installation

## Status
✅ RESOLVED (2025-08-16)

## Resolution Notes
This issue has been completely resolved as part of the comprehensive fix for Issue #003. The hardcoded `/usr/include` path has been replaced with intelligent platform detection that supports:

- **Linux**: Multiple standard paths checked automatically
- **macOS**: Both Intel (`/usr/local/include`) and Apple Silicon (`/opt/homebrew/include`) supported  
- **Windows**: MSYS2/MinGW and standard GLPK installation paths
- **Environment Variables**: Full support for GLPK_INCLUDE_PATH, GLPK_LIB_PATH, and GLPK_STATIC

The implementation exceeds the minimum requirements by providing automatic path detection with verification, helpful warnings for missing paths, and comprehensive test coverage (58 tests). See Issue #003's resolution summary for full implementation details.