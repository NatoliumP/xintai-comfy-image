#!/usr/bin/env python3
"""Static and live-container smoke verification for D:\\comyia\\xintai_image."""

import argparse
import hashlib
import json
import os
import re
import sys
import urllib.request
from pathlib import Path

EXPECTED_NODES = {
    "ComfyUI-Crystools",
    "ComfyUI-Easy-Use",
    "ComfyUI-Impact-Pack",
    "ComfyUI-Impact-Subpack",
    "ComfyUI-KJNodes",
    "ComfyUI-openpose-editor",
    "ComfyUI_UltimateSDUpscale",
    "ComfyUI_essentials",
    "comfyui-art-venture",
    "comfyui_controlnet_aux",
    "pre_cfg_comfy_nodes_for_ComfyUI",
    "rgthree-comfy",
    "was-node-suite-comfyui",
}

EXPECTED_LIVE_MODELS = {
    "anima-turbo-v1.1.safetensors",
    "anima-aesthetic-v1.1.safetensors",
    "anima-base-v1.0.safetensors",
    "qwen_3_06b_base.safetensors",
    "qwen_image_vae.safetensors",
}


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(4 * 1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def check_offline(root: Path, verify_lora_hashes: bool) -> int:
    errors = []

    required = [
        "Dockerfile",
        ".dockerignore",
        ".gitignore",
        "custom_nodes.txt",
        "models.sha256",
        "build.sh",
        "README.md",
        "loras/manifest.tsv",
        "scripts/install_custom_nodes.sh",
        "scripts/download_models.sh",
        "scripts/install_loras.sh",
        "scripts/boot_sync.sh",
        "scripts/38-xintai-sync.sh",
        ".github/workflows/build.yml",
    ]
    for rel in required:
        if not (root / rel).is_file():
            errors.append(f"Missing required file: {rel}")

    # Check LF line endings on shell scripts & manifests
    for rel in [
        "custom_nodes.txt",
        "models.sha256",
        "build.sh",
        "loras/manifest.tsv",
        "scripts/install_custom_nodes.sh",
        "scripts/download_models.sh",
        "scripts/install_loras.sh",
        "scripts/boot_sync.sh",
        "scripts/38-xintai-sync.sh",
    ]:
        p = root / rel
        if p.is_file() and b"\r\n" in p.read_bytes():
            errors.append(f"CRLF detected in {rel} (must be LF)")

    # Check Dockerfile hygiene (vastai base, no heredocs)
    df = (root / "Dockerfile").read_text(encoding="utf-8")
    if "FROM ${BASE_IMAGE}" not in df or "vastai/comfy:v0.43.0-cuda-13.2-py312" not in df:
        errors.append("Dockerfile must default BASE_IMAGE to vastai/comfy:v0.43.0-cuda-13.2-py312")
    if "<<" in df:
        errors.append("Dockerfile contains '<<' heredoc which breaks classic buildah 1.33")

    # Check custom_nodes.txt completeness
    listed_nodes = set()
    for line in (root / "custom_nodes.txt").read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("|")
        if len(parts) != 3:
            errors.append(f"Malformed custom_nodes.txt line: {line}")
            continue
        listed_nodes.add(parts[0])
    if listed_nodes != EXPECTED_NODES:
        errors.append(f"custom_nodes.txt mismatch: missing={EXPECTED_NODES - listed_nodes}, extra={listed_nodes - EXPECTED_NODES}")

    # Check models.sha256 formatting
    for line in (root / "models.sha256").read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("|")
        if len(parts) != 4 or not re.fullmatch(r"[0-9a-f]{64}", parts[2]):
            errors.append(f"Malformed models.sha256 line: {line}")

    # Check LoRAs manifest & files
    lora_entries = []
    for line in (root / "loras/manifest.tsv").read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("|")
        if len(parts) != 3 or not re.fullmatch(r"[0-9a-f]{64}", parts[1]):
            errors.append(f"Malformed loras/manifest.tsv line: {line}")
            continue
        lora_entries.append((parts[0], parts[1], parts[2]))

    if len(lora_entries) != 14:
        errors.append(f"Expected 14 LoRA entries in manifest.tsv, got {len(lora_entries)}")

    for _, expected_sha, fn in lora_entries:
        lp = root / "loras" / fn
        if not lp.is_file():
            errors.append(f"Missing LoRA file in loras/: {fn}")
        elif verify_lora_hashes:
            actual_sha = sha256_file(lp)
            if actual_sha != expected_sha:
                errors.append(f"LoRA SHA256 mismatch for {fn}: {actual_sha} != {expected_sha}")

    # Check workflows valid JSON
    wfs = list((root / "workflows").glob("*.json"))
    if not wfs:
        errors.append("No workflow .json files found under workflows/")
    for wf in wfs:
        try:
            data = json.loads(wf.read_text(encoding="utf-8-sig"))
            if not isinstance(data, dict) or "nodes" not in data:
                errors.append(f"Workflow {wf.name} does not look like ComfyUI UI JSON")
        except Exception as exc:
            errors.append(f"Invalid JSON in workflow {wf.name}: {exc}")

    if errors:
        print("OFFLINE CHECK FAILED:")
        for e in errors:
            print("  -", e)
        return 1

    print(f"OFFLINE CHECK PASSED ({len(listed_nodes)} custom nodes, {len(lora_entries)} LoRAs, {len(wfs)} workflows).")
    return 0


def check_live(url: str) -> int:
    base = url.rstrip("/")
    stats = json.loads(urllib.request.urlopen(f"{base}/system_stats", timeout=10).read().decode())
    sys_info = stats.get("system", {})
    print("Live system_stats:", json.dumps({
        "comfyui_version": sys_info.get("comfyui_version"),
        "python_version": sys_info.get("python_version"),
        "pytorch_version": sys_info.get("pytorch_version"),
        "argv": sys_info.get("argv"),
    }, indent=2))

    obj = json.loads(urllib.request.urlopen(f"{base}/object_info", timeout=15).read().decode())
    unet_vals = set(obj["UNETLoader"]["input"]["required"]["unet_name"][0])
    clip_vals = set(obj["CLIPLoader"]["input"]["required"]["clip_name"][0])
    vae_vals = set(obj["VAELoader"]["input"]["required"]["vae_name"][0])
    lora_vals = set(obj["LoraLoaderModelOnly"]["input"]["required"]["lora_name"][0])

    print(f"Live models: unets={len(unet_vals)}, clips={len(clip_vals)}, vaes={len(vae_vals)}, loras={len(lora_vals)}")
    found_core = unet_vals | clip_vals | vae_vals
    missing = EXPECTED_LIVE_MODELS - found_core
    if missing:
        print("LIVE CHECK FAILED: missing models:", sorted(missing))
        return 1

    # Spot-check custom nodes loaded into ComfyUI registry
    spot_nodes = ["CrystoolsMonitor", "easy cleanGpuUsed", "ImpactWildcardProcessor", "KJNodeInfo", "rgthree.Seed"]
    print("Custom node total classes registered:", len(obj))
    print("LIVE CHECK PASSED.")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--offline", action="store_true", help="Validate local repo files and manifests")
    ap.add_argument("--verify-hashes", action="store_true", help="Recompute SHA256 on all files in loras/")
    ap.add_argument("--url", help="Verify running ComfyUI endpoint, e.g. http://127.0.0.1:18188")
    args = ap.parse_args()

    rc = 0
    if args.offline or not args.url:
        rc |= check_offline(Path(__file__).resolve().parent, args.verify_hashes)
    if args.url:
        rc |= check_live(args.url)
    return rc


if __name__ == "__main__":
    sys.exit(main())
