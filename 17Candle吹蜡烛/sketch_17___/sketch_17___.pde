/**
 * Blow Candle（吹灭蜡烛） — Processing 4 (Java mode)
 * 
 * 交互：
 *  - 对着麦克风“吹气”（大于阈值的气流/噪声）→ 火焰抖动并逐步熄灭，出现烟雾
 *  - 空格键 Space → 重新点燃，火焰从烛芯慢慢长大
 *  - 键 'v' → 开/关调试视图（麦克风幅度条，阈值线）
 *  - 键 'p' → 保存 PNG
 * 
 * 依赖：Processing Sound 库（Sketch → Import Library → Add Library → 搜索 "Sound"）
 */

import processing.sound.*;

// —— 画布与配色 ——
int W = 768, H = 1024;
color bgTop = #0C3E59;   // 深蓝
color bgMid = #1E5B84;   // 中蓝
color bgBot = #0B374F;   // 底部深蓝

// —— 声音输入 ——
AudioIn mic;
Amplitude amp;
float level = 0;        // 实时幅度（0..1）
float levelSmooth = 0;  // 平滑后
float blowThreshold = 0.085; // 触发吹灭的阈值（可按需要调整）
float blowMemory = 0;         // 累积“吹气能量”（避免短噪声误触）

// —— 状态机 ——
static final int LIT = 0;          // 点燃
static final int EXTINGUISHING = 1;// 正在熄灭动画
static final int OUT = 2;          // 熄灭
static final int RELIGHT = 3;      // 重新点燃动画
int state = LIT;

// —— 火焰参数 ——
float flameAlpha = 255;  // 透明度（熄灭动画用）
float flameHeight = 90;  // 动态高度
float flameBaseHeight = 90;
float flameNoiseT = 0;   // 噪声时间
// 真实烛火：呼吸与闪烁控制
float breatheT = 0;     // 呼吸相位（正弦缓慢起伏）
float flickerT = 0;     // 微闪烁相位（更快）

// 写实配色（内亮→中层→外焰蓝）
color FLAME_CORE = #FFF6D6;   // 近白的热核
color FLAME_MID1 = #FFC95C;   // 明亮橙黄
color FLAME_MID2 = #FF9A3A;   // 稍深橙
color FLAME_OUT  = #A8D7FF;   // 外焰淡蓝

// —— 烟雾系统 ——
ArrayList<Smoke> smokes = new ArrayList<>();

// —— UI／调试 ——
boolean showDebug = false;

void settings(){
  size(W, H, P2D);
  smooth(8);
}

void setup(){
  surface.setTitle("Blow Candle（吹灭蜡烛） — v1.0");
  // 声音输入
  mic = new AudioIn(this, 0);
  amp = new Amplitude(this);
  mic.start();
  amp.input(mic);
}

void draw(){
  drawBg();
  drawCandle();
  updateMic();
  updateStateMachine();
  drawSmokes();
  drawFlame();
  if (showDebug) drawDebug();
}

// ————————————————————————————————————
// 背景（径向+线性混合）
void drawBg(){
  noStroke();
  // 顶→中→底的线性渐变
  for (int y=0; y<H; y++){
    float t = y/(float)H;
    color c = (t<0.6) ? lerpColor(bgTop, bgMid, map(t,0,0.6,0,1))
                      : lerpColor(bgMid, bgBot, map(t,0.6,1.0,0,1));
    stroke(c);
    line(0,y,W,y);
  }
}

// ————————————————————————————————————
// 烛身/烛芯
PVector candleTop = new PVector(W*0.5, H*0.58);
float candleW = 90, candleH = 460;

