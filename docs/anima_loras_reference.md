# Anima 底模与 LoRA 模型备查手册（xintai 服务器 / 本地工作区）

- **远端服务器路径**：`/workspace/ComfyUI/models/loras/`
- **本地工作区路径**：`D:\comyia\`
- **配套底模组件**：
  - **Diffusion Models (`/workspace/ComfyUI/models/diffusion_models`)**：
    - `anima-base-v1.0.safetensors`
    - `anima-turbo-v1.1.safetensors`
    - `anima-aesthetic-v1.1.safetensors`
  - **Text Encoder (`/workspace/ComfyUI/models/text_encoders`)**：`qwen_3_06b_base.safetensors`
  - **VAE (`/workspace/ComfyUI/models/vae`)**：`qwen_image_vae.safetensors`

---

## 一、Anima 专用 LoRA 总览表（共 10 个）

| 序号 | 文件名 | 原模型名称 | 分类 | 核心触发词 | 推荐权重 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `01-ba_anima.safetensors` | BlueArchive_CG style_anima1 (v1.0) | 画风 | `blue_archive, game_cg`（可选 `halo`） | `0.75 ~ 0.85` |
| 2 | `d3dv.safetensors` | [anima-base] Semi-realistic 2.5D style (v1.0) | 画风 | `@d3d` | `0.50 ~ 0.70` |
| 3 | `bakaE79AAEE882A4.Md2S.safetensors` | Baka skin / baka皮肤 (v1.0) | 皮肤质感 | 无硬性触发词（内嵌词 `baka，skin，matte texture，2.5d`） | `0.40 ~ 0.60` |
| 4 | `anima3-photo-background-v3.safetensors` | Photo Background - 2d Compositing (v3.0) | 背景合成 | `photo background`、`real world location`（或 `photo_background`） | `0.40 ~ 0.60` |
| 5 | `16.5 NextGen V1.safetensors` | 16.5 ANIMA NSFW style (NextGen V1.0) | 画风 / NSFW | 无触发词（挂载即生效） | `0.70 ~ 0.80` |
| 6 | `Femboy_pantyhose_Anima_epoch_10.safetensors` | Males and Femboys in Pantyhose (v1.0 Anima) | 服饰 / 概念 | `femboy, pantyhose` | `0.70 ~ 1.00` |
| 7 | `guided penetration_anima_V1.0.safetensors` | セルフ挿入 / guided penetration (v1.0 anima) | NSFW 体位 | `guided penetration, 1girl, 1boy, hetero, penis, girl on top` | `1.00 ~ 1.10` |
| 8 | `un.safetensors` | better pussy and anus (v2.0 / `pus`) | NSFW 细节 | 无硬性触发词（建议加 `vagina, vulva` 或自然语言私处描述） | `0.60 ~ 1.00` |
| 9 | `kanadera_anima-v2.0.safetensors` | Kanadera(maimai) - カナデラ・シス・レクスター (v2.0) | 角色 | `kanadera-maimai`（搭配角色外貌与自然语言服装词） | `0.70 ~ 0.90` |
| 10 | `arcaea-lagrange-ANIMA-000022.safetensors` | Lagrange (Arcaea) - ラグランジュ (ANIMA 000022) | 角色 | `lagrange-arcaea`（+ 单片眼镜/八角星饰/紫披风全套锚点） | `0.75 ~ 0.85` |

---

## 二、各模型详细特征、触发词与参数说明

### 1. `01-ba_anima.safetensors`
- **Civitai 标题**：BlueArchive_CG style_anima1 (v1.0)
- **SHA256**：`0e9195b760491dd9c9ecbf216adf8944e1e86bc7baa1ef33b6f6b07d335d865f`
- **架构特征**：968 Tensors（`diffusion_model.blocks.*` 标准 Diffusers / ComfyUI Anima UNet 格式）
- **触发词**：
  - 画风主触发词：`blue_archive, game_cg`
  - 光环触发词：`halo`
- **视觉特征与用法**：
  - 强化《碧蓝档案》官方 CG 清透明亮的赛璐璐上色、柔和环境光与面部五官表现。
  - 与 `d3dv.safetensors` 混搭时（如 `01-ba_anima: 0.85` + `d3dv: 0.6`），既能保留清透二次元五官，又能获得立体柔和的光影体积感。

---

### 2. `d3dv.safetensors`
- **Civitai 标题**：[anima-base] AI - Semi-realistic 2.5D style 偏写实2.5d风格 (v1.0)
- **内部标题**：`d3dV`_lora`
- **SHA256**：`f85314fa48d6ce95b3ec3e05fed1f2e694be0625857f1f2b41cabb16c1353358`
- **架构特征**：840 Tensors（`networks.lora_anima`，dim 32 / alpha 32，基于 `anima-base-v1.0` 使用 CAME 优化器训练）
- **触发词**：
  - `@d3d`
