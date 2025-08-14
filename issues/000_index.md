# Zig Lexer Library - Issue Index

## Active Issues

### Phase 1: Core Infrastructure (Week 1-2)
- ✅ [#001](001_issue.md): Set up project structure following MCS guidelines
- ✅ [#002](002_issue.md): Implement core token types and interfaces → [#001](001_issue.md)
- ✅ [#003](003_issue.md): Build basic character stream handling → [#001](001_issue.md), [#002](002_issue.md)
- ✅ [#004](004_issue.md): Add source position tracking → [#002](002_issue.md), [#003](003_issue.md)
- ✅ [#005](005_issue.md): Create error handling framework → [#002](002_issue.md), [#004](004_issue.md)
- ✅ [#006](006_issue.md): Write unit tests for core components → [#001](001_issue.md), [#002](002_issue.md), [#003](003_issue.md), [#004](004_issue.md), [#005](005_issue.md)

### Phase 2: JSON Lexer (Week 3-4)
**📚 See [PHASE2_IMPLEMENTATION_GUIDE.md](../docs/PHASE2_IMPLEMENTATION_GUIDE.md) for essential context before starting**
- ✅ [#007](007_issue.md): Implement JSON token types → [#001](001_issue.md), [#002](002_issue.md), [#003](003_issue.md)
- 🟡 [#008](008_issue.md): Add string escape sequence handling → [#003](003_issue.md), [#005](005_issue.md), [#007](007_issue.md)
- 🟡 [#009](009_issue.md): Implement number parsing → [#003](003_issue.md), [#005](005_issue.md), [#007](007_issue.md)
- 🟡 [#010](010_issue.md): Add comprehensive error messages → [#005](005_issue.md), [#007](007_issue.md), [#008](008_issue.md), [#009](009_issue.md)
- 🟡 [#011](011_issue.md): Create JSON-specific test suite → [#006](006_issue.md), [#007](007_issue.md), [#008](008_issue.md), [#009](009_issue.md), [#010](010_issue.md)
- 🟡 [#012](012_issue.md): Benchmark against existing JSON parsers → [#007](007_issue.md), [#008](008_issue.md), [#009](009_issue.md), [#011](011_issue.md)

### Phase 3: Parser Integration (Week 5-6)
- 🟡 [#013](013_issue.md): Build JSON parser using the lexer → [#007](007_issue.md), [#008](008_issue.md), [#009](009_issue.md), [#011](011_issue.md)
- 🟡 [#014](014_issue.md): Implement lookahead and backtracking → [#002](002_issue.md), [#003](003_issue.md), [#004](004_issue.md)
- 🟡 [#015](015_issue.md): Add parser error recovery → [#005](005_issue.md), [#013](013_issue.md), [#014](014_issue.md)
- 🟡 [#016](016_issue.md): Create end-to-end tests → [#011](011_issue.md), [#013](013_issue.md), [#015](015_issue.md)
- 🟡 [#017](017_issue.md): Write documentation and examples → [#013](013_issue.md), [#016](016_issue.md)
- 🟡 [#018](018_issue.md): Performance optimization based on profiling → [#012](012_issue.md), [#013](013_issue.md), [#016](016_issue.md)

### Success Metrics & Quality Gates
- 🟢 [#019](019_issue.md): Complete JSON lexer with 100% spec compliance → [#007](007_issue.md), [#008](008_issue.md), [#009](009_issue.md), [#011](011_issue.md)
- 🟢 [#020](020_issue.md): Performance within 2x of fastest Zig JSON parser → [#012](012_issue.md), [#018](018_issue.md)
- 🟢 [#021](021_issue.md): Zero memory leaks in all test scenarios → [#005](005_issue.md), [#006](006_issue.md), [#016](016_issue.md)
- 🟢 [#022](022_issue.md): Documentation for all public APIs → [#017](017_issue.md)
- 🟢 [#023](023_issue.md): Example programs demonstrating usage → [#013](013_issue.md), [#017](017_issue.md)
- 🟢 [#024](024_issue.md): Published to Zig package registry → [#022](022_issue.md), [#023](023_issue.md)
- 🟢 [#025](025_issue.md): Test coverage > 90% → [#006](006_issue.md), [#011](011_issue.md), [#016](016_issue.md)
- 🟢 [#026](026_issue.md): Benchmark suite with regression detection → [#012](012_issue.md), [#018](018_issue.md)
- 🟢 [#027](027_issue.md): Fuzz testing for 24 hours without crashes → [#011](011_issue.md), [#021](021_issue.md)
- 🟢 [#028](028_issue.md): Clean compilation with all Zig safety checks → [#021](021_issue.md)

### Critical Implementation Issues (Discovered during Issue #001)
- ✅ [#029](029_issue.md): Fix memory management and cleanup patterns → [#001](001_issue.md)
- ✅ [#030](030_issue.md): Resolve module import path problems → [#001](001_issue.md)
- ✅ [#031](031_issue.md): Fix test implementation compilation errors → [#001](001_issue.md), [#029](029_issue.md), [#030](030_issue.md)
- ✅ [#032](032_issue.md): Implement consistent resource cleanup patterns → [#029](029_issue.md), [#030](030_issue.md), [#031](031_issue.md)
- ✅ [#033](033_issue.md): Establish cross-module dependency architecture → [#030](030_issue.md)

### Code Quality & Cleanup Issues (Discovered during Issue #002)
- ✅ [#034](034_issue.md): Remove unnecessary files created during implementation
- 🟡 [#049](049_issue.md): Clean up debug output in test files - Partially complete

### Critical Test Discovery Bug (Discovered during Issue #035 investigation)
- ✅ [#035](035_issue.md): Fix critical test discovery - 64 tests were not running! (escalated from cleanup to critical)

### Compatibility Issues (Discovered during Issue #003 implementation)
- ✅ [#036](036_issue.md): Fix Zig builtin compatibility issues - deprecated builtins preventing test compilation

### Functional Bugs (Discovered during Session 7 testing)
- ✅ [#037](037_issue.md): Fix StreamingBuffer implementation bugs - EOF detection and position tracking issues

### Position Tracking Enhancements (Discovered during Issue #004 session review)
- ✅ [#038](038_issue.md): Add Position Tracking to StreamingBuffer → [#004](004_issue.md), [#037](037_issue.md)
- ✅ [#039](039_issue.md): Add Performance Benchmarks for Position Tracking → [#004](004_issue.md)
- 🟢 [#040](040_issue.md): Implement Line Offset Table for Large Files → [#004](004_issue.md), [#038](038_issue.md)

### StreamingBuffer Enhancements (Discovered during Issue #038 implementation)
- ✅ [#041](041_issue.md): StreamingBuffer Mark/Restore Limited to Current Window → [#038](038_issue.md)

### Performance Critical Issues (Discovered during Issue #039 benchmark implementation)
- ✅ [#042](042_issue.md): Optimize advanceUtf8Bytes() Performance → [#039](039_issue.md), [#004](004_issue.md)

### UTF-8 Position Tracking Correctness Issues (Discovered during Issue #042 technical review)
- ✅ [#043](043_issue.md): Fix UTF-8 Validation Table Bug → [#042](042_issue.md)
- ✅ [#044](044_issue.md): Add Unicode Codepoint Validation → [#042](042_issue.md), [#043](043_issue.md)
- ✅ [#045](045_issue.md): Add Integer Overflow Protection for Position Tracking → [#042](042_issue.md)
- ✅ [#046](046_issue.md): Fix MCS Compliance for UTF-8 Optimization Code → [#042](042_issue.md)
- ✅ [#047](047_issue.md): Remove Redundant ASCII Scanning in advanceUtf8Bytes → [#042](042_issue.md)

### Test Infrastructure Issues (Discovered during Issue #043 implementation)
- ✅ [#048](048_issue.md): Investigate Standalone Test Execution Error → [#035](035_issue.md)
- ✅ [#050](050_issue.md): Add Test Execution Logging to Verify All Tests Run → [#035](035_issue.md), [#048](048_issue.md)

### Error Framework Integration Issues (Discovered during Issue #005 implementation)
- ✅ [#051](051_issue.md): Export new error handling modules in public API → [#005](005_issue.md)
- ✅ [#052](052_issue.md): Integrate error handling framework with main Lexer implementation → [#005](005_issue.md), [#051](051_issue.md)

### Test Design Issues (Discovered during Issue #007 JSON implementation)
- ✅ [#054](054_issue.md): Fix Test Design Assumptions in Error Recovery Tests → [#007](007_issue.md), [#053](053_issue.md)

### Test Infrastructure Quality Issues (Discovered during Issue #054 resolution)
- ✅ [#055](055_issue.md): Audit and Fix Test Infrastructure Design Flaws → [#054](054_issue.md)
- ✅ [#056](056_issue.md): Create Standardized Error Pattern Library for Test Infrastructure → [#054](054_issue.md), [#055](055_issue.md)
- ✅ [#057](057_issue.md): Enhance Test Review Process for Error Recovery Validation → [#054](054_issue.md), [#055](055_issue.md), [#056](056_issue.md)

---

## Priority Legend
- 🔴 **Critical**: Core functionality required for basic operation (Issue #006)
- 🟡 **Medium**: Important features for full functionality (Issues #007-#018, #049)
- 🟢 **Low**: Quality metrics and polish (Issues #019-#028, #040)

## Status Legend
- 🔴/🟡/🟢 **Not Started**: Issue not yet begun (color indicates priority)
- 🚧 **In Progress**: Currently being worked on
- ✅ **Completed**: Issue fully resolved

## Dependencies
Issues with arrows (→) indicate dependencies. Complete prerequisite issues first.

## Implementation Order

### Suggested Sequence
1. **Phase 1** (Critical): Complete issues #002-#006 to establish foundation (blockers ~~#029~~, ~~#030~~, ~~#031~~ resolved)
2. **Code Cleanup** (Medium): Address #034-#035 for clean project structure
3. **Phase 2** (Medium): Complete issues #007-#012 to implement JSON lexer
4. **Phase 3** (Medium): Complete issues #013-#018 for parser integration
5. **Quality Gates** (Low): Complete issues #019-#028 for production readiness

### Parallel Work Opportunities
Once Phase 1 is complete:
- Issues #014 (lookahead) can be worked in parallel with Phase 2
- Documentation (#017) can begin once parser (#013) is started
- Benchmarking infrastructure (#012) can be set up early

## Notes
- Each phase builds upon the previous one
- Core infrastructure (Phase 1) is essential for all subsequent work
- ✅ **RESOLVED**: Issues #029-#033 (implementation blockers) have been successfully completed
- Issues #034-#035 address code cleanup from Issue #002 implementation
- **⚠️ PROOF OF CONCEPT**: JSON implementation (Issues #008-#020, #023, #054) serves as proof-of-concept for the generic lexer library. Primary focus should remain on generic lexer infrastructure. JSON may be separated into optional module or removed.
- **🏗️ ARCHITECTURAL**: Issues #008 and #013 include architectural requirements to ensure modular JSON implementation from the start
- Success metrics validate the library's production readiness

## Recent Updates
**2025-08-11 (Session 18 - Current)**:
- ✅ **Completed Issue #054** - Fix Test Design Assumptions in Error Recovery Tests
  - **MAJOR SUCCESS**: Achieved 538/538 tests passing (100% success rate) up from 517/536
  - Fixed 19 tests with incorrect assumptions about lexer quote pairing behavior
  - Created comprehensive error recovery testing guidelines (67KB documentation)
  - Implemented proper error patterns using newlines to break strings instead of quote pairing
  - Added expert agent collaboration (@zig-systems-expert, @zig-test-engineer, @maysara-style-enforcer)
  - Achieved 100% MCS compliance across all changes
- 🔴 **Created Issue #055** - Audit and Fix Test Infrastructure Design Flaws
  - Systematic infrastructure flaws discovered in stress test helper functions
  - Functions generated valid tokens instead of claimed error conditions
  - Critical priority due to potential impact on other test suites
- 🟡 **Created Issue #056** - Create Standardized Error Pattern Library  
  - Address pattern duplication and inconsistency discovered during fixes
  - Centralize validated error generation patterns for reuse across tests
- 🟡 **Created Issue #057** - Enhance Test Review Process for Error Recovery Validation
  - Address systematic review gap that allowed 19 incorrect tests to be committed
  - Create validation requirements and reviewer education for error recovery tests

**2025-08-10 (Session 17)**:
- ✅ **Completed Issue #007** - Implemented JSON token types
  - Added `True`, `False`, and `Null` token types to TokenType enum
  - Replaced placeholder `nextToken()` with complete JSON tokenizer
  - Implemented all structural tokens, literals, strings with escapes, and number validation
  - Integrated proper error handling and recovery mechanisms
  - Test results improved from 500/536 to 517/536 tests passing
- 🟡 **Created Issue #054** - Fix Test Design Assumptions in Error Recovery Tests
  - Identified 19 tests with incorrect assumptions about lexer behavior
  - Tests expect errors for valid token patterns (e.g., paired quotes forming valid strings)
  - Documentation of test design issues discovered during JSON implementation

**2025-08-10 (Session 16)**:
- ✅ **Completed Issue #051** - Exported error handling modules in public API
  - Added `recovery` and `formatter` module exports to PACK section
  - Added convenient re-exports for `ErrorFormatter`, `RecoveryStrategy`, `RecoveryContext`, `ErrorCollector`
  - Updated export test to verify all new modules and types are accessible
  - Achieved 100% MCS compliance with all 479 tests passing
  - Error handling framework is now fully accessible to library users

**2025-08-10 (Session 15)**:
- ✅ **Completed Issue #005** - Created comprehensive error handling framework
  - Implemented 14 error types with rich context (spans, codes, suggestions)
  - Created 4 recovery strategies (SkipToNext, SyncToDelimiter, PanicMode, BestEffort)
  - Built ErrorFormatter with visual indicators and JSON output
  - Integrated with Buffer (recovery marks) and Position (error spans)
  - Added 479 comprehensive tests including stress tests (10MB+ files, thousands of errors)
- 🔴 **Created Issues #051-#052** - Critical integration gaps discovered:
  - #051: New error modules not exported in public API
  - #052: Main lexer not using new error handling framework

**2025-08-10 (Session 14)**:
- 🟡 Partially completed Issue #049 - Cleaned up debug output in test files
  - Fixed `position_integration_test.zig` with compile-time `VERBOSE_TESTS` flag
  - Identified remaining test files needing cleanup
  - Established pattern for test debug output control

**2025-08-09 (Session 13)**:
- ✅ Completed Issue #043 - Fixed critical UTF-8 validation bug (0xC0/0xC1 overlong sequences)
- 🟡 Created Issue #048 - Investigate standalone test execution error

**2025-08-09 (Session 12)**:
- ✅ Completed Issue #042 - Optimized advanceUtf8Bytes() performance
- Achieved 175 MB/s for mixed UTF-8 (1,458x improvement), 11.8 GB/s for pure ASCII
- Added 44 comprehensive unit tests and integration tests for optimized functions
- Conducted MCS compliance audit and technical review
- Created Issues #043-#047 based on technical review findings:
  - #043: Fix UTF-8 validation table bug (Critical - correctness)
  - #044: Add Unicode codepoint validation (Critical - correctness)
  - #045: Add integer overflow protection (Medium - robustness)
  - #046: Fix MCS compliance for optimization code (Medium - code quality)
  - #047: Remove redundant ASCII scanning (Low - performance)

**2025-08-09 (Session 11)**:
- ✅ Completed Issue #039 - Added comprehensive performance benchmarks for position tracking
- Implemented complete benchmark suite with core, buffer, and scenario benchmarks
- Added build system integration with `zig build bench` commands
- Created test data generator for reproducible benchmarking
- **Critical Discovery**: Found severe performance issue in `advanceUtf8Bytes()` taking ~8.5s per MB
- Created Issue #042 to address the critical performance problem

**2025-08-08 (Session 10)**:
- ✅ Completed Issue #004 - Comprehensive source position tracking
- Enhanced PositionTracker with tab width configuration and line ending support (LF, CRLF, CR)
- Added UTF-8 aware position tracking with multi-byte character support
- Integrated optional position tracking into Buffer struct
- Added 234+ comprehensive tests covering all edge cases
- Created Issues #038-#040 based on session review:
  - #038: Add Position Tracking to StreamingBuffer (Critical priority)
  - #039: Add Performance Benchmarks for Position Tracking (Medium priority)
  - #040: Implement Line Offset Table for Large Files (Low priority)

**2025-08-08 (Session 9)**:
- ✅ Completed Issue #036 - Resolved Zig builtin compatibility concerns
- **Key finding**: All `@intCast` patterns already use correct modern syntax
- No deprecated builtins found (`@intToFloat`, `@floatToInt`, etc. already fixed)
- Confirmed `@as()` wrappers are necessary for type inference in arithmetic contexts
- All 172 tests compile and pass with Zig 0.14.1
- Codebase fully compatible with current Zig version

**2025-08-08 (Session 8)**:
- ✅ Completed Issue #037 - Fixed StreamingBuffer implementation bugs
- Fixed EOF detection by adding `valid_bytes` field to track actual data
- Fixed position tracking across window slides
- Added 8 comprehensive edge case tests for StreamingBuffer
- All 172 tests passing with no regressions

**2025-08-07 (Session 7)**:
- ✅ Completed Issue #003 - Build basic character stream handling
- Implemented UTF-8 aware buffer operations with skipWhile/consumeWhile predicates
- Added StreamingBuffer for efficient large file handling
- 45+ comprehensive tests added
- 🚧 Partially resolved Issue #036: Fixed @intToFloat in streaming_test.zig, more deprecated builtins remain
- ✅ Achieved 100% MCS compliance across modified files
- Added Issue #037: Fix StreamingBuffer implementation bugs (Critical)

**2025-08-07 (Session 6)**:
- ✅ Completed Issue #035 - Fixed critical test discovery bug
- **CRITICAL DISCOVERY**: Found that only 61 of 125 tests were running (51% missing!)
- Implemented Super-ZIG/io test import pattern across all modules
- Test count increased from 61 to 125 (104% increase)
- Fixed compilation errors in lexer.zig and position.zig

**2025-08-07 (Session 5)**:
- ✅ Completed Issue #002 - Implemented core token types and interfaces
- Implemented generic `Token(comptime T: type)` function with zero-copy design
- Added 56+ comprehensive tests including zero-copy verification and memory usage validation
- Added Issues #034-#035 based on session review:
  - #034: Remove unnecessary files created during implementation (Medium priority)
  - #035: Remove non-functional test targets from build.zig (Medium priority)

**2025-08-07 (Session 4)**:
- ✅ Completed Issue #031 - Fixed all test implementation compilation errors
- Resolved 5 categories of errors: variable mutability, import paths, namespace boundaries, ArrayList API, array bounds
- All 85 tests across 8 test files now compile and pass successfully

**2025-08-07 (Session 3)**:
- ✅ Completed Issue #030 - Resolved all module import path problems
- Established consistent import pattern: submodules import through parent lexer module

**2025-08-07 (Session 2)**: 
- ✅ Completed Issue #029 - Fixed all memory management and cleanup patterns

**2025-08-07 (Session 1)**: Added issues #029-#033 for critical implementation problems discovered during Issue #001 implementation session.

**2025-01-07**: Initial issue tracking system created with 28 issues covering all aspects of the lexer library development plan.