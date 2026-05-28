# 开发流程

godot-jolt-time 项目的标准开发流程。每次开发前过一遍。

## 总原则

1. **任何代码改动都要由 subsession 执行，主对话只做分析、方案、code review**
2. **改完任何代码（产品或测试）都必须跑全套测试**：`godot --headless --path . res://tests/run_tests.tscn`
3. **失败不提交**。哪怕只是 timer label format 这种小事 fail，也立刻停下来排查
4. **新增机制要同时新增测试**。今天的 bug 之所以反复，就是因为靠脑测不靠跑测
5. **共享脚本修改 = 高风险**。`actor.gd` / `timeline.gd` / `recorder.gd` / `rewindable.gd` / `camera_rig.gd` / `base_level.gd` 等改动前先确认 smoke 全过，改完再跑一次

## 决策树：用户的请求是什么类型？

- "做 X 功能" / "改 X" / "新关卡" → 见 §1 新功能 / 关卡
- "X 不工作" / "有 bug" → 见 §2 Bug 修复
- "X 是什么" / "能不能 X" / "X 怎么实现的" → 主对话直接答，不动代码
- "重构 X" / "优化 X" → 见 §3 架构重构

---

## §1 新功能 / 新关卡

### 1.1 新关卡

1. **在 LEVELS 数组登记**
   现在每关 .gd 都有自己的 `const LEVELS := [...]`。新建第四关之前，三关的 LEVELS 数组都要加上新关条目。（这是技术债，将来抽到单一 levels.gd 时再统一。）

2. **新建 `level_NN.tscn`**
   - 复制最近的关卡（推荐 `level_03.tscn`，结构最干净）
   - 必备节点：`HUD/GMPanel` (instance ref)、`HUD/BugReportButton`、`HUD/ExitButton`、`HUD/TimerLabel` (挂 timer_label.gd)
   - 如果需要 Timeline，加 `$Timeline` 类型 Node 挂 timeline.gd
   - TimerLabel 的 `timeline_path` 改成新关 Timeline 节点的路径

3. **新建 `level_NN.gd`**
   ```gdscript
   extends BaseLevel
   
   const LEVELS := [...]  # 三关同步的关卡清单
   
   func _get_levels() -> Array:
       return LEVELS
   
   func _dump_state() -> Dictionary:
       return {
           "timeline": {...},
           "actor": {...},
           "flags": {...},
       }
   
   func _ready() -> void:
       super._ready()  # 第一行！BaseLevel 的 GM/bug/exit wire 在这里跑
       # ... 关卡特有 setup
   ```

4. **如果关卡有"可活动节点"（推动/被推/规律运动的）**
   节点脚本实现 `has_activity() -> bool`，**写注释解释返回 true/false 的语义**。  
   level 的 `_is_input_active()` 加一行调用。  
   见 §4 "可活动节点契约"。

5. **写 smoke test 锁核心机制**
   每个新关至少写：
   - 加载场景不报错（_dump_state 返回非空 dict）
   - 该关核心机制的契约（key 拾取、door 触发、carry、暂停冻结 timeline 等）
   测试加在 `tests/run_tests.gd`，编号 `_test_5_xxx`。

6. **跑全套测试**：`godot --headless --path . res://tests/run_tests.tscn` 全 PASS 才能提交

### 1.2 新功能（非关卡）

- 改动写在最相关的关卡或新建模块
- 涉及 Timeline 状态机变化 → 必须改 `tests/run_tests.gd` 的对应 case，确认行为契约
- UI 按钮新增 → 用 `touch_button.gd` 作为 script
- 走 subsession 执行，commit 用 `feat:` 前缀

---

## §2 Bug 修复

### 2.1 用户报 bug 的标准流程

1. **用户按"提交Bug"按钮**（关卡 HUD 右上）
2. **用户把剪贴板内容粘给主对话**
3. **主对话不立刻下结论**：
   - 读 bug report，找数据反常的字段（任何"我以为应该 X 实际 Y"的值都要追根）
   - 把链路在脑子里手画一遍（事件 → 信号 → 状态字段 → 物理 / Timeline → 显示）
   - 如果数据不足，往 BugReport 加诊断字段，**不要**先建临时 DebugLabel
