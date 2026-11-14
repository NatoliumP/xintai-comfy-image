#!/usr/bin/env bash
set -euo pipefail

# Verify/install LoRAs in /opt/model_store/loras and symlink to /opt/workspace-internal/ComfyUI/models/loras.
# Usage: install_loras.sh <profile: none|xintai12|anima|all> <staging_dir> [bundle_url]
# When staging_dir == STORE_LORAS, avoids copying/moving files across Docker layers.

PROFILE="${1:-all}"
STAGING="${2:-/opt/model_store/loras}"
BUNDLE_URL="${3:-}"
MANIFEST="${STAGING}/manifest.tsv"
STORE_LORAS="${MODEL_STORE_DIR:-/opt/model_store}/loras"
LINK_LORAS="/opt/workspace-internal/ComfyUI/models/loras"

if [[ "${PROFILE}" == "none" ]]; then
    echo "[loras] LORA_PROFILE=none, removing staged files and skipping LoRA installation."
    rm -f "${STAGING}"/*.safetensors "${MANIFEST}"
    exit 0
fi

if [[ -n "${BUNDLE_URL}" ]]; then
    echo "[loras] Downloading LoRA bundle from ${BUNDLE_URL}..."
    mkdir -p "${STAGING}"
    bundle_tmp="/tmp/lora_bundle"
    curl -fSL --retry 5 --retry-delay 3 -o "${bundle_tmp}" "${BUNDLE_URL}"
    case "${BUNDLE_URL}" in
        *.zip)
            python -c "import zipfile, sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "${bundle_tmp}" "${STAGING}"
            ;;
        *)
            tar -xf "${bundle_tmp}" -C "${STAGING}"
            ;;
    esac
    rm -f "${bundle_tmp}"
fi

mkdir -p "${STORE_LORAS}" "${LINK_LORAS}"

want_lora() {
    local tags="$1"
    case "${PROFILE}" in
        all)
            return 0
            ;;
        xintai12)
            [[ ",${tags}," == *,xintai12,* ]]
            ;;
        anima)
            [[ ",${tags}," == *,anima,* ]]
            ;;
        *)
            echo "[loras] ERROR: Unknown LORA_PROFILE='${PROFILE}'" >&2
            return 1
            ;;
    esac
}

installed=0
while IFS='|' read -r tags expected_sha fn; do
    tags="$(printf '%s' "$tags" | tr -d '\r')"
    expected_sha="$(printf '%s' "$expected_sha" | tr -d '\r')"
    fn="$(printf '%s' "$fn" | tr -d '\r')"
    [[ -z "$tags" || "$tags" == \#* ]] && continue

    src="$(find "${STAGING}" -type f -name "${fn}" -print -quit || true)"

    if ! want_lora "$tags"; then
        [[ -n "${src}" ]] && rm -f "${src}"
        continue
    fi

    if [[ -z "${src}" ]]; then
        echo "[loras] ERROR: Required LoRA '${fn}' (profile=${PROFILE}) not found in ${STAGING}." >&2
        echo "[loras] Put .safetensors in ./loras/ before build, pass LORA_BUNDLE_URL, or set LORA_PROFILE=none." >&2
        exit 1
    fi

    actual_sha="$(sha256sum "${src}" | awk '{print $1}')"
    if [[ "${actual_sha}" != "${expected_sha}" ]]; then
        echo "[loras] ERROR: SHA256 mismatch for ${fn}: expected=${expected_sha} actual=${actual_sha}" >&2
        exit 1
    fi

    dest="${STORE_LORAS}/${fn}"
    if [[ "${src}" != "${dest}" ]]; then
        mv -f "${src}" "${dest}"
    fi
    ln -snf "${dest}" "${LINK_LORAS}/${fn}"
    installed=$((installed + 1))
done < "${MANIFEST}"

rm -f "${MANIFEST}"
echo "[loras] Verified and linked ${installed} LoRA(s) for profile=${PROFILE}."
