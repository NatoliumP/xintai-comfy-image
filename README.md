# xintai ComfyUI 容器镜像工程（基于 `vastai/comfy:v0.43.0-cuda-13.2-py312`）

复刻原 `xintai` Vast.ai 实例环境，底层继承官方 `vastai/comfy:v0.43.0-cuda-13.2-py312`。

## 1. 环境对照

- **基础镜像**: `vastai/comfy:v0.43.0-cuda-13.2-py312`
  - ComfyUI `0.43.0` / Frontend `1.57.4` / Python `3.12.15` / PyTorch `2.10.0+cu130`（兼容 Blackwell RTX 5060 Ti / 5070 Ti `sm_120`）
  - 预置 `ComfyUI-Manager`、`comfyui-workflow-to-api-converter-endpoint`、`v1-5-pruned-emaonly-fp16.safetensors`
  - Supervisor (`18188`) + Caddy (`8188` -> `18188`、`8288` -> API Wrapper `18288`、`1111` -> Portal、`8384` -> Syncthing) + Jupyter (`8080`)
- **默认启动参数 (`COMFYUI_ARGS`)**:
  `--disable-auto-launch --disable-xformers --port 18188 --enable-cors-header`
- **新增 13 个 Custom Nodes**（加上基础镜像预置 2 个，共 15 个）：
  见 [custom_nodes.txt](custom_nodes.txt)。安装时保留基础镜像 `torch` 生态版本，通过 `sam2` `--no-build-isolation` + `SAM2_BUILD_CUDA=0` 避免重下 Torch，并在构建尾声运行 `main.py --cpu --quick-test-for-ci`。
- **模型存储规范（遵循 Vast.ai `/opt/model_store` + symlink 机制）**：
  - 所有大模型与 LoRA 存放在 `/opt/model_store/`，并软链到 `/opt/workspace-internal/ComfyUI/models/`。
  - 启动阶段 `/etc/vast_boot.d/38-xintai-sync.sh` 在 Supervisor 启动 ComfyUI 前运行，即使复用已有 `/workspace` 数据卷也会自动补齐软链和工作流。

## 2. 构建模式（`BAKE_MODELS` 与 `LORA_PROFILE`）

| 参数 | 可选值 | 说明 | 预估成品体积 |
| --- | --- | --- | --- |
| `BAKE_MODELS` | `slim` | 仅打入 15 个插件 + LoRA + 工作流；首次启动可用 `FETCH_MODEL_PROFILE=anima\|full` 自动下载模型 | ~11 GB |
| `BAKE_MODELS` | `anima` *(默认)* | 内置 3 个 Anima 底模 (`turbo-v1.1`/`aesthetic-v1.1`/`base-v1.0`) + `qwen_3_06b_base` + `qwen_image_vae` + `RealESRGAN_x4plus_anime_6B` + LoRA | ~22 GB |
| `BAKE_MODELS` | `full` | 在 `anima` 基础上再内置 `NoobAI-XL-v1.1` (7.1 GB) + 2 个 SDXL ControlNet (5.0 GB)，1:1 完整复刻 | ~34 GB |
| `LORA_PROFILE` | `all` *(默认)* | `xintai` 原 12 个 LoRA + `xintai_anan` 新增 2 个触手 LoRA（共 14 个，约 1.64 GB） | +1.6 GB |
| `LORA_PROFILE` | `xintai12` | 严格只打入原 `xintai` 机器上的 12 个 LoRA | +1.5 GB |
| `LORA_PROFILE` | `anima` | 仅 Anima 架构 LoRA（共 11 个，去掉 3 个 SDXL/SD1.5 LoRA） | +1.1 GB |
| `LORA_PROFILE` | `none` | 不打入本地 LoRA（配合 GitHub 无二进制推送，或再传 `LORA_BUNDLE_URL`） | +0 GB |

## 3. 构建方式（本机 Windows 无 Docker，需在 Linux / GitHub Actions 构建）

### 方式 A：传到有 Docker / 大磁盘的 Linux 云主机构建（推荐 `anima` 或 `full`）

```bash
# 示例：打包上传本目录后在 Linux 机器执行
TAG=docker.io/<your-user>/xintai-comfy:v0.43.0-anima \
BAKE_MODELS=anima \
LORA_PROFILE=all \
PUSH=1 \
bash build.sh
```

若使用国内机房拉 PyPI/HF 较慢，可加 `USE_CN_MIRRORS=1`。主机如使用 Buildah 1.33，脚本会自动带上 `--storage-driver vfs --isolation chroot --format docker`。

### 方式 B：使用 GitHub Actions (`.github/workflows/build.yml`)

GitHub 免费 `ubuntu-latest` runner 清理后可用磁盘约 35–42 GB，工作流默认选用 `bake_models=slim` + `default_fetch_profile=anima`（若磁盘足够也可选 `anima`）：
- 工作流会自动把 `ghcr.io` 仓库名转为全小写，并支持从私有仓库 Release **`v1-loras`** 自动下载 14 个 LoRA（若不存在亦可传入外部 `lora_bundle_url` 或改选 `lora_profile=none`）。
- 构建产物默认推送至 `ghcr.io/<owner>/xintai-comfy`。

## 4. Vast.ai 运行配置建议

- **Docker Image**: `<your-registry>/xintai-comfy:v0.43.0-anima`
- **Launch Mode**: Run interactive shell / Jupyter + SSH（或默认 Vast entrypoint）
- **暴露端口**: `8188` (ComfyUI)、`8288` (API Wrapper)、`8080` (Jupyter)、`1111` (Portal)
- **环境变量**:
  - `COMFYUI_ARGS`: `--disable-auto-launch --disable-xformers --port 18188 --enable-cors-header`（已设默认）
  - `FETCH_MODEL_PROFILE`: `none`（若用 `slim` 镜像则改为 `anima` 或 `full`；若用 `anima` 镜像想自动补全 NoobAI+ControlNet 也可改为 `full`）

## 5. 本地校验与容器上线测试

```bash
# 本地静态校验（检查换行符、节点清单、模型与 LoRA SHA256、工作流 JSON）
python smoke_test.py --offline --verify-hashes

# 容器启动后线上验收（通过 SSH 转发或内网访问 18188）
python smoke_test.py --url http://127.0.0.1:18188
```
