《Falling Leaves Forest》 使用说明书 / User Guide (TXT)

基本信息
--------
- 作品名称：Falling Leaves Forest（秋色落叶森林）
- 创作平台：Processing（Java 模式）
- 版本：v1.5（Clean + Stable）
- 创作者：@iSDAGE
- 代码文件：Falling_Leaves_Forest_v1_5.pde（以你当前 .pde 为准）
- 最后更新：2025.11

项目简介
--------
《Falling Leaves Forest》是一款带有麦克风交互的 2D 自然生成插画：
- **点击种树**：在地面点击即可长出一棵随机造型的树；
- **吹气落叶**：对着麦克风吹气（或发声）可触发树叶脱落并下飘；
- **秋色限定**：叶片采用金黄—橘红的秋季调色；
- **R 清空**：一键清空场景；
- **性能优化**：地面落叶绘制到离屏层（`groundLayer`），避免重复重绘。

核心交互（Controls）
-------------------
- **Mouse Click（点击）**：鼠标点击地面位置生成一棵树；
- **Blow / Speak（吹气 / 说话）**：当麦克风输入超过阈值时，树叶更易**脱落**并随风飘落；
- **R（Reset）**：清空所有树与叶，重置场景。

运行方式
--------
方式一：源码运行（推荐）
1. 安装 Processing 4.x（Java 模式）：https://processing.org/download
2. 确认代码首行已引入声音库：`import processing.sound.*;`
3. 打开 .pde 文件并点击 ▶️ 运行
4. **首次运行**需允许系统**麦克风权限**（macOS 建议在「系统设置 → 隐私与安全性 → 麦克风」中勾选 Processing）

方式二：导出应用程序
1. 在 Processing 中打开 .pde
2. 点击 **File > Export Application...**
3. 勾选平台（macOS / Windows）并导出 `.app` / `.exe` 即可直接运行（同样需要麦克风权限）

系统需求
--------
- 操作系统：macOS / Windows / Linux
- 软件环境：Processing 4.x（Java 模式）
- 渲染器：P2D（代码中 `size(W,H,P2D)`）
- 声音库：`processing.sound`（Processing 4 自带；如缺少可用「Sketch > Import Library」添加）
- 麦克风：需可用且已授权

作品机制与结构
--------------
- **背景与地面**：
  - 天空使用竖向线性渐变（`drawSky()`），地面为色带矩形；
- **树与枝（Branch）**：
  - 点击后自根部向上生长主干，再递归分叉（`subdivide()`）；
  - 分叉参数（深度、角度、长度衰减）**每棵树独立随机**，造型多样；
- **叶（Leaf）状态机**：`ATTACHED → FALLING → LANDED`
  - 附着（轻微摇摆）→ 脱落（受重力与微风）→ 落地（烘托到 `groundLayer`，永久留存）；
- **风模型**：
  - `wind = breeze(Perlin) + micForce(Amplitude)`；
  - breeze 横向分量较小，使整体更**垂直**、更“秋天”；
- **性能优化**：
  - 落地叶片绘制到 `groundLayer` 离屏层，后续帧直接贴图，省去反复重绘成本。

可调参数（顶区）
----------------
- 画布与配色：`W/H`、`SKY_TOP/SKY_BOT/GROUND`
- 秋色调色板：`PAL_AUTUMN`
- 造型控制（单棵树的范围随机）：
  - `curDepthMax`（分支深度 4–5）
  - `curAngleSpread`（分叉角度 20–46°）
  - `curLenDecayMin/Max`（子枝长度衰减比）
- 麦克风触发阈值：`blowThreshold`（默认 0.06，环境嘈杂时可适度上调）

文件说明
--------
- **主程序 .pde**：包含全部逻辑（渲染、交互、声音输入、风、生成与优化）
- **离屏层**：`PGraphics groundLayer`（仅叠加新落地叶）
- **数据结构**：`Branch`、`Leaf`、`TreeInfo`，以及范围索引 `Range`

常见问题（FAQ）
--------------
1) **吹气没反应？**  
   - 检查系统是否已授权麦克风给 Processing；
   - 在安静环境中测试，或下调 `blowThreshold`；
   - 麦克风音量过低时可靠近一些，或提高系统输入增益。

2) **叶子几乎不掉？**  
   - 将阈值 `blowThreshold` 从 `0.06` 适当降低，如 `0.035–0.05`；
   - 或增大 `updateWind()` 中 `strength` 的映射上限。

3) **帧率不稳？**  
   - 分辨率较高时尽量保持 `P2D` 渲染；
   - 一次性种植太多树会增加叶片数量，可适度控制点击频率。

4) **如何改成“冬天/春天”风格？**  
   - 修改 `PAL_AUTUMN` 或在 `growLeavesOnRange()` 里根据季节换色；
   - 冬季可减少叶数并增强风；春季可增加新叶并提高饱和度。

扩展建议（可选）
----------------
- **截图功能**：在 `keyPressed()` 中添加 `S` 键调用 `saveFrame("forest_####.png");`；
- **降噪**：对 `amp.analyze()` 做滑动平均，已在 `levelSmooth` 中提供线性插值；
- **风向渐变**：让 `breeze` 缓慢改变方向以获得更自然的季节感。

版权与署名
----------
- 作者：@iSDAGE
- 仅限教学 / 展示 / 作品集等非商业用途；商用请联系作者。
- 转载或演示请保留署名。

联系
----
- Website：https://www.snowmonsterge.com
- Notes：欢迎就视觉细节与交互体验提出建议。
