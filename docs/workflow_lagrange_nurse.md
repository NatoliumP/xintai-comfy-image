# 工作流：Lagrange × 粉色护士服 NSFW 换装

- 服务器：`xintai` ComfyUI（RTX 5070 Ti）
- 角色：Arcaea ラグランジュ（`arcaea-lagrange-ANIMA-000022.safetensors`）
- 产出：`anima_out/lagrange_nurse_v2/`（v2 定稿）、`anima_out/lagrange_nurse/`（v1 对照）

---

## 一、文件清单

| 文件 | 说明 |
| :--- | :--- |
| `workflow_lagrange_nurse_ui.json` | **主工作流**，拖进 ComfyUI 即可用（默认 case01 配置） |
| `_batch_lagrange_nurse.json` | 4 组 API 批量任务 |
| `_build_nurse_wf.py` | 生成器，改 `CASES` 加新姿势 / 改 `NURSE_OUTFIT` 换装 |
| `lora_lagrange_arcaea.md` | 角色本体触发词档案 |

---

## 二、工作流结构（13 节点）

```
UNETLoader (anima-turbo-v1.1)
        │
        ├─ LoraLoaderModelOnly ① d3dv 0.55          ┐
        ├─ LoraLoaderModelOnly ② baka (skin) 0.45    │ 串行链
        ├─ LoraLoaderModelOnly ③ Lagrange 0.78       │ 只作用于 MODEL
        └─ LoraLoaderModelOnly ④ un 0.70            ┘
                    │
                    ▼
              KSampler ◄── CLIPTextEncode 正面（护士服 + NSFW）
                    │    ◄── CLIPTextEncode 负面（压原装 + 锁锚点）
                    │    ◄── EmptySD3LatentImage 768×1344
                    ▼
              VAEDecode ◄── VAELoader (qwen_image_vae)
                    ▼
              SaveImage → lagrange_nurse/manual
```

**关键设定**
- 底模 `anima-turbo-v1.1` / CLIP `qwen_3_06b_base`（`stable_diffusion`）/ VAE `qwen_image_vae`
- `steps 32` / `cfg 4.5` / `euler_ancestral` + `linear_quadratic`
- **Lagrange 权重 0.78**（低于角色基准 0.80，给换装留出服装位移空间；高于 0.82 会把原装黄紫裙拉回来）
- **不叠 `01-ba_anima`**（0.70 会把紫瞳染成蓝眼）
- **不叠 `16.5 NextGen`**（抢紫色饱和度）

---

## 三、提示词四段拆解

### 1. 本体锚点（`LAGRANGE_ANCHOR`，换任何装都不删）
```
lagrange-arcaea, 1girl, solo,
lavender hair, very long hair, large braid adorned with thin chains,
purple bows at the braid's end, purple bows on her side locks,
a single purple-and-white eight-pointed star hair ornament on her bangs,
sharp pointed eight-pointed star shape, star pointed outward,
choppy bangs,
purple eyes, violet eyes, purple iris, both eyes purple,
monocle over one eye with thin gold chain,
purple band wrapped around her wrist,
single small purple robotic companion beside her
```

> ⚠️ 这里**不能用原触发词 `octagram`**。在护士/医疗题材下，`octagram` 会被模型同化成医疗十字图标（v1 四张全中）。改写为 `eight-pointed star` 才压得住。

> ⚠️ `both eyes purple` 必须写。不写的话，`monocle` 那一侧的瞳色容易被单片眼镜的金属高光带偏成蓝色/异色瞳。

### 2. 护士服主体（`NURSE_OUTFIT`）
```
pink nurse uniform, short pink nurse dress,
white frilled nurse apron,
white nurse cap with a small pink cross emblem on the cap only,
pink puff short sleeves with white frilled cuffs,
pink ribbon bow at the collar,
stethoscope hanging around her neck,
white lace-trimmed thighhighs on both legs,
white thighhighs clearly visible under the raised skirt,
pink and white nurse pumps
```

> `on the cap only` 很关键：把十字限死在帽子上，避免扩散到发饰。
> 丝袜写 `thighhighs` + `lace-trimmed`，别写 `from hip to toe`（会和 thighhighs 语义打架，出成短袜或裸足）。

### 3. 原装压制（`ORIGINAL_SUPPRESS`，进负面）
```
yellow-and-purple layered dress, layered dress, yellow skirt,
white outer pinafore dress, pinafore,
purple cape, light purple cape, shoulder cape, cape with purple edges,
cape straps, pink ribbons tied across chest,
purple printed pantyhose, purple shoes
```
不写这段，LoRA 会把原本的黄紫分层裙 + 白罩裙 + 紫披风强行画回来，跟护士服搅成一团。

