# LoRA 档案：Lagrange（Arcaea / ラグランジュ）

> 本文件由用户上传的 Civitai 触发词说明整理而成，作为 `arcaea-lagrange-ANIMA-000022.safetensors` 的常驻参考。
> 原始来源文字见 `lora_lagrange_arcaea_source.txt` 之外的截图，此处为结构化提炼。

---

## 一、模型基本信息

| 项 | 值 |
| :--- | :--- |
| 文件名 | `arcaea-lagrange-ANIMA-000022.safetensors` |
| 架构 | Anima（`networks.lora_anima`），适配 `anima-base-v1.0` / `anima-turbo-v1.1` / `anima-aesthetic-v1.1` |
| 文件体积 | 331 MB（明显大于 kanadera 43.9 MB，训练充分度偏高） |
| 部署位置 | 远端 `/workspace/ComfyUI/models/loras/`（软链自 `/opt/model_store/loras/`） |
| 角色出处 | Arcaea — ラグランジュ（Lagrange） |
| **主触发词** | `lagrange-arcaea` |
| 推荐权重 | `0.75 ~ 0.85`（起手 0.80） |

---

## 二、触发词与外貌锚点（原文结构化）

### Head — 头部
```
lavender hair
large braid adorned with thin chains
purple bows at the braid's end
purple bows on her side locks
purple-and-white octagram hair ornament
choppy bangs
purple eyes
monocle
```

### Body — 上身与服饰
```
pink ruffled collar with purple edges
purple bow at the collar
yellow-and-purple layered dress with straps
white outer pinafore dress with purple bow at the center
bare shoulders
light purple cape with purple edges on one shoulder
cape has purple straps
cape tied with pink ribbons across her chest
ribbons feature a purple-and-white octagram decoration
purple band wrapped around her wrist
```

### Lower Body — 下身
```
purple printed pantyhose
purple shoes
```

### Others — 其他
```
（NOT RECOMMEND）special emblem printed on the cape   ← 原作者明确不建议使用
small purple robotic companion beside her
```

---

## 三、可直接使用的提示词模板

### 1. SFW 全身（站姿基准）
```text
masterpiece, best quality, best aesthetics, ultra detailed illustration,
@d3d, game_cg, photo_background, cinematic lighting,
lagrange-arcaea, 1girl, solo, androgynous girl,
lavender hair, very long hair, large braid adorned with thin chains,
purple bows at the braid's end, purple bows on her side locks,
purple-and-white octagram hair ornament, choppy bangs,
purple eyes, monocle,
pink ruffled collar with purple edges, purple bow at the collar,
yellow-and-purple layered dress with straps, white outer pinafore dress,
purple bow at the center of the pinafore, bare shoulders,
light purple cape with purple edges draped on one shoulder,
purple cape straps, pink ribbons tied across her chest,
purple-and-white octagram decoration on the ribbons,
purple band wrapped around her wrist,
purple printed pantyhose, purple shoes,
small purple robotic companion beside her,
standing in a bright open plaza, clear daylight,
full body, vertical composition, 9:16
```

### 2. SFW 半身特写（验头部锚点）
把上面第 1 节替换为：
```text
upper body, portrait, close-up on face,
looking at viewer, calm expression,
soft window light, shallow depth of field
```
并删除 `full body, vertical composition`，其余锚点保留。

### 3. NSFW（保留服饰锚点）
私密场景建议保留：`monocle`、`purple-and-white octagram hair ornament`、`light purple cape`、`purple cape straps`、`purple printed pantyhose`、`purple shoes`；躯干部分按需调整 `yellow-and-purple layered dress`、`white outer pinafore dress` 的位移状态，并追加 `explicit, uncensored`。

### 4. 成品负面提示词
```text
emblem printed on cape, printed pattern on cape, logo on cape,
two braids, multiple braids, short hair, bob cut,
blonde hair, pink hair, white hair, black hair,
blue eyes, red eyes, green eyes, heterochromia,
no monocle, bare head, hat, beret,
frilled skirt, kimono, school uniform,
1boy, male, manly, muscular, multiple girls, 2girls,
censored, mosaic censoring, bar censor,
worst quality, low quality, score_1, score_2, score_3,
lowres, blurry, jpeg artifacts, bad anatomy, bad hands, extra digits,
watermark, text, signature, border, cropped
```