void drawCandle(){
  // 影子
  noStroke();
  for (int i=0;i<200;i++){
    float a = map(i,0,199,40,0);
    fill(0, a);
    float w = map(i,0,199,candleW*0.6,candleW*1.6);
    ellipse(candleTop.x, candleTop.y+candleH+70+i*0.4, w, 8);
  }

  // 柱体
  pushMatrix();
  translate(candleTop.x, candleTop.y);
  rectMode(CENTER);
  // 立体渐变
  for (int x=-int(candleW/2); x<=int(candleW/2); x++){
    float t = map(x, -candleW/2, candleW/2, 0, 1);
    color c = lerpColor(#F6F7F9, #C8CFD8, pow(t,1.2));
    stroke(c);
    line(x, 0, x, candleH);
  }
  // 顶面
  noStroke();
  fill(#EDEFF3);
  rect(0, 0, candleW, 10);

  // 烛芯
  stroke(90, 90, 100);
  strokeWeight(3);
  noFill();
  float wickLen = 18;
  // 轻微弯曲
  beginShape();
  vertex(0, -4);
  bezierVertex(2, -wickLen*0.4, -2, -wickLen*0.7, 0, -wickLen);
  endShape();
  popMatrix();
}

// ————————————————————————————————————
// 麦克风与吹气检测
void updateMic(){
  level = amp.analyze();            // 原始 0..1（通常很小）
  // 简单去抖与平滑（指数平均）
  levelSmooth = lerp(levelSmooth, level, 0.35);

  // 累积“吹气能量”：当高于阈值时快速累积，低于阈值时缓慢衰减
  if (levelSmooth > blowThreshold) blowMemory = min(1.0, blowMemory + (levelSmooth - blowThreshold)*3.2);
  else                             blowMemory = max(0.0, blowMemory - 0.02);
}

boolean isBlowing(){
  // 需要超过阈值并且有一定持续（记忆>某值）
  return levelSmooth > blowThreshold*0.9 && blowMemory > 0.25;
}

// ————————————————————————————————————
// 状态机
void updateStateMachine(){
  switch(state){
    case LIT:
      // 火焰自然抖动
      flameNoiseT += 0.012;
      flameHeight = lerp(flameHeight, flameBaseHeight + noise(flameNoiseT)*16 + levelSmooth*120, 0.15);

      // 被吹到：进入熄灭动画
      if (isBlowing()) {
        state = EXTINGUISHING;
      }
      break;

    case EXTINGUISHING:
      flameNoiseT += 0.03; // 抖得更厉害
      flameHeight = max(8, flameHeight*0.9);
      flameAlpha   *= 0.86;

      // 释放烟雾
      for (int i=0; i<4; i++) smokes.add(new Smoke(candleTop.x, candleTop.y-30));
      if (flameAlpha < 6) { flameAlpha = 0; state = OUT; }
      break;

    case OUT:
      // 熄灭后还有余烟
      if (frameCount % 2 == 0) smokes.add(new Smoke(candleTop.x, candleTop.y-30));
      break;

    case RELIGHT:
      // 火苗从烛芯点起，逐步增高 + 透明度恢复
      flameAlpha   = min(255, flameAlpha + 12);
      flameHeight  = lerp(flameHeight, flameBaseHeight, 0.18);
      flameNoiseT += 0.01;
      if (abs(flameHeight - flameBaseHeight) < 1.5 && flameAlpha > 240) state = LIT;
      break;
  }
}

// ————————————————————————————————————
// 火焰绘制（贝塞尔叶片 + 光晕）
void drawFlame(){
  if (state == OUT && flameAlpha == 0) return;

  pushMatrix();
  translate(candleTop.x, candleTop.y-28);

  // 时间与幅度（呼吸 + 闪烁）
  breatheT += 0.020;                 // ~1.5s 一个呼吸
  flickerT += 0.030 + levelSmooth*0.20;
  float breathe = 1.0 + sin(breatheT)*0.06 + 0.04; // 高度轻微起伏

  // 高度与宽度
  float h = max(12, flameHeight * breathe);
  float w = map(h, 12, 160, 12, 34);

  // 左右摇摆（基础抖动 + 吹气偏斜）
  float baseSway = (noise(flameNoiseT*1.7)-0.5)*12;
  float blowSway = levelSmooth*220; // 吹时整体倾斜
  float sway = baseSway + blowSway;

  // 顶端微偏移，让形状不对称
  float tipJitter = (noise(flickerT*1.6)-0.5) * (4 + levelSmooth*28);

  // 柔和光晕（更短、更集中，更接近真实烛火）
// 小范围、较低亮度，避免照亮到烛身
drawRadialGlow(sway*0.06, -h*0.48, w*1.25, h*1.25, color(255, 230, 140), flameAlpha*0.08);
drawRadialGlow(sway*0.08, -h*0.28, w*1.05, h*1.05, color(255, 245, 200), flameAlpha*0.04);

  // 主体三层：外焰淡蓝 → 中层橙 → 内核白黄 → 中层橙 → 内核白黄
  pushMatrix();
  translate(sway, 0);
  noStroke();
  // 外焰（透明蓝，边缘更淡）
  drawFlameShape(w*1.10, h*1.10, color(red(FLAME_OUT), green(FLAME_OUT), blue(FLAME_OUT), flameAlpha*0.18), tipJitter, 0.30);
  // 中层（两次叠加制造过渡）
  drawFlameShape(w*1.00, h*1.00, color(red(FLAME_MID1), green(FLAME_MID1), blue(FLAME_MID1), flameAlpha*0.35), tipJitter*0.8, 0.36);
  drawFlameShape(w*0.86, h*0.86, color(red(FLAME_MID2), green(FLAME_MID2), blue(FLAME_MID2), flameAlpha*0.65), tipJitter*0.7, 0.34);
  // 内核（更亮更小）
  drawFlameShape(w*0.64, h*0.66, color(red(FLAME_CORE), green(FLAME_CORE), blue(FLAME_CORE), flameAlpha*0.52), tipJitter*0.5, 0.32);

  // 热点（小椭圆，模拟极亮的烛心）
  fill(255, 255, 230, flameAlpha*0.75);
  ellipse(0, -h*0.18, w*0.22, w*0.38);
  popMatrix();
  popMatrix();
}

// 以不完全对称的贝塞尔左右边缘构出火焰外形
// bulge 控制腰身鼓度（0.2~0.5 建议），tipJitter 让尖端轻微偏移
void drawFlameShape(float fw, float fh, color c, float tipJitter, float bulge){
  fill(c);
  beginShape();
  // 底点
  vertex(0, 0);
  // 右侧边缘（略与左侧不同以破对称）
  float r1x = fw*(0.65 + (noise(flickerT*0.9)-0.5)*0.10);
  float r1y = -fh*(0.22 + (noise(flickerT*0.7)-0.5)*0.04);
  float r2x = fw*(0.55 + (noise(flickerT*1.1)-0.5)*0.08);
  float r2y = -fh*(0.78 + (noise(flickerT*0.8)-0.5)*0.06);
  bezierVertex(r1x, r1y, r2x, r2y, tipJitter*0.6, -fh);
  // 左侧边缘（参数略不同）
  float l2x = -fw*(0.58 + (noise(flickerT*0.85)-0.5)*0.08);
  float l2y = -fh*(0.76 + (noise(flickerT*0.95)-0.5)*0.06);
  float l1x = -fw*(0.70 + (noise(flickerT*0.75)-0.5)*0.10);
  float l1y = -fh*(0.24 + (noise(flickerT*0.65)-0.5)*0.04);
  bezierVertex(l2x, l2y, l1x, l1y, 0, 0);
  endShape(CLOSE);
}

// 柔和径向光晕
void drawRadialGlow(float cx, float cy, float gw, float gh, color col, float baseA){
  noStroke();
  int rings = 36; // 更多圈数，过渡更顺滑
  for (int i=0; i<rings; i++){
    float t = i/(float)(rings-1);
    float a = baseA * (1.0 - pow(t, 0.85)); // 边缘更柔，中心不刺眼
    fill(red(col), green(col), blue(col), a);
    ellipse(cx, cy, lerp(gw, gw*1.6, t), lerp(gh, gh*1.6, t)); // 光晕扩散范围缩小
  }
}

// ————————————————————————————————————
// 烟雾粒子
class Smoke{
  PVector p, v;
  float r;
  float life = 1;
  Smoke(float x, float y){
    p = new PVector(x, y);
    v = new PVector(random(-0.3,0.3), random(-1.8,-0.6));
    r = random(8, 18);
  }
  void update(){
    p.add(v);
    v.x += (noise(p.y*0.01, frameCount*0.01)-0.5)*0.2;
    v.mult(0.995);
    life *= 0.985;
  }
  void display(){
    noStroke();
    fill(220, 220, 230, 60*life);
    ellipse(p.x, p.y, r*(1+0.6*(1-life)), r*(1+0.6*(1-life)));
  }
}

void drawSmokes(){
  for (int i=smokes.size()-1; i>=0; --i){
    Smoke s = smokes.get(i);
    s.update();
    s.display();
    if (s.life < 0.05) smokes.remove(i);
  }
}

// ————————————————————————————————————
// 调试可视化
void drawDebug(){
  pushStyle();
  fill(255,40);
  noStroke();
  rect(20, 20, 200, 70, 10);
  fill(255);
  text("mic level: "+nf(level,1,3), 30, 45);
  text("smooth: "+nf(levelSmooth,1,3), 30, 65);
  // 条形图
  float bar = map(levelSmooth, 0, 0.2, 0, 180);
  fill(#44D1FF);
  rect(30, 80, bar, 6, 3);
  stroke(255,120,120);
  float thr = map(blowThreshold, 0, 0.2, 0, 180);
  line(30+thr, 80, 30+thr, 86);
  popStyle();
}

// ————————————————————————————————————
// 键鼠
void keyPressed(){
  if (key==' ') relight();
  if (key=='v' || key=='V') showDebug = !showDebug;
  if (key=='p' || key=='P') saveFrame("blow_candle_####.png");
}

void relight(){
  flameAlpha = 0;
  flameHeight = 10;
  state = RELIGHT;
}
