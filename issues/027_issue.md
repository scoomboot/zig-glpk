# Issue #027: Set up CI/CD pipeline

## Priority
🟢 Low

## References
- [Issue Index](000_index.md)
- [GLPK Wrapper Plan](../issues/planning/glpk-wrapper-plan.md#65-cicd-setup)
- [Issue #018](018_issue.md) - Unit tests
- [Issue #019](019_issue.md) - Problem management tests
- [Issue #020](020_issue.md) - LP integration tests
- [Issue #021](021_issue.md) - MIP integration tests

## Description
Set up comprehensive CI/CD pipeline using GitHub Actions to automate building, testing, and releasing the GLPK wrapper across multiple platforms.

## Requirements

### Main CI Workflow
Create `.github/workflows/ci.yml`:
```yaml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 0 * * 0'  # Weekly run to catch dependency issues

env:
  ZIG_VERSION: '0.11.0'

jobs:
  test:
    name: Test (${{ matrix.os }})
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        include:
          - os: ubuntu-latest
            glpk_install: |
              sudo apt-get update
              sudo apt-get install -y libglpk-dev
          - os: macos-latest
            glpk_install: |
              brew update
              brew install glpk
          - os: windows-latest
            glpk_install: |
              # Windows GLPK installation
              curl -L -o glpk.zip https://sourceforge.net/projects/winglpk/files/latest/download
              unzip glpk.zip
              echo "GLPK_PATH=$PWD/glpk" >> $GITHUB_ENV
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Install GLPK
        run: ${{ matrix.glpk_install }}
      
      - name: Setup Zig
        uses: goto-bus-stop/setup-zig@v2
        with:
          version: ${{ env.ZIG_VERSION }}
      
      - name: Verify Installation
        run: |
          zig version
          zig env
      
      - name: Cache Zig build
        uses: actions/cache@v3
        with:
          path: |
            ~/.cache/zig
            zig-cache
            zig-out
          key: ${{ runner.os }}-zig-${{ hashFiles('build.zig.zon') }}
          restore-keys: |
            ${{ runner.os }}-zig-
      
      - name: Build
        run: zig build -Doptimize=Debug
      
      - name: Run Tests
        run: zig build test -Doptimize=Debug
      
      - name: Run Integration Tests
        run: |
          zig build test-integration -Doptimize=Debug
      
      - name: Build Examples
        run: |
          zig build examples -Doptimize=ReleaseSafe
      
      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results-${{ matrix.os }}
          path: |
            zig-out/test-results.xml
            test.log

  memory-check:
    name: Memory Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y libglpk-dev valgrind
      
      - name: Setup Zig
        uses: goto-bus-stop/setup-zig@v2
        with:
          version: ${{ env.ZIG_VERSION }}
      
      - name: Build Debug
        run: zig build -Doptimize=Debug
      
      - name: Run Valgrind
        run: |
          valgrind --leak-check=full \
                   --show-leak-kinds=all \
                   --error-exitcode=1 \
                   --xml=yes \
                   --xml-file=valgrind.xml \
                   ./zig-out/bin/test
      
      - name: Upload Valgrind Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: valgrind-results
          path: valgrind.xml

  coverage:
    name: Code Coverage
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y libglpk-dev lcov
      
      - name: Setup Zig
        uses: goto-bus-stop/setup-zig@v2
        with:
          version: ${{ env.ZIG_VERSION }}
      
      - name: Build with Coverage
        run: |
          zig build test -Dtest-coverage=true
      
      - name: Generate Coverage Report
        run: |
          # Process Zig coverage data
          # This would need a tool to convert Zig coverage to lcov format
          # For now, this is a placeholder
          echo "Coverage report generation"
      
      - name: Upload Coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage.lcov
          flags: unittests
          name: codecov-umbrella

  benchmark:
    name: Performance Benchmark
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y libglpk-dev
      
      - name: Setup Zig
        uses: goto-bus-stop/setup-zig@v2
        with:
          version: ${{ env.ZIG_VERSION }}
      
      - name: Build Benchmarks
        run: zig build bench -Doptimize=ReleaseFast
      
      - name: Run Benchmarks
        run: |
          ./zig-out/bin/bench > benchmark-results.txt
      
      - name: Store Benchmark Results
        uses: benchmark-action/github-action-benchmark@v1
        with:
          tool: 'customBiggerIsBetter'
          output-file-path: benchmark-results.txt
          github-token: ${{ secrets.GITHUB_TOKEN }}
          auto-push: true
      
      - name: Upload Benchmark Results
        uses: actions/upload-artifact@v3
        with:
          name: benchmark-results
          path: benchmark-results.txt

  lint:
    name: Code Quality
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Zig
        uses: goto-bus-stop/setup-zig@v2
        with:
          version: ${{ env.ZIG_VERSION }}
      
      - name: Check Formatting
        run: |
          zig fmt --check .
      
      - name: Run Zig Analyzer
        run: |
          # Install and run zls or other Zig analysis tools
          echo "Running code analysis"
      
      - name: Check Documentation
        run: |
          zig build docs
          # Verify all public APIs are documented

  cross-compile:
    name: Cross Compilation
    runs-on: ubuntu-latest
    strategy:
      matrix:
        target: [
          x86_64-linux-gnu,
          x86_64-macos,
          x86_64-windows,
          aarch64-linux-gnu,
          aarch64-macos,
          wasm32-wasi
        ]
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Zig
        uses: goto-bus-stop/setup-zig@v2
        with:
          version: ${{ env.ZIG_VERSION }}
      
      - name: Cross Compile
        run: |
          zig build -Dtarget=${{ matrix.target }} -Doptimize=ReleaseSafe
      
      - name: Upload Artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build-${{ matrix.target }}
          path: zig-out/lib/
```

### Release Workflow
Create `.github/workflows/release.yml`:
```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    name: Create Release
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Zig
        uses: goto-bus-stop/setup-zig@v2
        with:
          version: '0.11.0'
      
      - name: Build Release Artifacts
        run: |
          # Build for multiple targets
          zig build -Dtarget=x86_64-linux -Doptimize=ReleaseSafe
          mv zig-out zig-out-linux-x64
          
          zig build -Dtarget=x86_64-macos -Doptimize=ReleaseSafe
          mv zig-out zig-out-macos-x64
          
          zig build -Dtarget=x86_64-windows -Doptimize=ReleaseSafe
          mv zig-out zig-out-windows-x64
      
      - name: Create Archives
        run: |
          tar czf zig-glpk-linux-x64.tar.gz zig-out-linux-x64
          tar czf zig-glpk-macos-x64.tar.gz zig-out-macos-x64
          zip -r zig-glpk-windows-x64.zip zig-out-windows-x64
      
      - name: Generate Changelog
        id: changelog
        run: |
          # Extract changelog for this version
          echo "CHANGELOG<<EOF" >> $GITHUB_OUTPUT
          git log --pretty=format:"- %s" $(git describe --tags --abbrev=0 HEAD^)..HEAD >> $GITHUB_OUTPUT
          echo "EOF" >> $GITHUB_OUTPUT
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            zig-glpk-linux-x64.tar.gz
            zig-glpk-macos-x64.tar.gz
            zig-glpk-windows-x64.zip
          body: |
            ## What's Changed
            ${{ steps.changelog.outputs.CHANGELOG }}
            
            ## Installation
            See the [README](https://github.com/${{ github.repository }}/blob/main/README.md) for installation instructions.
          draft: false
          prerelease: false
```

### Documentation Deployment
Create `.github/workflows/docs.yml`:
```yaml
name: Documentation

on:
  push:
    branches: [ main ]
    paths:
      - 'docs/**'
      - 'lib/**'
      - 'examples/**'

jobs:
  docs:
    name: Build and Deploy Docs
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Zig
        uses: goto-bus-stop/setup-zig@v2
        with:
          version: '0.11.0'
      
      - name: Build Documentation
        run: |
          zig build docs
          
      - name: Generate API Docs
        run: |
          # Generate HTML documentation
          mkdir -p public
          cp -r zig-out/docs/* public/
          cp -r docs/* public/
          cp -r examples public/
      
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./public
```

### Dependency Updates
Create `.github/workflows/dependencies.yml`:
```yaml
name: Dependency Updates

on:
  schedule:
    - cron: '0 0 * * 1'  # Weekly on Monday
  workflow_dispatch:

jobs:
  update:
    name: Update Dependencies
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Zig
        uses: goto-bus-stop/setup-zig@v2
        with:
          version: '0.11.0'
      
      - name: Update Zig Dependencies
        run: |
          # Update build.zig.zon dependencies
          zig build update-deps
      
      - name: Test Updated Dependencies
        run: |
          zig build test
      
      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v5
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          commit-message: 'chore: update dependencies'
          title: 'chore: update dependencies'
          body: |
            ## Dependency Updates
            
            This PR updates the project dependencies to their latest versions.
            
            Please review and merge if all tests pass.
          branch: update-dependencies
          delete-branch: true
```

### Makefile for Local Development
Create `Makefile`:
```makefile
.PHONY: all build test clean install docs

ZIG ?= zig
OPTIMIZE ?= Debug
PREFIX ?= /usr/local

all: build

build:
→ $(ZIG) build -Doptimize=$(OPTIMIZE)

test:
→ $(ZIG) build test -Doptimize=$(OPTIMIZE)

test-verbose:
→ $(ZIG) build test -Doptimize=$(OPTIMIZE) --verbose

test-integration:
→ $(ZIG) build test-integration -Doptimize=$(OPTIMIZE)

bench:
→ $(ZIG) build bench -Doptimize=ReleaseFast

docs:
→ $(ZIG) build docs

clean:
→ rm -rf zig-out zig-cache

install: build
→ cp zig-out/lib/* $(PREFIX)/lib/
→ cp -r lib/*.zig $(PREFIX)/include/

format:
→ $(ZIG) fmt .

check-format:
→ $(ZIG) fmt --check .

memcheck: build
→ valgrind --leak-check=full --show-leak-kinds=all ./zig-out/bin/test

coverage:
→ $(ZIG) build test -Dtest-coverage=true
→ lcov --capture --directory . --output-file coverage.info
→ genhtml coverage.info --output-directory coverage-report

ci-local:
→ @echo "Running CI checks locally..."
→ @$(MAKE) format-check
→ @$(MAKE) build
→ @$(MAKE) test
→ @$(MAKE) test-integration
→ @echo "All CI checks passed!"
```

### Build Configuration Updates
Update `build.zig`:
```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    
    // Main library
    const lib = b.addStaticLibrary(.{
        .name = "zig-glpk",
        .root_source_file = .{ .path = "lib/lib.zig" },
        .target = target,
        .optimize = optimize,
    });
    lib.linkSystemLibrary("glpk");
    lib.linkLibC();
    b.installArtifact(lib);
    
    // Tests
    const tests = b.addTest(.{
        .root_source_file = .{ .path = "lib/lib.zig" },
        .target = target,
        .optimize = optimize,
    });
    tests.linkSystemLibrary("glpk");
    tests.linkLibC();
    
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&tests.step);
    
    // Integration tests
    const integration_tests = b.addTest(.{
        .root_source_file = .{ .path = "test/integration/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    integration_tests.linkSystemLibrary("glpk");
    integration_tests.linkLibC();
    
    const integration_step = b.step("test-integration", "Run integration tests");
    integration_step.dependOn(&integration_tests.step);
    
    // Benchmarks
    const bench = b.addExecutable(.{
        .name = "bench",
        .root_source_file = .{ .path = "bench/main.zig" },
        .target = target,
        .optimize = .ReleaseFast,
    });
    bench.linkSystemLibrary("glpk");
    bench.linkLibC();
    
    const bench_step = b.step("bench", "Run benchmarks");
    bench_step.dependOn(&bench.step);
    
    // Examples
    const examples_step = b.step("examples", "Build examples");
    const example_files = [_][]const u8{
        "diet_problem",
        "transportation",
        "knapsack",
        "production_planning",
    };
    
    for (example_files) |name| {
        const example = b.addExecutable(.{
            .name = name,
            .root_source_file = .{ .path = b.fmt("examples/{s}.zig", .{name}) },
            .target = target,
            .optimize = optimize,
        });
        example.linkSystemLibrary("glpk");
        example.linkLibC();
        examples_step.dependOn(&example.step);
    }
    
    // Documentation
    const docs_step = b.step("docs", "Generate documentation");
    // Add documentation generation logic
}
```

## Implementation Notes
- Test on multiple platforms
- Cache dependencies for faster builds
- Run tests in parallel where possible
- Upload artifacts for debugging failures
- Monitor performance over time
- Automate dependency updates

## Testing Requirements
- CI passes on all platforms
- Memory checks find no leaks
- Benchmarks run successfully
- Documentation builds correctly
- Release process works

## Dependencies
- [#018](018_issue.md) - Unit tests must exist
- [#019](019_issue.md) - Problem management tests
- [#020](020_issue.md) - LP integration tests
- [#021](021_issue.md) - MIP integration tests

## Acceptance Criteria
- [ ] CI workflow created and working
- [ ] Tests run on Linux, macOS, Windows
- [ ] Memory checking with valgrind
- [ ] Code coverage reporting
- [ ] Performance benchmarking
- [ ] Cross-compilation tested
- [ ] Release workflow automated
- [ ] Documentation deployment working
- [ ] Dependency updates automated
- [ ] Local development tools provided

## Status
🟢 Not Started