---

## 四、使用要点

1. **`lagrange-arcaea` 必须写**，且建议放在锚点最前，紧跟画质词之后。
2. **`monocle` 是易丢项**：权重低于 0.7 时单片眼镜常与眼睛融合成普通眼睛，建议 0.78~0.85。
3. **斗篷只在单肩**：要显式写 `draped on one shoulder` / `on one shoulder`，否则容易生成双侧对称披风。
4. **`(NOT RECOMMEND)` 的 cape emblem 不要写进正面**，同时把 `emblem printed on cape, printed pattern on cape, logo on cape` 写进负面。
5. **紫色系偏多**（发、蝴蝶结、斗篷、袜、鞋），若整体发紫发闷，可加 `photo_background` 与 `cinematic lighting` 提亮，或把 `01-ba_anima` 拉到 0.70 补青透感。
6. **配对 LoRA**：`d3dv` 0.55 + `baka` 0.45 作为常驻底层，不建议叠 `16.5 NextGen`（会抢紫色饱和度）。

---

## 五、测试记录（2026-11-17 首次实测，4 张全绿）

产出图：`anima_out/lagrange_test/`；远端 `/workspace/ComfyUI/output/lagrange_test/`；
批量配置：`_batch_lagrange_test.json`。

### 用例与结果

| # | 用例 | 权重 | 分辨率 | 结果 |
| :--- | :--- | :--- | :--- | :--- |
| 01 | SFW 全身 · 白色广场 + 蓝天 | 0.80 | 768×1344 | 通过 |
| 02 | SFW 半身特写 · 验 monocle | 0.85 | 896×1152 | 通过（monocle 完美） |
| 03 | NSFW 卧床 · 叠 `un` 0.70 | 0.80 | 768×1344 | 通过 |
| 04 | SFW 蓝档案清透画风 · 叠 `01-ba` 0.70 | 0.80 | 768×1344 | 通过（画风生效，代价见下） |

### 还原度确认（全部稳稳落地）

- 薰衣草紫发 + 饰细链粗编辫 + 辫尾紫大蝴蝶结 ✅
- 侧发紫蝴蝶结（左右各一）✅
- 紫白八角星发饰 ✅
- 紫眼 + **单片眼镜（金边带细链）** ✅ 0.80 以上就不会丢
- 粉荷叶边领 + 紫边 + 领口紫蝴蝶结 ✅
- 黄紫分层连衣裙 + 白罩裙 + 中央紫蝴蝶结 + 露肩 ✅
- 浅紫单肩披风（未出现双侧对称）✅
- 粉缎带交叉束胸 + 八角星饰扣 + 紫腕带 ✅
- 紫印花连裤袜 + 紫鞋 ✅

### 实测踩到的 4 个坑与修法

**1. 机械伙伴数量失控（case01 出了两只）**
- 正面加 `single small purple robotic companion`，负面加 `two companions, multiple companions, twin robots`。

**2. `01-ba_anima` 0.70 会把紫瞳染成蓝眼（case04）**
- 蓝档案的清透画风与 `purple eyes` 直接冲突。
- 修法：`01-ba_anima` 降到 `0.60`；或把 `blue eyes, azure eyes, cyan eyes` 塞进负面；或直接在正面写 `violet eyes (#9B72C8), purple iris`。

**3. 披风 emblem 反复出现（case01/04 的披风上有八角星图案与下摆吊坠）**
- 原文标注 `(NOT RECOMMEND)`，但负面 `emblem printed on cape, printed pattern on cape, logo on cape` 压不干净。
- 加强版负面：`pattern on cape, star pattern on cape, printed stars on cape, ornament dangling from cape hem, cape with print`。
- 或直接把披风写成素面：`plain unprinted light purple cape with purple edges`。

**4. NSFW 场景里「连裤袜」被画成过膝袜（case03）**
- 裙摆位移后模型倾向于只画可见段。
- 修法：正面写 `full-length pantyhose covering entire legs from waist to toes, sheer nylon texture from hip to ankle`，负面补 `thighhighs, kneehighs, socks, stocking tops`.

### 权重定稿建议

