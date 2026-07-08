#!/bin/bash
# benchmark_lfi_simd.sh - LFI vs Native SIMD benchmark with CPU pinning (taskset) and CSV output

set -e

if [ -z "${LFI_RUN:-}" ]; then
    echo "Error: LFI_RUN environment variable is not set." >&2
    echo "Usage: LFI_RUN=/path/to/lfi-run $0 [test-images-dir]" >&2
    exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Test images directory
IMG_DIR=${1:-"$SCRIPT_DIR/libjpeg-turbo/testimages"}
if [ ! -d "$IMG_DIR" ]; then
    # Try fallback for submodule
    IMG_DIR="$SCRIPT_DIR/libjpeg-turbo/libjpeg-turbo/testimages"
fi

if [ ! -d "$IMG_DIR" ]; then
    echo "Error: Test images directory '$IMG_DIR' not found." >&2
    exit 1
fi

# CPU Core for pinning (default to core 1 to avoid core 0 which handles interrupts)
BENCH_CORE=${BENCH_CORE:-1}

# Define test cases: "name;image_name;subsamp;extra_args"
TESTS=(
    "Bird 420;shira_bird8.bmp;420;"
    "Bird GRAY;shira_bird8.bmp;GRAY;"
    "Car 420;vgl_6434_0018a.bmp;420;"
    "Car GRAY;vgl_6434_0018a.bmp;GRAY;"
    "Bird Scale 1/2;shira_bird8.bmp;420;-scale 1/2"
)

# Define configurations: "name;env_name;env_val;binary;use_lfi"
CONFIGS=(
    "Native C;JSIMD_FORCENONE;1;build-native-nasm/tjbench-static;false"
    "Native SSE2;JSIMD_FORCESSE2;1;build-native-nasm/tjbench-static;false"
    "Native AVX2;;;build-native-nasm/tjbench-static;false"
    "LFI C;JSIMD_FORCENONE;1;build-lfi-nasm/tjbench-static;true"
    "LFI SSE2;JSIMD_FORCESSE2;1;build-lfi-nasm/tjbench-static;true"
    "LFI AVX2;;;build-lfi-nasm/tjbench-static;true"
)

QUALITY="95"
BENCHTIME="5.0"

declare -A RESULTS

if [ -n "$BENCH_CORE" ]; then
    echo "Pinning benchmarks to CPU core: $BENCH_CORE" >&2
fi

for test in "${TESTS[@]}"; do
    IFS=';' read -r t_name t_img t_subsamp t_extra <<< "$test"
    img_path="$IMG_DIR/$t_img"

    if [ ! -f "$img_path" ]; then
        echo "Warning: Image $img_path not found. Skipping $t_name." >&2
        continue
    fi

    echo "Benchmarking: $t_name" >&2

    for cfg in "${CONFIGS[@]}"; do
        IFS=';' read -r c_name env_name env_val binary use_lfi <<< "$cfg"
        bin_path="$SCRIPT_DIR/$binary"

        if [ ! -f "$bin_path" ]; then
            echo "  Warning: Binary $bin_path not found. Skipping $c_name." >&2
            continue
        fi

        echo "  Running $c_name..." >&2

        # Setup command with taskset
        cmd=()
        if [ -n "$BENCH_CORE" ]; then
            cmd+=("taskset" "-c" "$BENCH_CORE")
        fi

        if [ "$use_lfi" = "true" ]; then
            cmd+=("$LFI_RUN")
            if [ -n "$env_name" ]; then
                cmd+=("--env=$env_name=$env_val")
            fi
            cmd+=("--")
        fi

        cmd+=("$bin_path" "$img_path" "$QUALITY" -subsamp "$t_subsamp" -nowrite -benchtime "$BENCHTIME")
        if [ -n "$t_extra" ]; then
            read -r -a extra_arr <<< "$t_extra"
            cmd+=("${extra_arr[@]}")
        fi

        # Run
        if [ "$use_lfi" = "true" ]; then
            OUTPUT=$("${cmd[@]}" 2>/dev/null)
        else
            if [ -n "$env_name" ]; then
                OUTPUT=$(env "$env_name=$env_val" "${cmd[@]}" 2>/dev/null)
            else
                OUTPUT=$("${cmd[@]}" 2>/dev/null)
            fi
        fi

        # Parse
        comp=$(echo "$OUTPUT" | grep -A 4 "Compress      -->" | grep "Throughput:" | awk '{print $2}')
        decomp=$(echo "$OUTPUT" | grep -A 2 "Decompress    -->" | grep "Throughput:" | awk '{print $2}')

        key_t=${t_name// /_}
        key_c=${c_name// /_}
        RESULTS["${key_t}_${key_c}_comp"]=$comp
        RESULTS["${key_t}_${key_c}_decomp"]=$decomp
    done
done

# Print results in CSV format to stdout
echo "Test Case,Configuration,Compression (Mpps),Decompression (Mpps)"
for test in "${TESTS[@]}"; do
    IFS=';' read -r t_name t_img t_subsamp t_extra <<< "$test"
    key_t=${t_name// /_}

    # Check if we have any results for this test
    has_results=false
    for cfg in "${CONFIGS[@]}"; do
        IFS=';' read -r c_name _ <<< "$cfg"
        key_c=${c_name// /_}
        if [ -n "${RESULTS["${key_t}_${key_c}_comp"]:-}" ]; then
            has_results=true
            break
        fi
    done

    if [ "$has_results" = "false" ]; then
        continue
    fi

    for cfg in "${CONFIGS[@]}"; do
        IFS=';' read -r c_name _ <<< "$cfg"
        key_c=${c_name// /_}

        comp=${RESULTS["${key_t}_${key_c}_comp"]:-}
        decomp=${RESULTS["${key_t}_${key_c}_decomp"]:-}

        comp_val=""
        decomp_val=""
        [ -n "$comp" ] && comp_val=$(printf "%.2f" "$comp")
        [ -n "$decomp" ] && decomp_val=$(printf "%.2f" "$decomp")

        echo "$t_name,$c_name,$comp_val,$decomp_val"
    done
done
