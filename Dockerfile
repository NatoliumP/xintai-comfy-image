# Mirror of xintai Vast.ai ComfyUI environment built cleanly atop vastai/comfy:v0.43.0-cuda-13.2-py312
# Inherited from base image:
#   - Ubuntu + CUDA 13.2 + Python 3.12.15 (/venv/main) + PyTorch 2.10.0+cu130 (Blackwell sm_120)
#   - ComfyUI v0.43.0 + frontend 1.57.4 + ComfyUI-Manager + workflow-to-api-converter-endpoint
#   - Supervisor (/opt/supervisor-scripts/comfyui.sh :18188), Caddy (:8188 / :8288 / :1111 / :8384),
#     comfyui-api-wrapper (:18288), Jupyter (:8080), v1-5-pruned-emaonly-fp16.safetensors
#
# Build modes (ARG BAKE_MODELS):
#   slim   - Custom nodes + LoRAs + workflows only (~11 GB); fetch models on boot via FETCH_MODEL_PROFILE
#   anima  - Default: + Anima turbo/aesthetic/base + Qwen 3 0.6B + Qwen VAE + RealESRGAN (~22 GB)
#   full   - Exact 1:1 mirror including NoobAI-XL v1.1 + 2x SDXL ControlNets (~34 GB)

ARG BASE_IMAGE=vastai/comfy:v0.43.0-cuda-13.2-py312
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.description="ComfyUI v0.43.0 Anima + NoobAI workstation mirror on vastai/comfy:v0.43.0-cuda-13.2-py312"

# Runtime args kept minimal; do NOT embed private keys, tokens, or secrets.
ARG BAKE_MODELS=anima
ARG LORA_PROFILE=all
ARG LORA_BUNDLE_URL=
ARG DEFAULT_FETCH_PROFILE=none
ARG HF_ENDPOINT_ARG=https://huggingface.co
ARG PIP_INDEX_URL_ARG=

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONUNBUFFERED=1 \
    COMFYUI_ARGS="--disable-auto-launch --disable-xformers --port 18188 --enable-cors-header" \
    FETCH_MODEL_PROFILE="${DEFAULT_FETCH_PROFILE}"

# 1. Extra OS utilities needed for fast multi-connection downloads & OpenCV custom nodes
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        aria2 \
        ca-certificates \
        libgl1 \
        libglib2.0-0 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 2. Manifests, scripts, and boot sync hooks
COPY custom_nodes.txt models.sha256 /opt/xintai/
COPY scripts/ /opt/xintai/
RUN sed -i 's/\r$//' /opt/xintai/*.sh /opt/xintai/*.txt /opt/xintai/models.sha256 && \
    chmod +x /opt/xintai/*.sh && \
    cp /opt/xintai/38-xintai-sync.sh /etc/vast_boot.d/38-xintai-sync.sh && \
    chmod +x /etc/vast_boot.d/38-xintai-sync.sh

# 3. Install the 13 extra custom nodes into /opt/workspace-internal/ComfyUI/custom_nodes/
RUN PIP_INDEX_URL_ARG="${PIP_INDEX_URL_ARG}" \
    /opt/xintai/install_custom_nodes.sh /opt/xintai/custom_nodes.txt

# 4. Model layer A: Qwen text encoder + Qwen VAE + RealESRGAN anime 4x upscaler (~1.46 GB)
RUN if [ "${BAKE_MODELS}" = "anima" ] || [ "${BAKE_MODELS}" = "full" ]; then \
        HF_ENDPOINT="${HF_ENDPOINT_ARG}" /opt/xintai/download_models.sh core; \
    fi

# 5. Model layer B: Anima diffusion models (turbo-v1.1 + aesthetic-v1.1 + base-v1.0, ~12.5 GB)
RUN if [ "${BAKE_MODELS}" = "anima" ] || [ "${BAKE_MODELS}" = "full" ]; then \
        HF_ENDPOINT="${HF_ENDPOINT_ARG}" /opt/xintai/download_models.sh diffusion; \
    fi

# 6. Model layer C (full only): NoobAI-XL v1.1 checkpoint (~7.1 GB)
RUN if [ "${BAKE_MODELS}" = "full" ]; then \
        HF_ENDPOINT="${HF_ENDPOINT_ARG}" /opt/xintai/download_models.sh sdxl_ckpt; \
    fi

# 7. Model layer D (full only): SDXL ControlNets (~5.0 GB)
RUN if [ "${BAKE_MODELS}" = "full" ]; then \
        HF_ENDPOINT="${HF_ENDPOINT_ARG}" /opt/xintai/download_models.sh sdxl_cn; \
    fi

# 8. Install & SHA256-verify LoRAs in /opt/model_store/loras and symlink into workspace-internal
COPY loras/ /opt/model_store/loras/
RUN sed -i 's/\r$//' /opt/model_store/loras/manifest.tsv && \
    /opt/xintai/install_loras.sh "${LORA_PROFILE}" /opt/model_store/loras "${LORA_BUNDLE_URL}"

# 9. Saved ComfyUI UI workflows
COPY workflows/ /opt/workspace-internal/ComfyUI/user/default/workflows/

# 10. Refresh CA bundle and env hash per Vast.ai base-image convention
RUN /opt/instance-tools/lib/refresh-ca-data.sh && \
    env-hash > /.env_hash