- **视觉特征与用法**：
  - 提供偏写实的 2.5D 厚涂光影、细腻的肌肤明暗过渡与景深感。
  - 训练集中包含大量室内/床铺光影、背影与腿部透视构图，并使用了自然语言长句标注，对自然语言提示词响应良好。
  - 推荐权重：`0.5 ~ 0.7`（在 `haimi_v13_workflow.json` 中使用 `0.6`）。

---

### 3. `bakaE79AAEE882A4.Md2S.safetensors`
- **Civitai 标题**：Baka skin / baka皮肤 (v1.0)
- **SHA256**：`40c375f523c957c577140a59fb2b7fac6f90c06e287ff313077d89602b3bbb5f`
- **架构特征**：840 Tensors（`networks.lora_anima`，dim 32 / alpha 16，基于 `anima_baseV10` 训练）
- **触发词**：
  - **无需触发词**（训练集中内嵌标识为 `baka，skin，matte texture，2.5d`）
- **视觉特征与用法**：
  - 专门用于改善皮肤质感的辅助 LoRA，压制生硬的高光和“油皮/塑料感”，赋予人物干净、柔和、微哑光（matte texture）的肤质。
  - 适合作为常驻底层插件挂载，推荐权重 `0.4 ~ 0.55`（当前工作流设为 `0.45`）。

---

### 4. `anima3-photo-background-v3.safetensors`
- **Civitai 标题**：Photo Background - 2d Compositing｜写真背景・二次元合成 (v3.0 [anima-preview-3])
- **SHA256**：`ded6a43be005300423b43728c616d340ecbf527c25d2c4d29b0c77d1b6a067d0`
- **架构特征**：896 Tensors（`diffusion-pipe` 训练，基于 Anima Preview 3 Base）
- **触发词**：
  - `photo background`、`real world location`（或带下划线的 `photo_background`）
- **视觉特征与用法**：
  - 将 2D 动漫角色自然合成在真实照片级的背景中（2D Compositing / 实景二次元合成），强化背景建筑、街道、天台、自然光晕的摄影写实感与虚化景深。
  - 推荐权重：`0.4 ~ 0.6`（当前工作流设为 `0.45`）。

---

### 5. `16.5 NextGen V1.safetensors`
- **Civitai 标题**：16.5 ANIMA NSFW style (NextGen V1.0)
- **内部标题**：`16.5 NG V1`
- **SHA256**：`e8c6132dfc874803848110eeb0a27480cec228daa979239d91360e5fd013e464`
- **架构特征**：1344 Tensors（`networks.lora_anima`，dim 32 / alpha 16，最高 1536x1536 分桶，同时包含 UNet 与 Text Encoder 微调层）
- **触发词**：
  - **无触发词**（直接通过权重控制强度）
- **训练集高频标签特征**：
  - `1girl, breasts, blush, looking at viewer, indoors, smile, long hair, nipples, shirt, thighs, collarbone, short hair, solo, window, white shirt, skirt, navel, closed mouth, pleated skirt, underwear, school uniform, panties, clothes lift, shirt lift, open clothes, ass`
- **视觉特征与用法**：
  - 针对 `Anima Base v1` 体系重制的动画截图风格与 NSFW 表现力增强 LoRA。
  - 显著提升照明鲜艳度、头身比例、身体曲线解剖细节以及提示词遵循度。
  - 官方推荐权重：`0.7 ~ 0.8`。

---

### 6. `Femboy_pantyhose_Anima_epoch_10.safetensors`
- **Civitai 标题**：Males and Femboys in Pantyhose (v1.0 Anima)
- **SHA256**：`293baf62918a015c34480f5422cc66f6d65648e8c9f89dfd902f48e033036072`
- **架构特征**：896 Tensors（`ai-toolkit` v0.10.27 训练，dim 32 / alpha 32，基于 `Anima-Base-v1.0`）
- **触发词**：
  - `femboy, pantyhose`
- **视觉特征与用法**：
  - 专门强化男性/伪娘（Femboy）穿着连裤袜的题材，突出纤细腿部轮廓与丝袜半透明材质感。
  - 推荐权重：`0.7 ~ 1.0`。

---

