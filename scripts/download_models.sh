#!/usr/bin/env bash
set -euo pipefail

# Download and SHA256-verify model groups into /opt/model_store and symlink into workspace-internal.
# Usage:
#   download_models.sh <selector> [comfy_models_dir]
# Selectors:
#   core       - RealESRGAN + qwen_image_vae + qwen_3_06b_base (~1.46 GB)
#   turbo      - anima-turbo-v1.1.safetensors (~3.9 GB)
#   anima-turbo - core + turbo (~5.4 GB)
#   diffusion  - anima-aesthetic-v1.1 + anima-base-v1.0 (~8.4 GB)
#   anima      - core + turbo + diffusion
#   sdxl_ckpt  - NoobAI-XL-v1.1.safetensors (~7.1 GB)
#   sdxl_cn    - controlnet++_union_sdxl_promax + noobaiXLControlnet_openposeModel (~5.0 GB)
#   full       - core + turbo + diffusion + sdxl_ckpt + sdxl_cn (~26.1 GB)

SELECTOR="${1:-anima}"
TARGET_MODELS_DIR="${2:-/opt/workspace-internal/ComfyUI/models}"
MANIFEST="${MODELS_MANIFEST:-/opt/xintai/models.sha256}"
STORE_DIR="${MODEL_STORE_DIR:-/opt/model_store}"
HF_BASE="${HF_ENDPOINT:-https://huggingface.co}"
HF_BASE="${HF_BASE%/}"

matches_selector() {
    local grp="$1"
    case "${SELECTOR}" in
        all|full)
            return 0
            ;;
        anima-turbo|anima_turbo)
            [[ "$grp" == "core" || "$grp" == "turbo" ]]
            ;;
        anima)
            [[ "$grp" == "core" || "$grp" == "turbo" || "$grp" == "diffusion" ]]
            ;;
        *)
            [[ "$grp" == "${SELECTOR}" ]]
            ;;
    esac
}

download_file() {
    local url="$1"
    local dest="$2"
    local tmp="${dest}.part"

    mkdir -p "$(dirname "$dest")"
    rm -f "$tmp"

    echo "[models] Downloading $(basename "$dest") from ${url}"
    if command -v aria2c >/dev/null 2>&1; then
        aria2c --allow-overwrite=true --auto-file-renaming=false \
            -x 16 -s 16 -k 4M --retry-wait=3 --max-tries=5 \
            -d "$(dirname "$tmp")" -o "$(basename "$tmp")" "$url"
    else
        curl -fSL --retry 5 --retry-delay 3 -o "$tmp" "$url"
    fi
    mv -f "$tmp" "$dest"
}

verify_sha256() {
    local file="$1"
    local expected="$2"
    local actual
    actual="$(sha256sum "$file" | awk '{print $1}')"
    if [[ "$actual" != "$expected" ]]; then
        echo "[models] SHA256 mismatch for $file: expected=$expected actual=$actual" >&2
        return 1
    fi
}

while IFS='|' read -r grp relpath expected_sha hf_rel; do
    grp="$(printf '%s' "$grp" | tr -d '\r')"
    relpath="$(printf '%s' "$relpath" | tr -d '\r')"
    expected_sha="$(printf '%s' "$expected_sha" | tr -d '\r')"
    hf_rel="$(printf '%s' "$hf_rel" | tr -d '\r')"

    [[ -z "$grp" || "$grp" == \#* ]] && continue
    matches_selector "$grp" || continue

    store_file="${STORE_DIR}/${relpath}"
    link_path="${TARGET_MODELS_DIR}/${relpath}"
    url="${HF_BASE}/${hf_rel}"

    if [[ -f "$store_file" ]]; then
        if verify_sha256 "$store_file" "$expected_sha"; then
            echo "[models] Verified cached ${relpath}"
        else
            echo "[models] Re-downloading corrupted ${relpath}"
            rm -f "$store_file"
            download_file "$url" "$store_file"
            verify_sha256 "$store_file" "$expected_sha"
        fi
    else
        download_file "$url" "$store_file"
        verify_sha256 "$store_file" "$expected_sha"
    fi

    mkdir -p "$(dirname "$link_path")"
    ln -snf "$store_file" "$link_path"
done < "${MANIFEST}"

echo "[models] Done selector=${SELECTOR}"
