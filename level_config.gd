class_name LevelConfig
extends Resource

# 关卡数据驱动配置。每关一个 .tres 实例，BaseLevel 子类读取应用。
# 命名约定：res://config/level_<NN>.tres
#
# 当前阶段：参数定义齐全，但产品代码尚未消费（向后兼容，不强制改造）。
# 下次新关或重平衡时，把硬编码值搬到 .tres 即可数据驱动。

# 时间机制
@export var timer_duration: float = 10.0      # Timeline.total_duration
@export var timescale: float = 1.0            # Timeline.timescale (1.0=正常)
@export var rewind_window: float = 3.0        # Timeline.REWIND_WINDOW（现在是常量）

# 物理 / 引力
@export var gravity_vector: Vector3 = Vector3(0, -18, 0)
@export var fall_death_y: float = -5.0

# Actor 控制
@export var actor_speed: float = 5.0
@export var actor_jump_velocity: float = 6.0

# 关卡元信息
@export var display_name: String = ""         # GM 面板显示名
@export var next_scene: String = ""           # 走 Door 后切到哪个 scene；空串=不切