### 4. NSFW 段（按姿势替换）
四个变体已内置：

| 变体 | 核心 NSFW 锚点 | 场景 |
| :--- | :--- | :--- |
| `01_standing_open` | `nurse dress unbuttoned and pulled open at the front` / `small breasts exposed, pink nipples` / `apron lifted with one hand` / `no panties, shaved, exposed pussy` | 医院病房，窗光 |
| `02_sitting_spread` | `sitting on edge of examination bed` / `nurse dress pulled up around waist` / `legs spread wide in M-shape` / `pink labia spread apart, glistening wet` | 检查床 |
| `03_all_fours_rear` | `all fours on white bedsheets` / `from behind, ass focus` / `dress flipped up over lower back` / `exposed pussy and anus between thighs` | 卧室床 |
| `04_partial_strip` | `dress and apron slipped off both shoulders, bunched around elbows` / `cowboy shot, torso focus` | 诊所走廊，百叶窗光 |

---

## 四、v1 → v2 修正记录（同一 seed 对比）

| 问题 | v1 表现 | v2 修法 | v2 结果 |
| :--- | :--- | :--- | :--- |
| **八角星被同化成医疗十字** | 四张全中，头部一片十字 | `octagram` → `eight-pointed star`；负面加 `cross shaped hair ornament, cross hairpin, plus sign hair ornament, medical cross on hair` | ✅ 恢复星形 |
| **异色瞳**（case03 左眼变蓝） | 一只蓝一只紫 | 正面加 `both eyes purple`；负面加 `mismatched eyes, one blue eye, both eyes different colors` | ✅ 双紫瞳 |
| **丝袜出成短袜/裸足** | case03 脚部裸露 | `from hip to toe` → `lace-trimmed thighhighs` + `visible under the raised skirt`；负面加 `bare feet` | ✅ 蕾丝白丝统一 |
| **机械伙伴数量** | 首轮测 Lagrange 时出过两只 | `single small purple robotic companion` + 负面 `two companions, multiple companions, twin robots` | ✅ 稳定单只 |

---

## 五、已知瑕疵（可接受，附修法）

**发饰数量仍偏多（3~4 个星形）**
- 原装只有一枚八角星发饰，v2 画面里常出现 3~4 个分布在刘海两侧。
- 负面已有 `four hair ornaments, multiple hair ornaments`，但模型仍会重复。
- 想彻底压到一枚，可试：正面 `exactly one star ornament on the left side of bangs only`；负面再补 `symmetrical star ornament, star ornaments on both sides`；或把 Lagrange 权重降到 `0.75`。

**护士帽的十字有时不够明显**
- 需要更醒目时，正面改 `white nurse cap with a large pink cross on the front of the cap`。

---

## 六、换装扩展指引

改 `_build_nurse_wf.py` 里两处即可换任何服装：

1. **改 `NURSE_OUTFIT`** → 换成新服装描述（保留结构：主体 + 配件 + 腿部 + 鞋）
2. **改 `ORIGINAL_SUPPRESS`** → 把 LoRA 原装那套词继续留在负面（黄紫分层裙 / 白罩裙 / 紫披风 / 紫印花袜 / 紫鞋）
3. 需要新姿势时，在 `CASES` 里加一条，`positive` 用「LAGRANGE_ANCHOR + 新 NURSE_OUTFIT + 该姿势的 NSFW 锚点」拼接

**换装通用三条铁律**
- 角色 LoRA 权重压到 `0.75~0.78`，高于 `0.82` 会抢回原装
- 原装词必须全部写进负面，漏一个就被画回来
- 题材词会污染锚点（护士 = 十字），锚点要用更具体的形状词抵抗

---

## 七、复现

```powershell
# 隧道（IP/端口按当前 vast 实例更新）
ssh -N -o StrictHostKeyChecking=no -i E:\docs\aribot\rinato-vermidier\vn1 `
    -p 42239 -L 18188:127.0.0.1:18188 root@115.78.134.198

python _build_nurse_wf.py                              # 重建工作流 + batch
python _anima_gen.py _batch_lagrange_nurse.json        # 跑 4 组
```

> `xintai` 是 vast.ai 竞价实例，隧道会不定期掉线（本次中途断过一次）。复现前先 `curl http://127.0.0.1:18188/system_stats` 探活。
