#!/usr/bin/env bash
set -euo pipefail

# Build helper for Linux/cloud Docker or Buildah 1.33 hosts.
# Examples:
#   TAG=ghcr.io/youruser/xintai-comfy:v0.43.0-anima-turbo ./build.sh
#   BAKE_MODELS=full TAG=docker.io/youruser/xintai-comfy:v0.43.0-full PUSH=1 ./build.sh
#   USE_CN_MIRRORS=1 BAKE_MODELS=anima TAG=youruser/xintai-comfy:latest ./build.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

TAG="${TAG:-xintai-comfy:v0.43.0-cuda13.2-py312-anima-turbo}"
BAKE_MODELS="${BAKE_MODELS:-anima-turbo}"
LORA_PROFILE="${LORA_PROFILE:-all}"
LORA_BUNDLE_URL="${LORA_BUNDLE_URL:-}"
DEFAULT_FETCH_PROFILE="${DEFAULT_FETCH_PROFILE:-none}"
USE_CN_MIRRORS="${USE_CN_MIRRORS:-0}"
PUSH="${PUSH:-0}"

HF_ENDPOINT_ARG="${HF_ENDPOINT_ARG:-https://huggingface.co}"
PIP_INDEX_URL_ARG="${PIP_INDEX_URL_ARG:-}"

if [[ "${USE_CN_MIRRORS}" == "1" ]]; then
    HF_ENDPOINT_ARG="https://hf-mirror.com"
    PIP_INDEX_URL_ARG="https://pypi.tuna.tsinghua.edu.cn/simple"
fi

BUILD_ARGS=(
    --build-arg "BAKE_MODELS=${BAKE_MODELS}"
    --build-arg "LORA_PROFILE=${LORA_PROFILE}"
    --build-arg "LORA_BUNDLE_URL=${LORA_BUNDLE_URL}"
    --build-arg "DEFAULT_FETCH_PROFILE=${DEFAULT_FETCH_PROFILE}"
    --build-arg "HF_ENDPOINT_ARG=${HF_ENDPOINT_ARG}"
    --build-arg "PIP_INDEX_URL_ARG=${PIP_INDEX_URL_ARG}"
    -t "${TAG}"
)

if command -v docker >/dev/null 2>&1; then
    echo "[build] Using docker with tag=${TAG}, BAKE_MODELS=${BAKE_MODELS}, LORA_PROFILE=${LORA_PROFILE}"
    docker build "${BUILD_ARGS[@]}" .
    if [[ "${PUSH}" == "1" ]]; then
        docker push "${TAG}"
    fi
elif command -v buildah >/dev/null 2>&1; then
    echo "[build] Using buildah vfs with tag=${TAG}, BAKE_MODELS=${BAKE_MODELS}, LORA_PROFILE=${LORA_PROFILE}"
    buildah --storage-driver vfs bud \
        --layers \
        --isolation chroot \
        --format docker \
        --network host \
        --security-opt seccomp=unconfined \
        "${BUILD_ARGS[@]}" .
    if [[ "${PUSH}" == "1" ]]; then
        buildah --storage-driver vfs push "${TAG}" "docker://${TAG}"
    fi
else
    echo "[build] ERROR: Neither docker nor buildah found in PATH." >&2
    exit 1
fi
