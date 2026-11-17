# Anima LoRA 测试报告 — xintai ComfyUI

- 生成时间：2026-11-17
- 服务器：`xintai`（`115.78.134.198:42239`，vast.ai 实例，RTX 5070 Ti 16GB）
- ComfyUI：`v0.43.0` / PyTorch `2.10.0+cu130` / CUDA `13.0`
- 远端输出目录：`/workspace/ComfyUI/output/lora_test/`
- 本地回传目录：`D:\comyia\anima_out\lora_test\`

---

## 一、共用参数（所有用例一致，只换 LoRA 栈与提示词）

| 项 | 值 |
| :--- | :--- |
| UNET 底模 | `anima-turbo-v1.1.safetensors` |
| Text Encoder | `qwen_3_06b_base.safetensors`（type: `stable_diffusion`） |
| VAE | `qwen_image_vae.safetensors` |
| 分辨率 | `768 x 1344`（9:16） |
| KSampler | `steps 32` / `cfg 4.5` / `euler_ancestral` / `linear_quadratic` / `denoise 1.0` |
| LoRA 挂载方式 | `LoraLoaderModelOnly` 串行链，只作用于 MODEL（不污染 CLIP） |

---

## 二、测试矩阵与结果

### case01 基线四件套（SFW）
- **LoRA**：`01-ba_anima` 0.75 → `d3dv` 0.60 → `baka` 0.45 → `anima3-photo-background-v3` 0.45
- **目的**：验证画风 + 2.5D 光影 + 皮肤哑光 + 写真背景四层叠加是否互相干扰
- **结果**：通过。`@d3d` 与 `game_cg` 触发词生效，背景呈现真实天台景深与黄昏渐变；`baka` 压住了塑料高光，肤色干净。晴海全部锚点到位（藏青贝雷帽、银白/桃粉双色及腰发、左侧独枚草绿四叶草发卡、锁骨下三叶草项链、青色敞口外套、白高领短毛衣、灰百褶裙、白棉袜黑乐福鞋）。
- **已知瑕疵**：出现两只纸杯（提示词限定「双手捧一只」，模型重复生成握持物），属提示词遵循问题，非 LoRA 故障。

### case02 16.5 NextGen V1（NSFW）
- **LoRA**：`01-ba_anima` 0.65 → `d3dv` 0.55 → `baka` 0.45 → `16.5 NextGen V1` 0.75
- **目的**：验证无触发词 NSFW 画风 LoRA 在 0.75 权重的表现力与提示词遵循度
- **结果**：通过。`16.5 NextGen` 明显提升了照明鲜艳度与身体曲线解剖精度，服装位移动作（掀毛衣、掀裙）执行准确，角色锚点无漂移。

### case03 un.safetensors（私处细节）
- **LoRA**：`01-ba_anima` 0.65 → `d3dv` 0.55 → `baka` 0.45 → `un` 0.85
- **目的**：验证 `un` 在单人展示场景 0.7~1.0 区间的解剖细节强化，需 `vagina / vulva` 激活
- **结果**：通过。0.85 权重下皮肤与解剖细节明显强化，且未污染整体画风（v2.0 的降污染改动有效）。提示词中加入的 `vulva, detailed vagina and labia` 成功激活。

### case04 kanadera 角色 LoRA
- **LoRA**：`d3dv` 0.55 → `baka` 0.45 → `kanadera_anima-v2.0` 0.80
- **目的**：验证角色 LoRA 在 0.80 权重的角色还原度与服装复杂度承载能力
- **结果**：通过。触发词 `kanadera-maimai` 生效，红披风 + 橙内衬 + 金边、白衬衫灯笼袖 + 星星散布、星形帽饰压在左耳、白过膝袜金环、白靴黄底、彩虹耳机与电源插头电缆全部还原为一只手上的插头线。低权重下无画风过拟合。

### case05 Femboy_pantyhose（服饰概念）
- **LoRA**：`01-ba_anima` 0.70 → `d3dv` 0.55 → `baka` 0.45 → `Femboy_pantyhose_Anima_epoch_10` 0.85
- **目的**：验证 `femboy, pantyhose` 双触发词在 0.85 权重下的丝袜材质感，同时检验它与「垂耳兔少年」设定的冲突情况
- **结果**：通过。连裤袜呈现半透明尼龙光泽与贴合腿部轮廓，`femboy` 触发词压住了 `1girl` 倾向（负面提示词含 `1girl, female, pussy, vagina, breasts` 强化）。梓希的垂耳、银白长发、黑颈环四叶草吊坠、深藏青敞口风衣、白衬衫、浅蓝百褶裙、左大腿黑皮腿环全部保留。

---

## 三、权重可用区间复核（实测修正建议）

| LoRA | 手册推荐 | 实测结论 |
| :--- | :--- | :--- |
| `01-ba_anima` | 0.75 ~ 0.85 | 0.65~0.75 均可；0.75 已足够出画风，往 0.85 会轻微抢 `@d3d` 的光影层次 |
| `d3dv` | 0.50 ~ 0.70 | 0.55~0.60 最舒服，`@d3d` 必须写进正面提示词 |
| `bakaE79AAEE882A4.Md2S` | 0.40 ~ 0.60 | 0.45 是甜点值，可长期常驻 |
| `anima3-photo-background-v3` | 0.40 ~ 0.60 | 0.45 背景写实度刚好，再高会压角色线条 |
| `16.5 NextGen V1` | 0.70 ~ 0.80 | 0.75 合适，无需触发词 |
| `un` | 0.60 ~ 1.00 | 单人 0.85 效果最明显；多人交合场景建议降到 0.65~0.75 |
| `kanadera_anima-v2.0` | 0.70 ~ 0.90 | 0.80 还原度好，服装词要写全否则披风会残留 |
| `Femboy_pantyhose` | 0.70 ~ 1.00 | 0.85 质感到位，负面必须写全 `1girl, pussy, vagina, breasts` |

---

## 四、产出文件

| 文件 | 说明 |
| :--- | :--- |
| `workflow_anima_lora_test_ui.json` | 可拖入 ComfyUI 的 UI 工作流：UNET + CLIP + VAE 三个加载器，5 个 LoRA 串行槽（第 5 槽预置 `16.5 NextGen` 并以 `mode: 4` 旁路），晴海 SFW 提示词，32 步 KSampler，输出 `lora_test/manual` |
| `_batch_lora_test.json` | 5 组 API 批量任务，直接喂 `_anima_gen.py` |
| `_build_lora_test.py` | 生成上述两个文件的脚本（改 `CASES` 即可扩测试矩阵） |
| `anima_out/lora_test/*.png` | 5 张测试图本地副本 |

---

## 五、复现命令

```powershell
# 1) 隧道（远程 ComfyUI 只听 127.0.0.1:18188）
ssh -N -o StrictHostKeyChecking=no -o ServerAliveInterval=20 `
    -i E:\docs\aribot\rinato-vermidier\vn1 -p 42239 `
    -L 18188:127.0.0.1:18188 root@115.78.134.198

# 2) 重新生成工作流与 batch
python _build_lora_test.py

# 3) 跑批量生图
python _anima_gen.py _batch_lora_test.json

# 4) 回传（或用 /view 接口）
curl "http://127.0.0.1:18188/view?filename=01_baseline_ba_d3d_baka_photo_00001_.png&subfolder=lora_test&type=output" -o local.png
```

> 注意：`xintai` 是 vast.ai 竞价实例，重启后公网 IP 与端口会变，隧道命令里的 `115.78.134.198:42239` 需要按当前实例信息更新。
