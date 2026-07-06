# Common CMake build targets for LFI benchmarks
# This file defines standard build targets for projects using CMake
#
# Required variables to be set in the including Makefile:
#   TARGET_DIR - The source directory name
#
# Optional variables:
#   CMAKE_FLAGS - Project-specific CMake flags (default: empty)
#   CMAKE_SOURCE_DIR - CMake source directory (default: $(TARGET_DIR))
#   CMAKE_INSTALL_PREFIX_LFI - LFI install prefix (default: --install-prefix $(LFI_INSTALL))
#   CMAKE_INSTALL_PREFIX_STORES - LFI-stores install prefix (default: --install-prefix $(STORES_INSTALL))  
#   CMAKE_INSTALL_PREFIX_NATIVE - Native install prefix (default: --install-prefix $(NATIVE_INSTALL))

# Set default values if not specified
CMAKE_FLAGS ?=
CMAKE_SOURCE_DIR ?= $(TARGET_DIR)
CMAKE_INSTALL_PREFIX_LFI ?= --install-prefix $(LFI_INSTALL)
CMAKE_INSTALL_PREFIX_STORES ?= --install-prefix $(STORES_INSTALL)
CMAKE_INSTALL_PREFIX_NATIVE ?= --install-prefix $(NATIVE_INSTALL)
CMAKE_LFI_ASM_NASM_COMPILER ?= $(HOME)/code/NASM/nasm-lfi/nasm
CMAKE_NATIVE_ASM_NASM_COMPILER ?= $(HOME)/code/NASM/nasm/nasm
CMAKE_BUILD_TYPE ?= Release

#---ADD NEW TARGETS HERE---

# Hyperfine benchmark targets (name:runner:build_dir)

# Common build targets
build-lfi: $(TARGET_DIR)
	cmake -S $(CMAKE_SOURCE_DIR) $(CMAKE_FLAGS) -B build-lfi -DCMAKE_TOOLCHAIN_FILE=$(LFI_TOOLCHAIN) $(CMAKE_INSTALL_PREFIX_LFI) -DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE)
	cmake --build build-lfi -j $(JOBS)

build-lfi-nasm: $(TARGET_DIR)
	cmake -S $(CMAKE_SOURCE_DIR) $(CMAKE_FLAGS) -B build-lfi-nasm -DCMAKE_TOOLCHAIN_FILE=$(LFI_TOOLCHAIN) $(CMAKE_INSTALL_PREFIX_LFI) -DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE) -DCMAKE_ASM_NASM_COMPILER=$(CMAKE_LFI_ASM_NASM_COMPILER) -DCMAKE_ASM_NASM_FLAGS="-lfi"
	cmake --build build-lfi-nasm -j $(JOBS)

build-lfi-stores: $(TARGET_DIR)
	cmake -S $(CMAKE_SOURCE_DIR) $(CMAKE_FLAGS) -B build-lfi-stores -DCMAKE_TOOLCHAIN_FILE=$(STORES_TOOLCHAIN) $(CMAKE_INSTALL_PREFIX_STORES) -DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE)
	cmake --build build-lfi-stores -j $(JOBS)

build-native: $(TARGET_DIR)
	cmake -S $(CMAKE_SOURCE_DIR) $(CMAKE_FLAGS) -B build-native -DCMAKE_TOOLCHAIN_FILE=$(NATIVE_TOOLCHAIN) $(CMAKE_INSTALL_PREFIX_NATIVE) -DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE)
	cmake --build build-native -j $(JOBS)

build-native-nasm: $(TARGET_DIR)
	cmake -S $(CMAKE_SOURCE_DIR) $(CMAKE_FLAGS) -B build-native-nasm -DCMAKE_TOOLCHAIN_FILE=$(NATIVE_TOOLCHAIN) $(CMAKE_INSTALL_PREFIX_NATIVE) -DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE) -DCMAKE_ASM_NASM_COMPILER=$(CMAKE_NATIVE_ASM_NASM_COMPILER)
	cmake --build build-native-nasm -j $(JOBS)

# Common install target
install: build-lfi build-lfi-stores build-native
	cmake --install build-lfi
	cmake --install build-lfi-stores
	cmake --install build-native

# Standard clean pattern for build directories
.PHONY: build-lfi build-lfi-stores build-native install