### 7. `guided penetration_anima_V1.0.safetensors`
- **Civitai 标题**：セルフ挿入 / guided penetration(ill,pony) (v1.0 anima)
- **SHA256**：`9b8833de4ba66e01d35be8c460915a8131d7e688b786554463ca703984d0c83a`
- **架构特征**：1344 Tensors（`networks.lora_anima`，dim 32 / alpha 32，50 张图训练 1000 步）
- **触发词**：
  - **必带核心词**：`guided penetration`
  - **高频绑定词**：`1girl, 1boy, hetero, penis, solo focus, breasts, nipples, vaginal, sex, straddling, girl on top, cowgirl position, spread legs, nude, sweat, blush, pov, imminent penetration, imminent vaginal, handjob`
- **视觉特征与用法**：
  - 专门用于生成“女上位/骑乘位下，角色自己用手握住阴茎引导对准插入（セルフ挿入 / guided penetration）”的动作体位。
  - 作者推荐权重：`1.0 ~ 1.1`。

---

### 8. `un.safetensors`
- **Civitai 标题**：better pussy and anus (v2.0)
- **内部标题**：`pus`
- **SHA256**：`e089479ef993e617a1c7b758650fb60a022d8cb924ba6ca88435e37ea18e3502`
- **架构特征**：840 Tensors（`networks.lora_anima`，dim 48 / alpha 24，基于 `anima-preview` 训练 1700 步）
- **触发词**：
  - **无硬性触发词**
  - **增强激活词**：强烈建议在提示词中加入 **`vagina`**、**`vulva`**（或自然语言描述如 `exposed genitalia, labia spread apart, revealing her vulva in detailed close-up, anus`）。
- **视觉特征与用法**：
  - 训练集全部使用自然语言长句描述，专门强化女性外阴（阴唇、阴道口）与肛门的局部解剖细节。
  - v2.0 降低了对整体画风的污染；单人展示场景下权重可用 `0.7 ~ 1.0`；在双人性爱交合场景下，建议将权重略微下调至 `0.6 ~ 0.75` 并配合详细的自然语言体位描述，以避免肢体多长或错位。

---

### 9. `kanadera_anima-v2.0.safetensors`
- **Civitai 标题**：Kanadera(maimai) - カナデラ・シス・レクスター (v2.0)
- **内部标题**：`kanadera_anima_29th_try`
- **SHA256**：`b230354e44bda52c8ba93705934376acfd45c4e0b282b82123d28ebd61ff2312`
- **架构特征**：840 Tensors（`networks.lora_anima`，dim 16 / alpha 16，基于 `anima-base-v1.0` 使用 Prodigy 优化器训练）
- **触发词与完整提示词结构**：
  - **核心角色触发词**：`kanadera-maimai`
  - **基础外貌 Booru 词**：
    `1boy, red eyes, short hair, streaked hair, multicolored hair, white hair, purple hair, green hair, blonde hair, red hair, aqua hair, star hair ornament, hikimayu, short eyebrows, animal ears, bear ears, androgynous`
  - **外貌自然语言词**：
    `left side yellow animal ear and right side green animal ear, white-and-blue ringed hat decorated with yellow stars rests on her left yellow animal ear`
  - **完整红披风原皮预设（Red cape version）**：
    ```text
    kanadera-maimai, 1boy, red eyes, short hair, streaked hair, multicolored hair, white hair, purple hair, green hair, blonde hair, red hair, aqua hair, star hair ornament, star hat ornament, hikimayu, short eyebrows, black shorts, short shorts, shorts ribbon, puffy shorts, red ribbon, red cape, two-sided cape, white thighhighs, ankle boots, white boots, animal ears, red bow, shirt, white shirt, frilled shirt, puffy long sleeves, lace trim, aiguillette, shoulder sash, tilted headwear, headphones around neck, electric plug, cable, bear ears, left side yellow animal ear and right side green animal ear, white-and-blue ringed hat decorated with yellow stars rests on her left yellow animal ear, fur collar with pearl chain in front and white ascot under the fur collar and black fabric under both the ascot and collar, with connecting the chest ornament which holds a large gold star brooch with a red diamond-shaped jewel and dangling star charms, the white shirt featuring a stylized "DX" logo on the left bottom of the shirt with the blocky "D" has a star-shaped cutout in its center, tied with a shoulder sash, rainbow headphone with black cable ending in a red bow and a power plug, the white shirt featuring puffy long sleeves that with crossed shaped white lace on the hem and white outlined five-pointed stars scattered across the material, gold trimmed red cape with orange inner fabrics and outside with rainbow lining ribbon ending with a star ornament hanging down from the cape and pale-blue striped lining ribbon around the shoulder and gold trimmed red ribbon, black short shorts with crossed shaped white lace on the hem and red shorts ribbon on side, white thighhigh socks with gold bands, oversized white ankle boots with yellow soles, red toe panels
    ```
  - **仅白衬衫预设（Only white shirt version）**：
    去掉披风、肩带、绶带与靴子相关词，若依然出现披风/毛领残留，可在负面提示词中加入：
    `no fur collar, no cape, no sash, no aiguillette`
