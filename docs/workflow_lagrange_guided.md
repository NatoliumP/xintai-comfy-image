# 工作流：Lagrange × 护士服 × guided penetration（双人）

- 服务器：`xintai` ComfyUI（RTX 5070 Ti）
- 角色：Arcaea ラグランジュ（`arcaea-lagrange-ANIMA-000022.safetensors`）
- 体位：`guided penetration_anima_V1.0.safetensors`（女上位引导插入）
- 定稿产出：`anima_out/lagrange_guided_v2/`；v1 对照 `anima_out/lagrange_guided/`

---

## 一、文件清单

| 文件 | 说明 |
| :--- | :--- |
| `workflow_lagrange_guided_ui.json` | **主工作流**，14 节点 5 LoRA，拖进 ComfyUI 直接用 |
| `_batch_lagrange_guided.json` | 4 组 API 批量任务 |
| `_build_guided_wf.py` | 生成器 |
| `workflow_lagrange_nurse.md` | 前一版单人护士服工作流（对照） |
| `lora_lagrange_arcaea.md` | 角色触发词档案 |

---

## 二、本轮四项改动

| 要求 | 落地做法 |
| :--- | :--- |
| **配饰少一点** | 锚点从 8 项砍到 3 项：只留 `八角星发饰 + 单片眼镜 + 辫尾蝴蝶结`。删掉侧发蝴蝶结、紫色腕带、机械伙伴、胸前三叶草、披风系带；并把删掉的词全部塞进负面 |
| **保留紫色裤袜** | `NURSE_OUTFIT` 里用 `purple printed pantyhose on both legs` + `sheer purple nylon pantyhose from waist to toes`；负面**不再**压 `purple printed pantyhose`（上一版压了会导致出白丝），改压 `white thighhighs, white socks, bare legs` |
| **去掉机械伙伴** | 正面删 `small purple robotic companion`；负面加 `robotic companion, robot companion, small robot, floating robot` |
| **试 guided penetration** | 挂 `guided penetration_anima_V1.0.safetensors` 权重 `1.05`；正面注入核心触发词组（见下）；负面**移除** `1boy / male / penis / testicles`（双人必需），改为压 `multiple boys, threesome, group sex` |

---

## 三、工作流结构（14 节点，5 LoRA）

```
UNETLoader (anima-turbo-v1.1)
        │
        ├─ LoRA ① d3dv 0.55                          ┐
        ├─ LoRA ② baka (skin) 0.45                   │
        ├─ LoRA ③ Lagrange 0.75  ← 收紧到 0.75        │ 串行链
        ├─ LoRA ④ guided penetration 1.05            │ 只作用于 MODEL
        └─ LoRA ⑤ un 0.65  ← 多体场景降权防错位       ┘
                    │
                    ▼
              KSampler ◄── 正面（锚点 + 护士服 + 紫裤袜 + 引导插入）
                    │    ◄── 负面（配饰精简 + 压多人混战）
                    │    ◄── EmptySD3LatentImage 768×1344
                    ▼
              VAEDecode ◄── VAELoader (qwen_image_vae)
                    ▼
              SaveImage → lagrange_guided/manual
```

**参数**
- `steps 36`（比单人版 32 高，双人体位需要更多步收敛）
- `cfg 4.5` / `euler_ancestral` + `linear_quadratic`
- **Lagrange 0.75**（角色基准 0.80，本轮为了减少配饰密度再降一档）
- **guided penetration 1.05**（作者推荐 1.0~1.1）
- **un 0.65**（手册建议交合场景 0.6~0.75，防肢体多长）

---

## 四、guided penetration 触发词组

```text
1boy, hetero, guided penetration,
penis, erection,
girl on top, cowgirl position, straddling,
spread legs, sitting on his lap,
one hand gripping his penis, guiding it toward her pussy,
imminent penetration, imminent vaginal,
vaginal, sex, sweat, blush
```

`guided penetration` 是必带核心词，缺了它整个体位动作会退化成普通骑乘或纯站立。
`imminent penetration` / `imminent vaginal` 是原训练集的高频绑定词，负责让「还没插进去、正在对准」这个瞬间成立。

---

## 五、四个变体

