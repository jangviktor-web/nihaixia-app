# ADR-UI-001: 锁定一套 SVG 图标库（Lucide）

- 状态：Accepted（2026-09-02）
- 提案：大湾区靓仔（项目总监）｜ 关联方案 B（UI/无障碍优化）Step 1

## Background（背景）

UI 审计发现两大图标相关风险：

1. **P0-1 绝对规则**：禁止用 emoji 作功能图标。当前代码中部分功能图标依赖 `Icons.xxx`（Material 图标），
   虽非 emoji，但 Material 图标语义/描边风格不统一，且与「统一描边、可矢量缩放、语义明确」的团队规范存在偏差。
2. **审计暴露的隐患**：部分交互控件仅有图标无文字、无 `tooltip`、无 `Semantics`，读屏不可达。

为根治，需**锁定一套** SVG 图标库，全项目统一使用、不混用，并配套 `tooltip`/`Semantics` 门禁（Step 3）。

## Decision（决策）

- 锁定 **Lucide**（`lucide_icons`）作为本 App 唯一功能图标库。
- 约束：
  - 全项目功能图标 **只** 用 Lucide，禁止 emoji、禁止与 Material `Icons` 混用。
  - 图标尺寸统一为 3 档：行内 16px / 按钮内 20px / 独立图标 24px（与团队 P0-1 规范一致）。
  - 每个图标必须配 `semanticLabel`（或 `tooltip`），保证读屏可达。
- 选型理由：
  - 纯 SVG / 统一 2px 描边、视觉一致、可矢量缩放；
  - 语义化命名（如 `LucideIcons.heartPulse` 对应中医心率场景），贴合医疗内容；
  - 支持 tree-shaking，仅打包用到的图标；
  - MIT 协议，可商用。

## Consequences（后果）

- 正面：图标风格统一、可访问性达标、未来换肤/主题一致；满足 P0-1。
- 负面：需一次性的图标迁移（将现有 `Icons.xxx` 逐步替换为 Lucide）—— 归入 **Step 3** 执行，不在 Step 1 范围。
- 注意：Step 1 仅「锁定 + 入依赖 + 立门禁」，不改动现有 `Icons` 调用，保证本步零回归、可独立回退。

## 迁移计划（Step 3）

1. 全量扫描 `Icons.` 调用点，建立「Material 图标 → Lucide 等价图标」映射表。
2. 按屏幕分批替换，每屏替换后跑 emoji 正则扫描 + 读屏验证。
3. 替换后补 `tooltip`/`Semantics`，门禁（S8）兜底。

## 备选方案（已否决）

- 继续用 Material `Icons`：不满足「统一描边 SVG」规范，且无法根治 P0-1 风险。
- 自绘 SVG assets：维护成本高，不划算。
- 多套图标库混用：明确违反 P0-1「锁定一套不混用」。
