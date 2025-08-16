# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Build
```bash
zig build
```

### Run Tests
```bash
zig build test
```

### Verify GLPK Installation
```bash
./scripts/verify-glpk.sh
```

## Architecture

This is a Zig wrapper library for GLPK (GNU Linear Programming Kit). The codebase follows the Maysara Code Style (MCS) with a specific structure:

### Module Organization
- **lib/lib.zig**: Main library entry point that exports `core` and `c` modules
- **lib/c/**: C bindings layer containing direct GLPK API wrappers
  - **glpk.zig**: Low-level GLPK C bindings with constants and function wrappers
- **lib/core/**: High-level Zig-native API layer
  - **problem/**: Problem definition and management
  - **solver/**: Solver interfaces and implementations  
  - **types/**: Type definitions and conversions

### Code Style Requirements (MCS)
The project strictly follows Maysara Code Style defined in `docs/MCS.md`:
- Files use decorative section headers: `╔══════ SECTION ══════╗`
- Code within sections is indented by 4 spaces
- Test naming follows pattern: `test "<category>: <component>: <description>"`
- Categories: `unit`, `integration`, `e2e`, `performance`, `stress`

### Testing Conventions
- Unit tests are inline in implementation files
- Integration/stress tests are in separate `.test.zig` files
- All tests must follow naming conventions in `docs/TESTING_CONVENTIONS.md`
- Use `std.testing.allocator` for memory allocation in tests

### Dependencies
- Requires GLPK library installed on system (`apt install libglpk-dev` or equivalent)
- Links to system GLPK via `linkSystemLibrary("glpk")`
- Minimum Zig version: 0.14.1