- **推荐权重**：`0.7 ~ 0.9`（遇到背景符号过拟合或换装困难时降至 `0.7`）。

---

### 10. `arcaea-lagrange-ANIMA-000022.safetensors`
- **Civitai 标题**：Lagrange (Arcaea) — ラグランジュ（ANIMA 第 22 版）
- **架构特征**：Anima `networks.lora_anima` 格式，文件 331 MB（远大于同类角色 LoRA 的 40~130 MB，训练充分度高）
- **触发词**：
  - **必带主词**：`lagrange-arcaea`
- **头部锚点**：
  - `lavender hair`（薰衣草紫发）、`large braid adorned with thin chains`（饰细链的大编辫）
  - `purple bows at the braid's end`、`purple bows on her side locks`
  - `purple-and-white octagram hair ornament`（紫白八角星发饰）
  - `choppy bangs`、`purple eyes`、`monocle`（单片眼镜）
- **上身服饰锚点**：
  - `pink ruffled collar with purple edges`、`purple bow at the collar`
  - `yellow-and-purple layered dress with straps`、`white outer pinafore dress`、`purple bow at the center`（罩裙中央紫蝴蝶结）
  - `bare shoulders`
  - `light purple cape with purple edges on one shoulder`、`purple cape straps`
  - `pink ribbons tied across her chest`、`purple-and-white octagram decoration on the ribbons`
  - `purple band wrapped around her wrist`
- **下身锚点**：
  - `purple printed pantyhose`（紫色印花连裤袜）、`purple shoes`
- **可选 / 不建议**：
  - `small purple robotic companion beside her`（小型紫色机械伙伴，可选）
  - **原作者明确标注 `(NOT RECOMMEND)`**：斗篷上印刷的特殊徽记 —— 不要把 emblem 写进正面提示词，并建议把 `emblem printed on cape, printed pattern on cape, logo on cape` 放进负面
- **视觉特征与用法**：
  - 还原 Arcaea ラグランジュ 的紫白配色体系：薰衣草长发 + 粗编辫 + 侧发蝴蝶结 + 八角星饰，配单肩浅紫披风与粉缎带交叉束胸。
  - `monocle` 是最易丢的锚点，权重低于 `0.7` 时单片眼镜容易被模型揉合进眼睛，建议维持 `0.78 ~ 0.85`。
  - 披风**只在一侧肩**，必须显式写 `draped on one shoulder`，否则容易生成双侧对称披风。
  - 全身紫色占比高（发 / 蝴蝶结 / 披风 / 袜 / 鞋），整体发暗时搭配 `photo_background` + `cinematic lighting` 提亮，或把 `01-ba_anima` 拉到 `0.70` 补青透感。
  - 推荐配对：`d3dv` `0.55` + `baka` `0.45` 作常驻底层；不建议叠 `16.5 NextGen V1`（会抢紫色饱和度）。
  - 完整可直接使用的提示词模板见 `lora_lagrange_arcaea.md`。
- **推荐权重**：`0.75 ~ 0.85`（起手 `0.80`）

---

## 三、非 Anima 架构的 3 个同目录 LoRA（切勿在 Anima 工作流中混用）

以下 3 个文件虽然存放在同一目录中，但内部权重层属于 SDXL 或 SD1.5，无法挂载到 Anima 的 DiT/UNet 结构上：

1. **`femboyAnima_v1.safetensors`**
   - **实际底模**：`SDXL 1.0`（Civitai 在线训练时基底选为 SDXL checkpoint `civitai:261336@597138`，包含 `lora_te1` / `lora_te2` 等 2958 个 SDXL 张量）
   - **触发词**：`Femboy `
2. **`uni-000012.safetensors`**
   - **实际底模**：`NoobAI XL (sdxl_base_v1-0)`（2430 个张量）
   - **角色与触发词**：《CHUNITHM》角色 ユニ (Uni)，触发词 `uni_thm` / `uni thm`
3. **`femboy_flat_chastity_v3.0.safetensors`**
   - **实际底模**：`SD 1.5`（基于 `ComicBlender-pruned` 训练，分辨率 512x512，792 个张量）
   - **概念与触发词**：平板金属贞操锁，触发词 `flat chastity_cage, testicles, shaved, otoko no ko`
