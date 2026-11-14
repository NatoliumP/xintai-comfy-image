#!/usr/bin/env bash
set -euo pipefail

# Executed as a child process from /etc/vast_boot.d/38-xintai-sync.sh
# Runs after 36-sync-workspace.sh and before 65-supervisor-launch.sh.

WORKSPACE_DIR="${WORKSPACE:-/workspace}"
COMFY_DIR="${WORKSPACE_DIR}/ComfyUI"
INTERNAL_COMFY="/opt/workspace-internal/ComfyUI"
STORE_DIR="${MODEL_STORE_DIR:-/opt/model_store}"
FETCH_PROFILE="${FETCH_MODEL_PROFILE:-none}"

mkdir -p "${COMFY_DIR}/models" "${COMFY_DIR}/user/default/workflows"

# Optional boot-time model fetch (e.g. for slim builds or pulling NoobAI/ControlNets)
case "${FETCH_PROFILE}" in
    none|"")
        ;;
    anima|full|sdxl_ckpt|sdxl_cn|core|diffusion)
        if [[ ! -f "${COMFY_DIR}/.xintai_fetched_${FETCH_PROFILE}" ]]; then
            echo "[xintai-sync] Fetching missing models for profile=${FETCH_PROFILE}..."
            /opt/xintai/download_models.sh "${FETCH_PROFILE}" "${COMFY_DIR}/models"
            touch "${COMFY_DIR}/.xintai_fetched_${FETCH_PROFILE}"
        fi
        ;;
    *)
        echo "[xintai-sync] WARNING: Unknown FETCH_MODEL_PROFILE='${FETCH_PROFILE}', skipping." >&2
        ;;
esac

# Ensure every model & LoRA in /opt/model_store is symlinked into active workspace ComfyUI/models/
# Safe when /workspace is backed by a reused persistent volume where 36-sync-workspace.sh skipped copying ComfyUI.
if [[ -d "${STORE_DIR}" ]]; then
    while IFS= read -r -d '' src; do
        rel="${src#${STORE_DIR}/}"
        dst="${COMFY_DIR}/models/${rel}"
        mkdir -p "$(dirname "${dst}")"
        if [[ ! -e "${dst}" && ! -L "${dst}" ]]; then
            ln -s "${src}" "${dst}"
        fi
    done < <(find "${STORE_DIR}" -type f -print0)
fi

# Ensure baked custom_nodes are linked if workspace ComfyUI predates this image
if [[ -d "${INTERNAL_COMFY}/custom_nodes" ]]; then
    mkdir -p "${COMFY_DIR}/custom_nodes"
    for node in "${INTERNAL_COMFY}/custom_nodes"/*; do
        [[ -e "${node}" ]] || continue
        name="$(basename "${node}")"
        if [[ ! -e "${COMFY_DIR}/custom_nodes/${name}" ]]; then
            cp -a "${node}" "${COMFY_DIR}/custom_nodes/${name}"
        fi
    done
fi

# Copy baked workflows without clobbering user edits
if [[ -d "${INTERNAL_COMFY}/user/default/workflows" ]]; then
    for wf in "${INTERNAL_COMFY}/user/default/workflows"/*.json; do
        [[ -f "${wf}" ]] || continue
        cp -n "${wf}" "${COMFY_DIR}/user/default/workflows/"
    done
fi
