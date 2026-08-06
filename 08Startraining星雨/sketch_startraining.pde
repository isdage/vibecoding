/**
 * Star Rain with Ripples — stars + flicker + mic wind + responsive window
 * bg: #f9f9f9; rain: #7AA6CA; star: #F9F452
 * 操作：
 *  - 向麦克风吹气：雨被风吹斜
 *  - A / D：切换风向（左/右）
 *  - S：保存截图
 *  - 可拖拽改变窗口大小（响应式）
 */

import processing.sound.*;

ArrayList<Drop> drops;
float groundY;

// —— 配色 —— //
color BG_COL    = #ffffff;   // 背景
color RAIN_COL  = #7AA6CA;   // 雨滴 + 蓝色涟漪
color LINE_COL  = #add8e6;   // 地平线
color STAR_COL  = #F9F452;   // 星星 + 黄色涟漪

// —— 频率/概率（基础值） —— //
float spawnProbBase = 0.10;  // 基础生成概率/帧（参照 800x1000）
float starProb      = 0.25;  // 星星雨滴比例
final int REF_W = 800, REF_H = 1000;   // 参考画幅
float areaFactor;                           // 面积自适应因子

// —— 麦克风风力 —— //
AudioIn mic;
Amplitude amp;
float wind = 0;             // 实际风
float windTarget = 0;       // 目标风
int   windDir = +1;         // 风向：+1 右，-1 左

// —— 响应式：记录窗口变化 —— //
int prevW, prevH;

void settings() {
  size(800, 1000, P2D);
  smooth(8);
}

void setup() {
  background(BG_COL);
  drops = new ArrayList<Drop>();
  groundY = height * 0.75;

  // 允许窗口可调整大小
  surface.setResizable(true);

  // 初始面积系数
  areaFactor = (float)width * height / (REF_W * (float)REF_H);

  // 音频输入
  mic = new AudioIn(this, 0);
  mic.start();
  amp = new Amplitude(this);
  amp.input(mic);

  prevW = width;
  prevH = height;
}

void draw() {
  // —— 监听窗口尺寸变化 —— //
  if (width != prevW || height != prevH) {
    onResize();
    prevW = width;
    prevH = height;
  }

  background(BG_COL);

  // —— 将麦克风音量映射成风力（并平滑）——
  float level = amp.analyze();  // 0..~0.4
  windTarget = map(constrain(level, 0, 0.30), 0, 0.30, 0, 8.0) * windDir;
  wind = lerp(wind, windTarget, 0.12);

  // —— 按面积自适应的生成概率 —— //
  float spawnProb = spawnProbBase * areaFactor;
  if (random(1) < spawnProb) {
    boolean isStar = random(1) < starProb;
    drops.add(new Drop(random(width), -20, isStar));
  }

  // 地面线
  stroke(LINE_COL);
  strokeWeight(1.5);
  line(0, groundY, width, groundY);

  // 更新 & 绘制
  for (int i = drops.size()-1; i >= 0; i--) {
    Drop d = drops.get(i);
    d.update();
    d.display();
    if (d.dead) drops.remove(i);
  }

  drawHUD(level);
}

// —— 尺寸变化时的处理 —— //
void onResize() {
  // 重新计算地面位置（保持 3/4 高度）
  groundY = height * 0.75;

  // 重新计算生成密度的面积系数
  areaFactor = (float)width * height / (REF_W * (float)REF_H);

  // 避免已有雨滴越界：超出边界就标记死亡
  for (Drop d : drops) {
    if (d.y > height + 20 || d.x < -20 || d.x > width + 20) d.dead = true;
    // 若地面上移，正在下落的雨滴撞地条件也要同步
    if (!d.splashed && d.y >= groundY) {
      d.y = groundY;
      d.splashed = true;
      int n = d.isStar ? 4 : 3;
      for (int i=0; i<n; i++) d.ripples.add(new Ripple(d.x, groundY, d.isStar));
    }
  }
}

class Drop {
  float x, y, vy;
  boolean isStar;
  boolean splashed = false;
  boolean dead = false;
  ArrayList<Ripple> ripples = new ArrayList<Ripple>();
  int trailLen;
  float flickerPhase;     // 星星闪烁相位
  float flickerFreq;      // 星星闪烁频率

  Drop(float x, float y, boolean isStar) {
    this.x = x;
    this.y = y;
    this.isStar = isStar;
    vy = random(6, 10);
    trailLen = int(random(6, 12));
    flickerPhase = random(TWO_PI);
    flickerFreq  = random(0.15, 0.30);
  }

