# GLPK Installation Guide

<br>
<div align="center">
    <p style="font-size: 24px;">
        <i>"Setting Up GLPK for Zig Development"</i>
    </p>
</div>

<div align="center">
    <img src="https://raw.githubusercontent.com/maysara-elshewehy/SuperZIG-assets/refs/heads/main/dist/img/md/line.png" alt="line" style="display: block; margin-top:20px;margin-bottom:20px;width:500px;"/>
    <br>
</div>

## Overview

This guide provides comprehensive instructions for installing and configuring the GNU Linear Programming Kit (GLPK) for use with the zig-glpk wrapper library. GLPK is a powerful open-source library for solving large-scale linear programming (LP), mixed integer programming (MIP), and related optimization problems.

## Requirements

- **GLPK Version**: 4.65 or later (version 5.0+ recommended)
- **Zig Version**: 0.14.0 or later
- **C Compiler**: gcc, clang, or zig cc (for verification)
- **Platform**: Linux, macOS, or Windows

<div align="center">
    <img src="https://raw.githubusercontent.com/maysara-elshewehy/SuperZIG-assets/refs/heads/main/dist/img/md/line.png" alt="line" style="display: block; margin-top:20px;margin-bottom:20px;width:500px;"/>
</div>

## Platform-Specific Installation

### Fedora / RHEL / CentOS

```bash
# Install GLPK and development headers
sudo dnf install glpk glpk-devel

# Verify installation
rpm -qa | grep glpk
```

**Verified Paths (Fedora 42)**:
- Header: `/usr/include/glpk.h`
- Library: `/usr/lib64/libglpk.so`
- Version: 5.0-13

### Ubuntu / Debian

```bash
# Install GLPK and development headers
sudo apt-get update
sudo apt-get install libglpk-dev glpk-utils

# Verify installation
dpkg -l | grep glpk
```

**Typical Paths**:
- Header: `/usr/include/glpk.h`
- Library: `/usr/lib/x86_64-linux-gnu/libglpk.so`

### Arch Linux

```bash
# Install GLPK
sudo pacman -S glpk

# Verify installation
pacman -Q glpk
```

**Typical Paths**:
- Header: `/usr/include/glpk.h`
- Library: `/usr/lib/libglpk.so`

### macOS

```bash
# Using Homebrew
brew install glpk

# Using MacPorts
sudo port install glpk

# Verify installation
brew list glpk || port installed glpk
```

**Homebrew Paths**:
- Header: `/opt/homebrew/include/glpk.h` (Apple Silicon) or `/usr/local/include/glpk.h` (Intel)
- Library: `/opt/homebrew/lib/libglpk.dylib` (Apple Silicon) or `/usr/local/lib/libglpk.dylib` (Intel)

**MacPorts Paths**:
- Header: `/opt/local/include/glpk.h`
- Library: `/opt/local/lib/libglpk.dylib`

### Windows

#### Option 1: Pre-built Binaries

1. Download GLPK for Windows from: https://sourceforge.net/projects/winglpk/
2. Extract to a directory (e.g., `C:\glpk`)
3. Add the `bin` directory to your PATH
4. Set environment variables:
   ```cmd
   set GLPK_INCLUDE=C:\glpk\include
   set GLPK_LIB=C:\glpk\lib
   ```

#### Option 2: MSYS2

```bash
# Install GLPK using pacman
pacman -S mingw-w64-x86_64-glpk

# Verify installation
pacman -Q mingw-w64-x86_64-glpk
```

#### Option 3: Build from Source

1. Download source from: https://www.gnu.org/software/glpk/
2. Extract and build:
   ```bash
   ./configure
   make
   make install
   ```

<div align="center">
    <img src="https://raw.githubusercontent.com/maysara-elshewehy/SuperZIG-assets/refs/heads/main/dist/img/md/line.png" alt="line" style="display: block; margin-top:20px;margin-bottom:20px;width:500px;"/>
</div>

## Verification

### Automatic Verification

Run the provided verification script to check your GLPK installation:

```bash
# Make the script executable
chmod +x scripts/verify-glpk.sh

# Run verification
./scripts/verify-glpk.sh
```

The script will check for:
- GLPK header file location
- GLPK library file location
- GLPK version compatibility
- C compilation test

Expected output for a successful installation:
```
════════════════════════════════════════════════════════════════════════
                    GLPK Installation Verification                      
════════════════════════════════════════════════════════════════════════

Checking for GLPK header file... ✓ Found at: /usr/include/glpk.h
Checking for GLPK library file... ✓ Found at: /usr/lib64/libglpk.so
Checking GLPK version... ✓ Version 5.0
Testing C compilation with GLPK... ✓ Success
  GLPK version: 5.0

════════════════════════════════════════════════════════════════════════
                           Verification Summary                         
════════════════════════════════════════════════════════════════════════

  Status: ✓ GLPK is ready for use!
```

### Manual Verification

If the automatic script doesn't work, verify manually:

1. **Check for header file**:
   ```bash
   find /usr -name "glpk.h" 2>/dev/null
   ```

2. **Check for library file**:
   ```bash
   find /usr -name "libglpk*" 2>/dev/null
   ```

