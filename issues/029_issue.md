# Issue #029: Restructure Module Directory to Comply with MCS Rules

## Priority
🔴 Critical

## References
- [Issue Index](000_index.md)
- [Session Review #004](SESSION_REVIEW_004.md)
- [MCS Documentation](../docs/MCS.md#11-directory-hierarchy)
- [Issue #006](006_issue.md) - Problem struct implementation

## Description
The current module directory structure violates Maysara Code Style (MCS) rules for module organization. Modules are incorrectly nested under `/lib/core/utils/` when they should be direct children of their parent module directory.

## Current Structure (Incorrect)
```
lib/
├── core/
│   ├── core.zig
│   └── utils/
│       ├── problem/
│       │   ├── problem.zig
│       │   └── problem.test.zig
│       ├── solver/
│       │   ├── solver.zig
│       │   └── solver.test.zig
│       └── types/
│           ├── types.zig
│           └── types.test.zig
```

## Required Structure (MCS Compliant)
```
lib/
├── core/
│   ├── core.zig
│   ├── problem/
│   │   ├── problem.zig
│   │   └── problem.test.zig
│   ├── solver/
│   │   ├── solver.zig
│   │   └── solver.test.zig
│   └── types/
│       ├── types.zig
│       └── types.test.zig
```

## MCS Rules Violated
From MCS.md §1.1-1.2:
- "Each logical component gets its own directory"
- "Utilities are grouped under a `utils` directory"
- "Complex utilities may have their own subdirectories and submodules"

The current structure treats core modules (problem, solver, types) as utilities when they are actually primary modules.

## Migration Tasks

### 1. Directory Restructuring
- [x] Move `/lib/core/utils/problem/` to `/lib/core/problem/`
- [x] Move `/lib/core/utils/solver/` to `/lib/core/solver/`
- [x] Move `/lib/core/utils/types/` to `/lib/core/types/`
- [x] Remove empty `/lib/core/utils/` directory

### 2. Import Path Updates
Update all import statements:
- [x] In problem.zig: Change `@import("../../../c/utils/glpk/glpk.zig")` to `@import("../../c/utils/glpk/glpk.zig")`
- [x] In problem.zig: Change `@import("../types/types.zig")` to `@import("../types/types.zig")`
- [x] In solver.zig: Update relative imports
- [x] In core.zig: Update module exports

### 3. Test Updates
- [x] Update import paths in all test files
- [x] Verify test discovery in build.zig still works

### 4. Build System Updates
- [x] Update module paths in build.zig if needed
- [x] Verify `zig build` succeeds
- [x] Verify `zig build test` runs all tests

### 5. Documentation Updates
- [x] Update any documentation referencing old paths
- [x] Update file headers with correct paths

## Impact Analysis

### Files Affected
- lib/core/core.zig (module exports)
- lib/core/utils/problem/problem.zig → lib/core/problem/problem.zig
- lib/core/utils/problem/problem.test.zig → lib/core/problem/problem.test.zig
- lib/core/utils/solver/solver.zig → lib/core/solver/solver.zig
- lib/core/utils/solver/solver.test.zig → lib/core/solver/solver.test.zig
- lib/core/utils/types/types.zig → lib/core/types/types.zig
- lib/core/utils/types/types.test.zig → lib/core/types/types.test.zig

### Backwards Compatibility
- This is a breaking change for any code importing these modules
- Since the project is in early development, impact should be minimal

## Testing Requirements
- [x] All existing tests must pass after migration
- [x] Build must succeed without errors
- [x] Verify imports work correctly from lib.zig
- [x] Test that module exports are accessible

## Dependencies
- None - This is a structural refactoring

## Acceptance Criteria
- [x] Directory structure matches MCS requirements
- [x] All imports updated and working
- [x] All tests passing
- [x] Build system functioning
- [x] No broken references in codebase
- [x] Documentation updated

## Status
✅ Resolved

## Resolution Summary

### Changes Implemented
Successfully restructured the module directory to comply with MCS rules. All modules have been moved from `/lib/core/utils/` to be direct children of `/lib/core/`.

### Directory Moves Completed
- ✅ Moved `/lib/core/utils/problem/` → `/lib/core/problem/`
- ✅ Moved `/lib/core/utils/solver/` → `/lib/core/solver/`
- ✅ Moved `/lib/core/utils/types/` → `/lib/core/types/`
- ✅ Removed empty `/lib/core/utils/` directory

### Import Updates
- ✅ Updated GLPK imports from `../../../c/utils/glpk/glpk.zig` to `../../c/utils/glpk/glpk.zig`
- ✅ Maintained correct relative imports between modules
- ✅ Updated all test file imports

### Core Module Updates
- ✅ Restructured `/lib/core/core.zig` to export modules directly instead of under `utils`
- ✅ Added proper MCS-style section headers and documentation
- ✅ Updated test imports to reference new locations

### Verification
- ✅ Build completes successfully (`zig build`)
- ✅ All 184 tests pass (`zig build test`)
- ✅ Module exports accessible as `glpk.core.problem`, `glpk.core.solver`, `glpk.core.types`
- ✅ Code follows MCS style with proper section headers and 4-space indentation

### Final Structure
```
lib/
├── core/
│   ├── core.zig
│   ├── problem/
│   │   ├── problem.zig
│   │   └── problem.test.zig
│   ├── solver/
│   │   ├── solver.zig
│   │   └── solver.test.zig
│   └── types/
│       ├── types.zig
│       └── types.test.zig
```

The codebase now fully complies with MCS directory hierarchy rules, treating problem, solver, and types as primary modules rather than utilities.

## Notes
This issue was identified during Session Review #004 after implementing Issue #006. Resolution completed successfully with all tests passing and full MCS compliance achieved.