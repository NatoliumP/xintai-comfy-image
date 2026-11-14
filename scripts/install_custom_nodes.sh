#!/usr/bin/env bash
set -euo pipefail

NODES_FILE="${1:-/opt/xintai/custom_nodes.txt}"
COMFY_DIR="/opt/workspace-internal/ComfyUI"
CUSTOM_NODES_DIR="${COMFY_DIR}/custom_nodes"

. /venv/main/bin/activate

# Snapshot torch ecosystem before custom node installs to prevent silent ABI drift
torch_versions_pre="$({ pip list --format=freeze 2>/dev/null | grep -E '^(torch|torchvision|torchaudio|torchcodec|numpy)==' || :; } | sort)"
echo "[nodes] Pre-install packages:"
echo "${torch_versions_pre}"

# Write torch constraints so sam2 / transitive deps cannot override base PyTorch
pip list --format=freeze 2>/dev/null | grep -E '^(torch|torchvision|torchaudio|torchcodec)==' > /tmp/torch-constraints.txt || true

mkdir -p "${CUSTOM_NODES_DIR}"
cd "${CUSTOM_NODES_DIR}"

# Prevent Impact-Pack / Subpack from downloading extra SAM/YOLO models automatically if invoked
touch "${CUSTOM_NODES_DIR}/skip_download_model"

while IFS='|' read -r dir url recursive; do
    dir="$(printf '%s' "$dir" | tr -d '\r')"
    url="$(printf '%s' "$url" | tr -d '\r')"
    recursive="$(printf '%s' "$recursive" | tr -d '\r')"
    [[ -z "$dir" || "$dir" == \#* ]] && continue

    if [[ -d "${CUSTOM_NODES_DIR}/${dir}" ]]; then
        echo "[nodes] Already exists, skipping clone: ${dir}"
        continue
    fi

    echo "[nodes] Cloning ${dir} from ${url} (recursive=${recursive})"
    if [[ "${recursive}" == "1" ]]; then
        git clone --depth 1 --recursive --shallow-submodules "${url}" "${dir}"
    else
        git clone --depth 1 "${url}" "${dir}"
    fi
done < "${NODES_FILE}"

# Collect and sanitize requirements across all newly cloned nodes
COMBINED_REQ="/tmp/custom_nodes_requirements.txt"
: > "${COMBINED_REQ}"

for req_file in "${CUSTOM_NODES_DIR}"/*/requirements.txt; do
    [[ -f "$req_file" ]] || continue
    # Skip packages handled in base image or combined carefully below
    grep -vE '^\s*(#|$)' "$req_file" \
        | sed -E 's/\r$//' \
        | grep -vE '^(torch|torchvision|torchaudio|torchcodec)([[:space:]=<>!~]|$)' \
        | grep -vE '^onnxruntime([[:space:]=<>!~]|$)' \
        | grep -vE '^git\+https://github\.com/facebookresearch/sam2' \
        >> "${COMBINED_REQ}" || true
done

if [[ -n "${PIP_INDEX_URL_ARG:-}" ]]; then
    export UV_INDEX_URL="${PIP_INDEX_URL_ARG}"
fi

echo "[nodes] Installing combined node requirements via uv..."
uv pip install --no-cache-dir -c /tmp/torch-constraints.txt -r "${COMBINED_REQ}"

# Install SAM2 cleanly without triggering isolated torch download or nvcc compilation on runtime base
if grep -rq 'facebookresearch/sam2' "${CUSTOM_NODES_DIR}"/*/requirements.txt 2>/dev/null; then
    echo "[nodes] Installing facebookresearch/sam2 (--no-build-isolation, SAM2_BUILD_CUDA=0)..."
    SAM2_BUILD_CUDA=0 SAM2_BUILD_ALLOW_ERRORS=1 \
        uv pip install --no-cache-dir --no-build-isolation -c /tmp/torch-constraints.txt \
        "git+https://github.com/facebookresearch/sam2"
fi

# Verify torch + torchvision + torchaudio + torchcodec were NOT drifted
torch_versions_post="$({ pip list --format=freeze 2>/dev/null | grep -E '^(torch|torchvision|torchaudio|torchcodec)==' || :; } | sort)"
torch_pre_only="$({ printf '%s\n' "${torch_versions_pre}" | grep -E '^(torch|torchvision|torchaudio|torchcodec)==' || :; } | sort)"
if [[ "${torch_pre_only}" != "${torch_versions_post}" ]]; then
    echo "[nodes] ERROR: PyTorch ecosystem version drift detected!" >&2
    diff -u <(printf '%s\n' "${torch_pre_only}") <(printf '%s\n' "${torch_versions_post}") >&2 || true
    exit 1
fi

# Patch comfyui-art-venture load_module so it reuses already-loaded custom nodes in sys.modules
# instead of re-executing them under a different module name (which duplicates PromptServer routes).
ART_VENTURE_UTILS="${CUSTOM_NODES_DIR}/comfyui-art-venture/modules/utils.py"
if [[ -f "${ART_VENTURE_UTILS}" ]]; then
    python - "${ART_VENTURE_UTILS}" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
src = path.read_text(encoding="utf-8")
marker = "# patched: reuse sys.modules to avoid duplicate custom_node routes"
if marker in src:
    print(f"[nodes] {path} already patched")
    raise SystemExit(0)

old_block = """def load_module(module_path, module_name=None):
    import importlib.util

    if module_name is None:
        module_name = os.path.basename(module_path)
        if os.path.isdir(module_path):
            module_path = os.path.join(module_path, "__init__.py")

    module_spec = importlib.util.spec_from_file_location(module_name, module_path)

    module = importlib.util.module_from_spec(module_spec)
    module_spec.loader.exec_module(module)

    return module"""

new_block = """def load_module(module_path, module_name=None):
    import importlib.util
    # patched: reuse sys.modules to avoid duplicate custom_node routes
    orig_path = os.path.abspath(module_path)
    if module_name is None:
        if os.path.isdir(orig_path):
            module_name = orig_path.replace(".", "_x_")
            module_path = os.path.join(orig_path, "__init__.py")
        else:
            module_name = os.path.splitext(orig_path)[0]
    elif os.path.isdir(orig_path):
        module_path = os.path.join(orig_path, "__init__.py")

    target_real = os.path.realpath(module_path)
    existing = sys.modules.get(module_name)
    if existing is None:
        for mod in list(sys.modules.values()):
            mod_file = getattr(mod, "__file__", None)
            if mod_file and os.path.realpath(mod_file) == target_real:
                existing = mod
                break
    if existing is not None:
        return existing

    module_spec = importlib.util.spec_from_file_location(module_name, module_path)

    module = importlib.util.module_from_spec(module_spec)
    sys.modules[module_name] = module
    module_spec.loader.exec_module(module)

    return module"""

if old_block not in src:
    raise SystemExit(f"[nodes] ERROR: expected load_module block not found in {path}")

path.write_text(src.replace(old_block, new_block, 1), encoding="utf-8")
print(f"[nodes] Patched {path} (load_module deduplication)")
PY
fi

rm -f "${CUSTOM_NODES_DIR}/skip_download_model" /tmp/torch-constraints.txt "${COMBINED_REQ}"

echo "[nodes] Running ComfyUI CI quick smoke test..."
cd "${COMFY_DIR}"
LD_PRELOAD=libtcmalloc_minimal.so.4 \
    python main.py \
        --cpu \
        --listen 127.0.0.1 \
        --port 11404 \
        --disable-auto-launch \
        --quick-test-for-ci