3. **Check version** (if glpsol is installed):
   ```bash
   glpsol --version
   ```

4. **Test compilation**:
   ```c
   // test.c
   #include <glpk.h>
   #include <stdio.h>
   
   int main() {
       glp_prob *lp = glp_create_prob();
       printf("GLPK version: %s\n", glp_version());
       glp_delete_prob(lp);
       return 0;
   }
   ```
   
   Compile with:
   ```bash
   gcc -o test test.c -lglpk
   # or
   zig cc -o test test.c -lglpk
   ```

<div align="center">
    <img src="https://raw.githubusercontent.com/maysara-elshewehy/SuperZIG-assets/refs/heads/main/dist/img/md/line.png" alt="line" style="display: block; margin-top:20px;margin-bottom:20px;width:500px;"/>
</div>

## Building the Zig Wrapper

Once GLPK is installed and verified:

```bash
# Build the library
zig build

# Run tests
zig build test
```

The build system will automatically:
- Link with the GLPK library
- Include GLPK headers
- Configure for your platform

<div align="center">
    <img src="https://raw.githubusercontent.com/maysara-elshewehy/SuperZIG-assets/refs/heads/main/dist/img/md/line.png" alt="line" style="display: block; margin-top:20px;margin-bottom:20px;width:500px;"/>
</div>

## Troubleshooting

### Common Issues

#### 1. Header File Not Found

**Error**: `fatal error: glpk.h: No such file or directory`

**Solution**: Install development headers:
- Fedora: `sudo dnf install glpk-devel`
- Ubuntu: `sudo apt-get install libglpk-dev`
- macOS: `brew install glpk`

#### 2. Library Not Found at Runtime

**Error**: `error while loading shared libraries: libglpk.so`

**Solution**: Update library path:
```bash
# Linux
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# macOS
export DYLD_LIBRARY_PATH=/usr/local/lib:$DYLD_LIBRARY_PATH
```

#### 3. Version Too Old

**Error**: GLPK version is older than 4.65

**Solution**: Update GLPK to a newer version:
- Build from source: https://www.gnu.org/software/glpk/
- Use a newer package repository
- Use a package manager with updated versions

#### 4. No C Compiler Available

**Warning**: No C compiler found for verification

**Solution**: The verification script needs a C compiler. Install one:
- `sudo dnf install gcc` (Fedora)
- `sudo apt-get install gcc` (Ubuntu)
- Or use `zig cc` which comes with Zig

#### 5. Windows Path Issues

**Error**: GLPK not found on Windows

**Solution**: Ensure paths are correctly set:
```cmd
set PATH=%PATH%;C:\glpk\bin
set INCLUDE=%INCLUDE%;C:\glpk\include
set LIB=%LIB%;C:\glpk\lib
```

### Building GLPK from Source

If your package manager doesn't have GLPK or has an old version:

```bash
# Download latest source
wget https://ftp.gnu.org/gnu/glpk/glpk-5.0.tar.gz
tar -xzf glpk-5.0.tar.gz
cd glpk-5.0

# Configure and build
./configure --prefix=/usr/local
make
sudo make install

# Update library cache (Linux)
sudo ldconfig
```

<div align="center">
    <img src="https://raw.githubusercontent.com/maysara-elshewehy/SuperZIG-assets/refs/heads/main/dist/img/md/line.png" alt="line" style="display: block; margin-top:20px;margin-bottom:20px;width:500px;"/>
</div>

## Version Compatibility

| GLPK Version | Status | Notes |
|--------------|--------|-------|
| 5.0+ | ✅ Recommended | Latest features, best performance |
| 4.65 - 4.99 | ✅ Supported | Minimum required version |
| 4.45 - 4.64 | ⚠️ Limited | May work but not tested |
| < 4.45 | ❌ Unsupported | Missing required features |

<div align="center">
    <img src="https://raw.githubusercontent.com/maysara-elshewehy/SuperZIG-assets/refs/heads/main/dist/img/md/line.png" alt="line" style="display: block; margin-top:20px;margin-bottom:20px;width:500px;"/>
</div>

## Additional Resources

- **GLPK Official Site**: https://www.gnu.org/software/glpk/
- **GLPK Documentation**: https://www.gnu.org/software/glpk/glpk.pdf
- **GLPK Examples**: https://github.com/firedrakeproject/glpk/tree/master/examples
- **zig-glpk Repository**: https://github.com/scoomboot/zig-glpk

<div align="center">
    <img src="https://raw.githubusercontent.com/maysara-elshewehy/SuperZIG-assets/refs/heads/main/dist/img/md/line.png" alt="line" style="display: block; margin-top:20px;margin-bottom:20px;width:500px;"/>
</div>

## Support

If you encounter issues not covered in this guide:

1. Run the verification script and include the output
2. Check the [Issues](https://github.com/scoomboot/zig-glpk/issues) page
3. Provide your platform, GLPK version, and Zig version when reporting issues

<br>
<div align="center">
    <p style="font-size: 18px;">
        <i>Happy Optimizing! 🚀</i>
    </p>
</div>