4. **写一个能复现这个 bug 的 smoke test**（先 fail）
5. **修复 → subsession 执行**
6. **跑全套测试，新 case 应该 PASS，旧 case 不能 regress**
7. **commit 用 `fix:` 前缀**，body 解释根因（不是症状）

### 2.2 复盘禁区（基于今天血泪）

- 多个 bug 互相遮蔽时，修完一层立刻 reset 假设，**不要默认下一个问题是同一原因**
- 偏离心智模型的数字（如 `items_v=[3.016, 1.245, 1.782]` 在 KINEMATIC freeze 下）必须停下来追问 "为什么"
- `headless --quit-after N 干净` 不等于行为正确，只是语法/资源链接验证
- subagent "完成报告" 是 intent 不是 fact，看完报告自己再跑一次关键路径

---

## §3 架构重构

### 3.1 前置条件

- 当前所有测试必须 PASS（`tests/run_tests.tscn` exit=0）
- 三关 headless 加载 `--quit-after 100` 无 ERROR/WARNING

### 3.2 流程

1. **主对话提案 + 风险分析**：要改什么、影响哪些文件、为什么这么改、有什么替代方案
2. **用户确认方案**
3. **subsession 执行**，要求 subagent：
   - 列改动文件清单
   - 跑测试给出 PASS/FAIL 输出
   - 报告踩坑
4. **主对话亲自再跑一遍测试**（subagent 的 "PASS 总数" 当 intent 不当 fact）
5. **commit 用 `refactor:` 前缀**

### 3.3 高危改动清单

| 改动 | 影响范围 | 必跑的测试 |
|---|---|---|
| `rewindable.gd` has_motion 语义 | 所有关卡 | B1-B3 |
| `timeline.gd` advance/step_backward | 所有关卡 timeline 行为 | D1-D2 + 5.1 / 5.2 |
| `actor.gd` 物理参数 (SPEED/GRAVITY/JUMP_VELOCITY) | 跳跃曲线 + carry | 1.1-1.3 + 5.3 |
| `base_level.gd` _ready 顺序 | 三关初始化 | 2.1-2.5 |
| `touch_button.gd` 事件处理 | 所有按钮 | C1 |
| `gm_panel.gd` 接口 | 三关 GM 面板 | 4.1-4.4 |

---

## §4 接口契约

### 4.1 可活动节点 (Activity Provider)

任何"可能贡献活动到 Timeline 推进"的脚本必须实现：

```gdscript
func has_activity() -> bool:
    # 这里写返回 true/false 的语义说明
    return ...
```

例子：
- `actor.gd`: velocity > 0.05 OR not is_on_floor → 物理活动
- `level_03_item.gd`: 永远 false（KINEMATIC，运动由 sine 规律驱动，规律开关在 level 表达）
- PushBox 没单独脚本：level 内联 `_pushbox_has_activity()` helper

**绝对禁止**直接调 `Rewindable.has_motion(x)`——必须走 `x.has_activity()` 接口，让节点自己声明语义。

### 4.2 Level 调试快照

`BaseLevel` 子类必须实现：

```gdscript
func _dump_state() -> Dictionary:
    return {
        "timeline": {...},     # current/total/state/locked/dragging/rewind
        "actor": {...},        # pos/vel/on_floor
        # 关卡特有：items / pushbox / has_key / etc.
        "flags": {...},        # 所有相关布尔字段
    }
```

`BugReport.copy_dict()` 会自动把它格式化成 YAML-ish 文本写到剪贴板。

### 4.3 Level 注册

每关 `_get_levels()` 返回 `LEVELS` 数组。三关 LEVELS 应该完全同步（技术债）。

---

## §5 测试覆盖要求

### 5.1 新增机制 = 新增测试

| 新增类型 | 必须的测试 |
|---|---|
| 新关卡 | smoke：加载、_dump_state 结构、核心机制契约 |
| 新可活动节点 | unit：`has_activity()` 三态（idle/active/edge case） |
| 新 HUD 按钮 | unit：按钮存在、信号触发 |
| 新 Timeline subscriber | unit：subscribe → 状态变化 → 接收 dispatch |
| 修复任何 bug | smoke：能复现该 bug 的场景（先 fail，修后 pass） |