| 场景 | 建议权重 | 备注 |
| :--- | :--- | :--- |
| SFW 全身 / 风景 | `0.80` | 服饰锚点足够稳 |
| 头部特写 | `0.85` | 保 monocle 与八角星饰 |
| NSFW | `0.78 ~ 0.80` | 再高会连带锁死服装位移 |
| 叠 `01-ba_anima` | lagrange `0.80` + ba `0.60` | 防蓝眼 |
| 叠 `16.5 NextGen` | **不建议** | 抢紫色饱和度，整体发闷 |

---

## 六、换装指南与通用服饰替换模板（以粉色护士装为例）

`arcaea-lagrange-ANIMA-000022.safetensors` 对人物头部特征与原皮服饰进行了分区标注（Head / Body / Lower Body），因此**换装灵活性极高**：只要在正面提示词中只保留 `lagrange-arcaea` + `Head` 段锚点，并在负面提示词中封禁原皮关键词，即可在 `0.70 ~ 0.75` 权重下实现零原皮残留的干净换装。

### 1. 换装通用公式

- **推荐 LoRA 权重**：`0.70 ~ 0.75`（`0.75` 对细链编辫与八角星发饰锁定更稳；`0.70` 对大幅度解衣/掀裙动作更自由）
- **正面必留角色特征（Head Only）**：
  ```text
  lagrange-arcaea, 1girl, solo, lavender hair, very long hair, single large braid adorned with thin chains, purple bows at the braid's end, purple bows on her side locks, purple-and-white octagram hair ornament, choppy bangs, purple eyes, violet iris, round monocle over one eye
  ```
- **负面必加原皮屏蔽词（Outfit Blocker）**：
  ```text
  cape, shoulder cape, purple cape, cloak, pinafore dress, yellow dress, yellow skirt, purple dress, pink ruffled detached collar, purple collar bow, crisscross chest ribbons, octagram on chest, purple pantyhose, printed pantyhose, purple stockings, purple shoes, wrist band, robotic companion, floating robot
  ```

### 2. 粉色护士装实测记录（`anima_out/lagrange_nurse/`，配置见 `_batch_lagrange_nurse.json`）

| # | 用例 | LoRA 栈与权重 | 表现与结论 |
| :--- | :--- | :--- | :--- |
| 01 | `01_sfw_standing_w075` | `d3dv 0.55` + `baka 0.45` + `photo-bg 0.40` + **`lagrange 0.75`** | **零原皮残留**。粉色短袖护士裙、白围裙、粉护士帽、白蕾丝吊带长筒袜、粉玛丽珍护士鞋全部准确生成；薰衣草粗编辫、辫尾紫蝴蝶结、两侧鬓发紫蝴蝶结、紫白八角星发饰、金边单片眼镜 100% 保留。 |
| 02 | `02_sfw_sitting_w070` | `01-ba 0.60` + `d3dv 0.55` + `baka 0.45` + **`lagrange 0.70`** | 把 `01-ba_anima` 降到 `0.60` 并在负面加入 `blue eyes, cyan eyes` 后，**彻底解决了蓝眼污染问题**，双瞳保持清透紫罗兰色；听诊器与粉色排扣护士裙细节自然。 |
| 03 | `03_nsfw_standing_lift_w072` | `01-ba 0.60` + `d3dv 0.55` + `baka 0.45` + **`lagrange 0.72`** + `un 0.75` | 敞开胸口并双手掀裙的动作完全放开，未被原皮罩裙锁死；编辫上的金属细链（`thin chains`）清晰可见，白色吊带袜与粉色护士装反差感极佳。 |
| 04 | `04_nsfw_bed_spread_w075` | `d3dv 0.55` + `baka 0.45` + **`lagrange 0.75`** + `un 0.80` | 卧床 M 字开腿构图，粉色护士装向两侧敞开，单片眼镜、紫瞳、侧发紫蝴蝶结与编辫细链全部维持稳定。 |

> **换装细节提示**：当新服装包含强烈符号元素（如护士帽的十字 `cross`）时，头部的 `octagram hair ornament` 有一定概率被同化为紫白十字发饰；若希望严格保持八角星造型，避免在正面写 `cross emblem`，改用 `plain pastel pink nurse cap`。

---

## 七、复现命令

```powershell
# 原皮测试（4 张）
python _anima_gen.py _batch_lagrange_test.json

# 粉色护士装换装测试（4 张）
python _anima_gen.py _batch_lagrange_nurse.json
```