  void update() {
    if (!splashed) {
      y += vy;
      x += wind; // 风导致水平漂移
      if (y >= groundY) {
        y = groundY;
        splashed = true;
        int n = isStar ? 4 : 3;  // 星星触地多一点圈
        for (int i=0; i<n; i++) ripples.add(new Ripple(x, groundY, isStar));
      }
    } else {
      for (Ripple r : ripples) r.update();
      if (allRipplesDead()) dead = true;
    }
  }

  void display() {
    color c = isStar ? STAR_COL : RAIN_COL;

    if (!splashed) {
      // 尾迹（随风倾斜）
      stroke(c);
      strokeWeight(1.2);
      for (int i=0; i<trailLen; i++) {
        float ty = y - i*vy*0.7;
        float tx = x - i*wind*0.7;
        if (ty > 0) point(tx, ty);
      }

      if (isStar) drawStarFlicker(x, y, 6, c, flickerPhase, flickerFreq);
      else        drawCross(x, y, 5, c);
    } else {
      for (Ripple r : ripples) r.display();
      if (isStar) drawStarFlicker(x, y, 8, c, flickerPhase, flickerFreq);
      else        drawCross(x, y, 7, c);
    }
  }

  boolean allRipplesDead() {
    for (Ripple r : ripples) if (!r.dead) return false;
    return true;
  }
}

class Ripple {
  float x, y, r, maxR, alpha;
  boolean dead = false;
  boolean starRipple;

  Ripple(float x, float y, boolean isStar) {
    this.x = x; this.y = y;
    this.starRipple = isStar;
    r = 5;
    maxR = random(60, 120);
    alpha = 180;
  }

  void update() {
    if (!dead) {
      r += 1.5;
      alpha -= 1.5;
      if (r > maxR || alpha <= 0) dead = true;
    }
  }

  void display() {
    if (dead) return;
    noFill();
    stroke(starRipple ? STAR_COL : RAIN_COL, alpha);
    strokeWeight(1.1);
    ellipse(x, y, r*2, r*2);
  }
}

// —— 基础十字雨点 —— //
void drawCross(float cx, float cy, float s, color c) {
  stroke(c);
  strokeWeight(1.5);
  line(cx-s, cy, cx+s, cy);
  line(cx, cy-s, cx, cy+s);
}

// —— 星星：带闪烁与简易光晕 —— //
void drawStarFlicker(float cx, float cy, float baseSize, color c, float phase, float freq) {
  float blink = 0.6 + 0.4 * (0.5 + 0.5 * sin(frameCount*freq + phase));
  float s  = baseSize * (0.9 + 0.2*blink);
  float a  = 160 + 80*blink;     // 主体不透明度
  float ag = 70  + 50*blink;     // 光晕不透明度

  // 光晕
  stroke(c, ag);
  strokeWeight(3.6);
  line(cx-s, cy, cx+s, cy);
  line(cx, cy-s, cx, cy+s);

  // 主体
  stroke(c, a);
  strokeWeight(1.8);
  line(cx-s*0.9, cy, cx+s*0.9, cy);
  line(cx, cy-s*0.9, cx, cy+s*0.9);
}

// —— HUD：随窗口响应布局 —— //
void drawHUD(float level){
  int margin = max(12, int(min(width, height) * 0.015));
  int barW   = max(160, int(width * 0.22));
  int barH   = 36;

  noStroke();
  fill(0, 15); rect(margin, margin, barW, barH, 6);

  // 麦克风音量（灰）
  float volW = map(constrain(level,0,0.30), 0, 0.30, 0, barW);
  fill(120,140,160,160); rect(margin, margin, volW, barH, 6);

  // 实际风力（蓝）
  float windW = map(constrain(abs(wind),0,8), 0, 8, 0, barW);
  fill(RAIN_COL, 220); rect(margin, margin, windW, barH, 6);

  fill(#4A4A4A);
  textSize(12); textAlign(LEFT, CENTER);
  String dir = windDir>0 ? "→" : "←";
  text("Blow to tilt " + dir + "  (A/D dir, S save)", margin+6, margin + barH*0.5);
}

void keyPressed() {
  if (key=='S' || key=='s') saveFrame("star_rain_####.png");
  if (key=='A' || key=='a') windDir = -1;
  if (key=='D' || key=='d') windDir = +1;
}
