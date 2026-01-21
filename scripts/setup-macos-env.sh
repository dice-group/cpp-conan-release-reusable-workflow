#!/bin/bash

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: Script must be sourced, Usage: source $0 <gcc_version>" >&2
    exit 1
fi

if [[ -z "$1" ]]; then
    echo "Error: Missing argument, Usage: source $0 <gcc_version>" >&2
    return 1
fi

if ! brew --version > /dev/null 2>&1; then
    echo "Error: Homebrew missing, install from https://brew.sh/." >&2
    return 1
fi

GCC_VERSION="$1"

REQUIRED_FORMULAE=(
    "gcc@${GCC_VERSION}"
    "openjdk"
    "cmake"
    "ninja"
)

for formula in "${REQUIRED_FORMULAE[@]}"; do
    if ! brew list --formula "${formula}" &>/dev/null; then
        echo "Error: ${formula} missing, install with `brew install ${formula}`" >&2
        return 1
    fi
done

GCC_PREFIX="$(brew --prefix "gcc@${GCC_VERSION}")"
OPENJDK_PREFIX="$(brew --prefix "openjdk")"


# specify minimum support macOS version
export MACOSX_DEPLOYMENT_TARGET="15.0"

# java needs to be in path
export PATH="${OPENJDK_PREFIX}/bin:${PATH}"

# apple-clang is completely incompatible to tentris in every way
# llvm-clang has issues with thread local variables when using libstdc++ and libc++ is completely imcompatible to tentris
export CC="${GCC_PREFIX}/bin/gcc-${GCC_VERSION}"
export CXX="${GCC_PREFIX}/bin/g++-${GCC_VERSION}"

# aws-lc-sys requires __ARM_FEATURE_AES and __ARM_FEATURE_SHA2
# which are only enabled when you pass this option
# see https://developer.arm.com/documentation/101754/0624/armclang-Reference/armclang-Command-line-Options/-march
export CFLAGS="-march=armv8-a+aes+sha2"

# rustc needs to be able to find libgcc.a libgcc_s.dylib and libstdc++.a
export RUSTFLAGS="-L${GCC_PREFIX}/lib/gcc/${GCC_VERSION} -L${GCC_PREFIX}/lib/gcc/${GCC_VERSION}/gcc/aarch64-apple-darwin24/${GCC_VERSION}"

# Workaround for issue in aws-lc-sys jitter-entropy component
# https://github.com/aws/aws-lc-rs/issues/1008
export AWS_LC_SYS_NO_JITTER_ENTROPY=1
