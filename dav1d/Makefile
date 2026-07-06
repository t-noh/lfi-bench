# Include shared configuration
include ../common.mk

# Benchmark-specific configuration
RUNS   ?= 1
WARMUP ?= 0

TARGET_DIR := dav1d

all: bench

$(TARGET_DIR):
	git clone https://github.com/videolan/dav1d.git
	cd $(TARGET_DIR) && git checkout 77ef66354d76a3c8aa4b11cde8093294fce23b0f && patch -p1 < ../dav1d-lfi.patch

dav1d-benchdata:
	wget https://github.com/zyedidia/lfi-bench/releases/download/benchdata/dav1d-benchdata.tar.gz
	tar -xf dav1d-benchdata.tar.gz
	rm -f dav1d-benchdata.tar.gz

build-lfi: $(TARGET_DIR)
	meson setup build-lfi $(TARGET_DIR) --cross-file $(LFI_MESON) -Denable_asm=false -Ddefault_library=static
	ninja -C build-lfi

build-lfi-nasm: $(TARGET_DIR)
	meson setup build-lfi-nasm $(TARGET_DIR) --cross-file $(LFI_MESON) -Denable_asm=true -Ddefault_library=static -Dpass_lfi=true
	ninja -C build-lfi-nasm

# build-lfi-stores: $(TARGET_DIR)
# 	meson setup build-lfi-stores $(TARGET_DIR) --cross-file $(STORES_MESON) -Ddefault_library=static
# 	ninja -C build-lfi-stores

build-native: $(TARGET_DIR)
	meson setup build-native $(TARGET_DIR) --cross-file $(NATIVE_MESON) -Denable_asm=false -Ddefault_library=static
	ninja -C build-native

build-native-nasm: $(TARGET_DIR)
	meson setup build-native-nasm $(TARGET_DIR) --cross-file $(NATIVE_MESON) -Denable_asm=true -Ddefault_library=static
	ninja -C build-native-nasm

bench: dav1d.csv

# Video decode benchmark
dav1d.csv: build-native build-lfi build-native-nasm build-lfi-nasm dav1d-benchdata
	../hyperfine.py --name dav1d --cmd "{BUILD_DIR}/tools/dav1d -i dav1d-benchdata/Bosphorus_3840x2160_120fps_420_8bit.ivf -o /dev/null --threads=$(THREADS)" --targets "$(NASM_HYPERFINE_TARGETS)" --run-command-flags="-p" --runs $(RUNS) --warmup $(WARMUP)

clean:
	rm -rf $(BUILD_DIRS) $(TARGET_DIR) dav1d-benchdata
		rm -f *.csv

.PHONY: all bench clean
