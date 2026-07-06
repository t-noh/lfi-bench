# common.mk - Dispatcher for architecture-specific configurations

# Get the directory of this common.mk file
COMMON_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

# Load local environment variables if .env exists
-include $(COMMON_DIR).env

# Export loaded variables to sub-commands (like cmake/meson)
ifdef ARCH
  export ARCH
endif
ifdef LFI_ROOT
  export LFI_ROOT
endif
ifdef NATIVE_ROOT
  export NATIVE_ROOT
endif
ifdef NASM_LFI
  export NASM_LFI
endif
ifdef NASM_NATIVE
  export NASM_NATIVE
endif
ifdef CMAKE_BUILD_TYPE
  export CMAKE_BUILD_TYPE
endif

# Detect host architecture if ARCH is not set
ARCH ?= $(shell uname -m)

# Normalize ARCH
ifeq ($(ARCH),arm64)
  ARCH := aarch64
endif

ifeq ($(ARCH),x86_64)
  include $(COMMON_DIR)common-x86_64.mk
else ifeq ($(ARCH),aarch64)
  include $(COMMON_DIR)common-aarch64.mk
else
  $(error Unsupported architecture: $(ARCH))
endif
