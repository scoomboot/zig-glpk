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
- [ ] GLPK development library installed on at least one platform
- [ ] `glpk.h` header file located and path documented
- [ ] GLPK library files located and path documented
- [ ] GLPK version verified to be 4.65 or later
- [ ] Simple C test program compiles and links successfully
- [ ] Installation documentation created in `docs/INSTALLATION.md`
- [ ] Platform-specific paths and requirements documented
- [ ] Verification script created and tested

## Status
🔴 Not Started