### 5.2 测试编号约定

- B1-B3: rewindable.has_motion 三态
- C1: touch_button 去重
- D1-D2: timer_label 格式
- 1.x: ActivityProvider 接口
- 2.x: BaseLevel 基类
- 3.x: BugReport dict_to_text + dump_state
- 4.x: GMPanel
- 5.x: 关卡行为契约 smoke
- 6.x+: 新增功能预留

### 5.3 测试运行

```bash
# 全套
godot --headless --path . res://tests/run_tests.tscn

# 加载某关
godot --headless --path . res://level_03.tscn --quit-after 100
```

提交前两个都必须干净。

---

## §6 Commit 规范

### 6.1 前缀

- `feat:` 新功能 / 新关卡
- `fix:` Bug 修复
- `refactor:` 重构（行为不变）
- `test:` 只加测试
- `docs:` 只改文档
- `debug:` 临时调试代码（**之后必须清掉**）

### 6.2 Body

中文写清"为什么"和"怎么改"，不是"改了什么"（diff 已经告诉你）。关键：

- 根因 / 设计动机
- 测试覆盖（PASS 总数）
- 踩过的坑（如果有）

末尾保留 `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`

### 6.3 PR / 推送

主分支 `main`。直接推 `main` 没问题（个人项目）。

---

## §7 命令速查

```bash
# 跑全套测试
godot --headless --path . res://tests/run_tests.tscn

# 加载某关验证
godot --headless --path . res://world.tscn --quit-after 100
godot --headless --path . res://level_02.tscn --quit-after 100
godot --headless --path . res://level_03.tscn --quit-after 100

# 重新生成 .uid（新建 .gd 后需要）
godot --editor --quit  # 跑一次 editor 让 class_name 注册到全局

# 导出 iOS .pck（不重做 Xcode 工程）
godot --headless --path . --export-pack "iOS" build/ios/JoltTime.pck
```

---

## §8 文件分工地图

| 文件 | 角色 | 修改风险 |
|---|---|---|
| `base_level.gd` | 三关公共脚手架 | 高（影响三关） |
| `gm_panel.gd/.tscn` | GM 选关面板 | 中 |
| `bug_report.gd` | 调试 dump 工具 | 低 |
| `timer_label.gd` | TimerLabel 自管脚本 | 低 |
| `game_settings.gd` | 全局开关常量 | 低 |
| `actor.gd` | Actor 控制器 | **高**（影响跳跃/移动/carry） |
| `timeline.gd` | 时间状态机 | **极高**（影响所有 rewind） |
| `recorder.gd` / `ghost_trail.gd` | Timeline subscriber | 高 |
| `rewindable.gd` | 静态 capture/apply/has_motion | **极高** |
| `camera_rig.gd` / `observer_camera.gd` | 相机 | 中 |
| `touch_button.gd` | 按钮基类（含双源去重） | 高（影响所有按钮） |
| `virtual_joystick.gd` | 摇杆 | 低 |
| `timeline_bar.gd` | 时间轴 UI | 中 |
| `rewind_button.gd` | 长按 rewind 按钮 | 低 |
| `level_03_item.gd` | KINEMATIC 跳板脚本 | 低 |
| `world.gd` / `level_02.gd` / `level_03.gd` | 各关业务 | 中 |

---

## §9 项目里没做但应该做（技术债清单）

- LEVELS 数组三关重复（每加一关改三处）—— 抽到单一 `levels_registry.gd`
- 关卡 .tscn 里 HUD 节点大量重复（Joystick / ExitButton 锚点等）—— 抽 `hud_base.tscn`
- world.gd 和 level_02.gd 的 `_pushbox_has_activity` 重复 —— 抽到 BaseLevel 或者 PushBox 单独脚本
- 没有 CI / pre-commit hook —— 应该把 `tests/run_tests.tscn` 挂到 git pre-commit
- 没有覆盖率统计 —— 哪些代码路径没被测试碰到看不出来

这些不是必须立刻做。下次开始新关卡前再考虑。
