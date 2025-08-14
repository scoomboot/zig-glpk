# Issue #001: Install and verify GLPK system dependencies

## Priority
🔴 Critical

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#phase-1-setup--foundation)
- [GLPK Official Documentation](https://www.gnu.org/software/glpk/)

## Description
Install the GNU Linear Programming Kit (GLPK) development library on the target system and verify that all necessary components are available for building the Zig wrapper. This is the foundational step that ensures we have the C library available to link against.

## Requirements

### System Package Installation
- **Fedora**: Install via `sudo dnf install glpk-devel`
- **macOS**: Install via `brew install glpk`
- **Windows**: Download pre-built binaries from the GLPK website or build from source
- **Arch Linux**: Install via `pacman -S glpk`
- **Fedora/RHEL**: Install via `dnf install glpk-devel`

### Verification Steps
1. Locate the GLPK header file:
   - Find `glpk.h` (typically in `/usr/include` or `/usr/local/include`)
   - Document the exact path for build configuration

2. Locate the GLPK library files:
   - Find `libglpk.so` (Linux), `libglpk.dylib` (macOS), or `glpk.lib` (Windows)
   - Document the library path (typically `/usr/lib` or `/usr/local/lib`)

3. Verify version compatibility:
   - Check GLPK version with `glpsol --version`
   - Ensure version is 4.65 or later
   - Document the installed version

4. Test basic functionality:
   - Create a simple C test program that includes `glpk.h`
   - Compile and link against GLPK
   - Verify it runs without errors

### Documentation Requirements
- Create `docs/INSTALLATION.md` with:
  - Platform-specific installation instructions
  - Troubleshooting common installation issues
  - Version compatibility notes
  - Header and library paths for each platform

## Implementation Notes
- Different platforms may have different package names and paths
- Some systems may require setting `LD_LIBRARY_PATH` or `DYLD_LIBRARY_PATH`
- Windows users may need to build from source or use pre-built binaries
- Consider documenting how to build GLPK from source as a fallback

## Testing Requirements
- Create a simple verification script that:
  - Checks for the presence of `glpk.h`
  - Checks for the presence of the GLPK library
  - Reports the GLPK version
  - Attempts to compile a minimal test program

## Dependencies
None - this is the foundational issue

## Acceptance Criteria
- [x] GLPK development library installed on at least one platform
- [x] `glpk.h` header file located and path documented
- [x] GLPK library files located and path documented
- [x] GLPK version verified to be 4.65 or later
- [x] Simple C test program compiles and links successfully
- [x] Installation documentation created in `docs/INSTALLATION.md`
- [x] Platform-specific paths and requirements documented
- [x] Verification script created and tested

## Status
🟢 Resolved

## Resolution Summary

### Completed Implementation
Successfully installed and configured GLPK 5.0 on Fedora 42 with complete integration into the zig-glpk wrapper project.

### Key Deliverables
1. **Verification Script** (`scripts/verify-glpk.sh`)
   - Comprehensive checks for header, library, version, and compilation
   - Multi-compiler support (gcc, clang, zig cc)
   - Clear status reporting

2. **Build Configuration** (`build.zig`)
   - Linked GLPK library and libc
   - Added include paths for headers
   - MCS-compliant code organization

3. **GLPK C Bindings** (`lib/c/utils/glpk/glpk.zig`)
   - Complete C API imports
   - All essential constants exported
   - Core function wrappers
   - Version utility functions

4. **Test Suite** (`lib/c/utils/glpk/glpk.test.zig`)
   - 11 comprehensive test categories
   - Library linkage verification
   - Integration tests with LP solving
   - Memory management validation

5. **Documentation** (`docs/INSTALLATION.md`)
   - Platform-specific instructions for all major OS
   - Troubleshooting guide
   - Version compatibility matrix
   - Build from source instructions

### Verified Configuration (Fedora 42)
- **GLPK Version**: 5.0-13
- **Header Path**: `/usr/include/glpk.h`
- **Library Path**: `/usr/lib64/libglpk.so`
- **Build Command**: `zig build`
- **Test Command**: `zig build test`

### Testing Results
- All unit tests passing
- Library successfully builds as `libzig-glpk.a`
- Verification script confirms full functionality
- LP problem solving tested and working

### Next Steps
With GLPK successfully installed and verified, the project is ready to proceed with implementing higher-level Zig wrappers as outlined in subsequent issues.

### Cross-Platform Note
**Important**: While this issue is resolved for Linux (Fedora 42), cross-platform build support is tracked separately in [Issue #028](028_issue.md). The current build.zig has a hardcoded include path that only works on Linux. Users on macOS or Windows should refer to issue #028 for the necessary build fixes.