| # | 变体 | 构图 | 核心动作 |
| :--- | :--- | :--- | :--- |
| 01 | `pov_cowgirl` | POV 仰视 | 跪在上方，手握龟头压在自己阴唇上，紫裤袜褪到大腿 |
| 02 | `side_insert` | 侧面 profile | 跨坐，手指捏住阴茎往两腿间带，裤袜裆部撕开 |
| 03 | `cowgirl_closeup` | 髋部特写 | 半插入状态，手指还握着茎身往里推，裤袜堆在大腿 |
| 04 | `standing_guided` | 背后回望 | 站立背贴，手向后伸引导，裤袜褪到中大腿 |

---

## 六、v1 → v2 修正记录

| 问题 | v1 | v2 修法 | v2 结果 |
| :--- | :--- | :--- | :--- |
| **侧发蝴蝶结没掉** | 还在（case02/03） | 只在正面删了没进负面；v2 负面补 `side lock bows, purple bows on her side locks, hair bow on both sides, twin side hair bows` | ✅ 全部清除 |
| **case04 左眼偏蓝** | 轻微异色瞳复发 | 正面 `both eyes exactly the same purple color`；负面补 `one purple eye one blue eye, asymmetric eye color` | ✅ 双紫瞳 |
| **八角星变花瓣** | 花瓣形 | 改用 `octagram star + eight-pointed star polygon + straight sharp edges + not a flower` | ⚠️ 见下方已知问题 |

**四项核心要求在两版都稳定达成**：紫印花裤袜纹样完整、机械伙伴完全消失、腕带消失、引导插入动作准确。

---

## 七、已知顽固问题：八角星在护士题材下不稳定

**现象**：原装只有一枚紫白八角星发饰，在这套护士场景里会反复在三种形态间摇摆 —— **医疗十字**（v1 case01）、**四角/五角星**（v2 case02/03）、**十字与星混合**（v2 case04），而且数量始终是 4~5 个而不是一枚。

**原因**：`护士 = 十字` 的语义强度压过了形状描述。模型在「医疗题材 + 发饰」的组合下会把任何头部装饰向十字坍塌。负面里同时压 `cross shaped hair ornament` 和 `flower shaped hair ornament`，会让模型在两者之间反复横跳。

**三种取舍方案**：

1. **接受现状**（推荐）—— 星形变体本身观感不差，整体辨识度主要靠紫发大辫 + 单片眼镜撑着，配饰数量上也符合「配饰少一点」的诉求。
2. **换非医疗题材** —— 女仆装 / 泳装 / 睡衣 / 制服都不带十字语义，八角星能稳定还原（`lagrange_nurse.md` 那轮的普通场景实测就是这个结论）。
3. **彻底撤掉发饰** —— 正面只留 `monocle + 辫尾蝴蝶结`，把八角星从锚点完全删除，负面同时压所有星形与十字。牺牲还原度换干净。

---

## 八、换姿势 / 换装扩展

改 `_build_guided_wf.py`：

1. **加新体位变体** → 在 `CASES` 追加一条，`positive` 按「`LAGRANGE_ANCHOR` + `NURSE_OUTFIT` + `GUIDED_CORE` + 该构图的视角词」拼接
2. **换回单人场景** → 从 LoRA 链去掉 `guided penetration`，把 `1boy / male / penis` 挪回负面，`un` 调到 0.70~0.85
3. **换其他服装** → 改 `NURSE_OUTFIT`；同步把原装词继续留在 `ORIGINAL_SUPPRESS`（注意别把要保留的 legwear 写进负面）

**双人场景三条铁律**
- 负面里绝对不能出现 `1boy / male / penis / testicles`，否则男性角色被压掉，变成单人自慰
- `un` 必须降到 0.6~0.7，高于 0.75 容易出现第三条腿或错位肢体
- `solo focus` 要留在角色锚点里，让画面焦点保持在女性身上，避免构图散成混战

---

## 九、复现

```powershell
# 隧道（IP/端口按当前 vast 实例更新）
ssh -N -o StrictHostKeyChecking=no -i E:\docs\aribot\rinato-vermidier\vn1 `
    -p 42239 -L 18188:127.0.0.1:18188 root@115.78.134.198

python _build_guided_wf.py
python _anima_gen.py _batch_lagrange_guided.json
```

> `xintai` 是 vast.ai 竞价实例，隧道会不定期掉线。复现前先 `curl http://127.0.0.1:18188/system_stats` 探活。
