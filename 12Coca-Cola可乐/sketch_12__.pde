/**
 * Cup split into 3 parts (TopRect, BottomRect, Coke in front)
 * - 可乐水体：只底部两个圆角
 * - 响应式窗口
 * - 背景蓝色范围/浓度可调；对角线直径避免四角灰边
 * - 顶部方块：普通上下渐变；底部方块：圆心渐变
 * - 交互：点击生成冰块（更大，随机角度，自转，中心径向渐变）
 * - 每块冰的上浮力/阻尼/抖动均随机，层次感更强
 * - 气泡：更像泡泡，寿命 0.5–1 秒（若要 3–5 秒，把寿命参数改回 3000/5000）
 */

int prevW, prevH;

void settings() {
  size(900, 1400, P2D);
  smooth(8);
}

/* ===== 容器 ===== */
ArrayList<Ice>    ices    = new ArrayList<Ice>();
ArrayList<Bubble> bubbles = new ArrayList<Bubble>();

/* ===== 背景控制 ===== */
final color BG_CENTER = #39B9EA;
final color BG_EDGE   = #FFFFFF;
float BG_DIAM_K = 1.00;   // 光晕直径（基于对角线）的系数
float BG_BIAS   = 1.6;    // 渐变偏置：>1 蓝更集中

/* ===== 杯子与可乐颜色 ===== */
final color COKE_TOP    = #5B3A05;
final color COKE_BOTTOM = #260003;

/* —— 上/下方块颜色 —— */
final color TOP_COL_TOP = color(255, 255, 255, 100);
final color TOP_COL_BOT = color(255, 255, 255,  50);
final color BOT_CENTER_COL = color(255, 255, 255, 235);
final color BOT_EDGE_COL   = color( 57, 185, 234, 160);
int   RECT_RADIAL_STEPS = 120;
float RECT_RADIAL_BIAS  = 1.4;

/* ===== 吸管参数 ===== */
color STRAW_COL = #111111;
float STRAW_W_FRAC   = 0.055;
float STRAW_LEN_FRAC = 1.1;
float STRAW_ANGLE_DEG= 15;
float STRAW_ALPHA_TOP= 220;
float STRAW_ALPHA_BOT= 60;

/* ===== 柠檬切片 ===== */
color LEMON_RING = #F39A2E;
color LEMON_A    = #FFE060;
color LEMON_B    = #FFC81A;
float LEMON_R_FRAC = 0.32;
int   LEMON_STEPS   = 80;
int   LEMON_SPOKES  = 8;
int   LEMON_SPOKE_ALPHA = 70;

/* ===== 杯子布局（相对比例） ===== */
float CX = 0.50;
float GW = 0.30;
float GH = 0.50;
float BASE_PAD = 0.14;

// 三层高度
float TOP_RATIO    = 0.20;
float BOTTOM_RATIO = 0.40;
float LIQ_RATIO    = 0.72;

float RADIUS_BOTTOM = 0.28;

/* ===== 实际像素（运行时计算） ===== */
float cx, cy;
float glassW, glassH, glassX, glassY;
float topH, bottomH, liqH, radiusBot;
float topLiq, bottomLiq; // 液面与杯底的 y（便于判断位置）

/* ===== 冰块 & 气泡 ===== */
// 冰块：尺寸/动力学/旋转
float ICE_SIZE_FRAC   = 0.30;      // 冰块边长占杯宽
float ICE_ROUND_FRAC  = 0.15;      // 冰块轮廓圆角
float GRAVITY         = 0.34;
float BUOYANCY_BASE   = 0.40;      // ★ 基准浮力（每块冰会随机偏移）
float DRAG_AIR        = 0.98;
float DRAG_WATER      = 0.92;
float BOUNCE_DAMP     = 0.35;
float ICE_ANGLE_RANGE_DEG = 35;    // 初始随机角度范围 ±deg
float ICE_SPIN_AIR        = 0.010; // 空气中角速度（基准）
float ICE_SPIN_WATER      = 0.003; // 液体中角速度（阻尼）
color ICE_CENTER_COL = color(255, 255, 255, 220); // 冰块中心色
color ICE_EDGE_COL   = color(190, 225, 255, 110); // 冰块边缘色
int   ICE_GRAD_STEPS = 64;                          // 冰块渐变层数

// 气泡“更像泡泡”
int   BUBBLE_CAP       = 1400;
float SPAWN_PER_FRAME  = 44;
float SPAWN_PROB       = 0.58;
float BUBBLE_R_MIN     = 0.009;    // 初始半径范围（相对杯宽）
float BUBBLE_R_MAX     = 0.015;
float BUBBLE_GROW_K    = 0.0014;   // 变大速度
float BUBBLE_UP_MIN    = -2.6;     // 初速上浮范围
float BUBBLE_UP_MAX    = -0.1;
// 寿命（当前 0.5–1 秒；如需 3–5 秒改为 3000/5000）
int   BUBBLE_LIFE_MIN_MS = 500;
int   BUBBLE_LIFE_MAX_MS = 1000;
float BUBBLE_RIM_ALPHA  = 220;     // 描边不透明度
float BUBBLE_FILL_ALPHA = 90;      // 内填充透明度
float BUBBLE_RIM_THICK  = 1.0;     // 描边基准线宽
float BUBBLE_WOBBLE_F   = 7.0;     // 呼吸频率
float BUBBLE_WOBBLE_A   = 0.06;    // 呼吸振幅（相对半径）

void setup() {
  surface.setResizable(true);
  computeLayout();
  prevW = width;
  prevH = height;
}

void draw() {
  if (width!=prevW || height!=prevH) {
    computeLayout();
    prevW = width;
    prevH = height;
  }

  // 背景（对角线直径，避免灰角）
  background(BG_EDGE);
  float diag = sqrt(width*width + height*height);
  float dia  = diag * BG_DIAM_K;
  drawRadialGradient(width*0.5, height*0.45, dia,
                     BG_CENTER, BG_EDGE,
                     220, BG_BIAS);

  // 柠檬（杯后面）
  float lemonR = glassW * LEMON_R_FRAC;
  drawLemonSlice(glassX, glassY, lemonR);

  // 杯子三层（含可乐）
  drawCup3Layers();
  
  // 吸管最上层
  drawStraw();
  
  // 冰块 & 气泡（画在可乐上面）
  updateAndDrawIceAndBubbles();


}

/* ---------- 布局计算 ---------- */
void computeLayout() {
  glassW = width * GW;
  glassH = height * GH;
  cx = width * CX;
  float basePadPx = height * BASE_PAD;
  cy = height - basePadPx - glassH * 0.5;

  glassX = cx - glassW/2f;
  glassY = cy - glassH/2f;

  topH    = glassH * TOP_RATIO;
  bottomH = glassH * BOTTOM_RATIO;
  liqH    = constrain(glassH * LIQ_RATIO, 2, glassH);

  radiusBot = glassW * RADIUS_BOTTOM;

  topLiq    = glassY + topH;
  bottomLiq = glassY + glassH;
}

/* ---------- 绘制模块（背景/杯子/吸管/柠檬） ---------- */
void drawRadialGradient(float x, float y, float dia,
                        color cCenter, color cEdge,
                        int steps, float bias) {
  noStroke();
  for (int i = 0; i < steps; i++) {
    float t  = i / float(steps - 1);
    float tb = pow(t, bias);
    float d  = dia * (1.0 - t);
    fill(lerpColor(cEdge, cCenter, tb));
    ellipse(x, y, d, d);
  }
}

void drawVerticalGradientRect(float x, float y, float w, float h,
                              color cTop, color cBot) {
  noFill();
  for (int i = 0; i < int(h); i++) {
    float t = i / h;
    stroke(lerpColor(cTop, cBot, t));
    line(x, y + i, x + w, y + i);
  }
}

void drawRectRadialGradient(float x, float y, float w, float h,
                            color cCenter, color cEdge,
                            int steps, float bias) {
  noStroke();
  for (int i = 0; i < steps; i++) {
    float t  = i / float(steps - 1);
    float tb = pow(1.0 - t, bias);
    color col = lerpColor(cEdge, cCenter, tb);

    float insetX = (w * 0.5) * t;
    float insetY = (h * 0.5) * t;
    float rx = x + insetX;
    float ry = y + insetY;
    float rw = max(1, w - 2*insetX);
    float rh = max(1, h - 2*insetY);

    fill(col);
    rect(rx, ry, rw, rh);
  }
}

void drawVerticalGradientRounded(float x, float y, float w, float h,
                                 color cTop, color cBot,
                                 float r1, float r2, float r3, float r4) {
  noFill();
  for (int i = 0; i < int(h); i++) {
    float yy = y + i;
    float t  = i / h;
    stroke(lerpColor(cTop, cBot, t));
    float left  = x;
    float right = x + w;

    if (i < r1) { float dy = r1 - i; float dx = r1 - sqrt(max(0, r1*r1 - dy*dy)); left += dx; }
    if (i < r2) { float dy = r2 - i; float dx = r2 - sqrt(max(0, r2*r2 - dy*dy)); right -= dx; }

    float ib = int(h) - 1 - i;
    if (ib < r3) { float dy = r3 - ib; float dx = r3 - sqrt(max(0, r3*r3 - dy*dy)); left += dx; }
    if (ib < r4) { float dy = r4 - ib; float dx = r4 - sqrt(max(0, r4*r4 - dy*dy)); right -= dx; }

    line(left, yy, right, yy);
  }
}

void drawCup3Layers() {
  // 顶部：普通上下渐变
  drawVerticalGradientRect(glassX, glassY, glassW, topH,
                           TOP_COL_TOP, TOP_COL_BOT);

  // 底部：圆心渐变
  drawRectRadialGradient(glassX, glassY + glassH - bottomH, glassW, bottomH,
                         BOT_CENTER_COL, BOT_EDGE_COL,
                         RECT_RADIAL_STEPS, RECT_RADIAL_BIAS);

  // 可乐：顶部直角，底部两个圆角
  float cokeY = glassY + topH;
  float cokeH = min(liqH, glassY + glassH - cokeY);
  drawVerticalGradientRounded(glassX, cokeY, glassW, cokeH,
                              COKE_TOP, COKE_BOTTOM,
                              0, 0, radiusBot, radiusBot);
}

void drawStraw() {
  float ox = glassX + glassW * 1.06;
  float oy = glassY - glassH * 0.2;
  float w  = glassW * STRAW_W_FRAC;
  float len= glassH * STRAW_LEN_FRAC;
  float ang= radians(STRAW_ANGLE_DEG);

  pushMatrix();
  translate(ox, oy);
  rotate(ang);

  noStroke();
  for (int i = 0; i < int(len); i++) {
    float t = i / len;
    int a = int(lerp(STRAW_ALPHA_TOP, STRAW_ALPHA_BOT, t));
    fill(red(STRAW_COL), green(STRAW_COL), blue(STRAW_COL), a);
    rect(-w/2, i, w, 1);
  }
  popMatrix();
}

void drawLemonSlice(float cx, float cy, float r) {
  stroke(LEMON_RING);
  strokeWeight(max(1, r * 0.12));
  noFill();
  ellipse(cx, cy, r*2, r*2);

  noStroke();
  for (int i = LEMON_STEPS; i >= 1; i--) {
    float t = i / float(LEMON_STEPS);
    fill(lerpColor(LEMON_A, LEMON_B, 1 - t));
    ellipse(cx, cy, r*2*t, r*2*t);
  }

  fill(255, 140);
  ellipse(cx, cy, r*0.35, r*0.35);

  stroke(255, LEMON_SPOKE_ALPHA);
  strokeWeight(max(1, r * 0.05));
  for (int k = 0; k < LEMON_SPOKES; k++) {
    float a = TWO_PI * k / LEMON_SPOKES;
    float x2 = cx + cos(a) * r * 0.92;
    float y2 = cy + sin(a) * r * 0.92;
    line(cx, cy, x2, y2);
  }
}

/* ---------- 方形中心径向渐变（用于冰块） ---------- */
void drawSquareRadialGradient(float s, color cCenter, color cEdge, int steps) {
  // 在当前坐标系下、以 (0,0) 为中心，绘制边长 s 的方形中心径向渐变
  noStroke();
  float half = s * 0.5;
  for (int i = 0; i < steps; i++) {
    float t  = i / float(steps - 1);     // 0..1 外→内
    float tb = 1.0 - t;                  // 内侧权重
    color col = lerpColor(cEdge, cCenter, tb);
    float inset = t * half;              // 按比例向内收
    float side  = max(1, s - inset*2);
    fill(col);
    rectMode(CENTER);
    rect(0, 0, side, side);
  }
}

/* ---------- 冰块 & 气泡系统（冰块随机浮力/阻尼/抖动） ---------- */
class Ice {
  float x, y, vx, vy;
  float s, r;
  boolean inLiquid=false;

  // 角度 & 自转
  float ang;     // 当前角度
  float angVel;  // 角速度

  // ★ 每块冰的“个性化”参数
  float buoy;    // 浮力
  float dragW;   // 液体阻尼
  float jiggle;  // 轻微抖动幅度

  Ice(float sx, float sy) {
    s = glassW * ICE_SIZE_FRAC;
    r = s * ICE_ROUND_FRAC;

    // 横向夹在杯内
    x = constrain(sx, glassX + s*0.5, glassX + glassW - s*0.5);
    y = sy;
    vx = 0;
    vy = 0;

    // 随机初始角度与方向
    ang    = radians(random(-ICE_ANGLE_RANGE_DEG, ICE_ANGLE_RANGE_DEG));
    angVel = random(1) < 0.5 ? ICE_SPIN_AIR : -ICE_SPIN_AIR;

    // ★ 浮力在基准的 85%~115% 之间随机
    buoy  = BUOYANCY_BASE * random(0.85, 1.15);
    // ★ 阻尼做一点差异：浮力越大，阻尼略大（更“被水拖住”的感觉）
    float t = map(buoy, BUOYANCY_BASE*0.85, BUOYANCY_BASE*1.15, 0, 1);
    dragW = lerp(DRAG_WATER * 0.96, DRAG_WATER * 1.04, constrain(t, 0, 1));
    // ★ 轻微抖动
    jiggle = random(0.02, 0.08);
  }

  void update() {
    float left   = glassX + s*0.5;
    float right  = glassX + glassW - s*0.5;
    float maxY   = (topLiq + liqH) - s*0.6; // 停在可乐里，不触底

    boolean wasInLiquid = inLiquid;
    inLiquid = (y >= topLiq + 1);

    if (!inLiquid) {
      vy += GRAVITY;
      vx *= DRAG_AIR;
      vy *= DRAG_AIR;

      ang += angVel;
      angVel += random(-0.0005, 0.0005);
      angVel = constrain(angVel, -ICE_SPIN_AIR*1.5, ICE_SPIN_AIR*1.5);
    } else {
      // 使用该冰块的个性化浮力/阻尼
      vy += GRAVITY - buoy;
      vx *= dragW;
      vy *= dragW;

      // 轻微随机扰动（层次更自然）
      vx += random(-jiggle, jiggle) * 0.02;

      ang += angVel;
      angVel = lerp(angVel, 0, 0.08);
      angVel += random(-0.0003, 0.0003);
      angVel = constrain(angVel, -ICE_SPIN_WATER*1.5, ICE_SPIN_WATER*1.5);

      if (y > maxY - s*0.15) vy -= 0.20; // 贴底轻推回上方，防止躺底
    }

    x += vx;
    y += vy;

    // 碰壁处理
    if (x < left)  { x = left;  vx *= -BOUNCE_DAMP; }
    if (x > right) { x = right; vx *= -BOUNCE_DAMP; }
    if (inLiquid && y > maxY) { y = maxY; if (vy>0) vy=0; }

    // 入水后在冰块附近持续冒泡
    if (inLiquid) {
      int tries = int(SPAWN_PER_FRAME);
      for (int i=0; i<tries; i++) {
        if (random(1) < SPAWN_PROB && bubbles.size() < BUBBLE_CAP) {
          float bx = x + random(-s*0.5, s*0.5);
          float by = y + random(-s*0.5, s*0.5);
          bx = constrain(bx, glassX+2, glassX+glassW-2);
          by = constrain(by, topLiq+2, topLiq+liqH-2);
          bubbles.add(new Bubble(bx, by));
        }
      }
    }
  }

  void display() {
    pushMatrix();
    translate(x, y);
    rotate(ang);

    // 冰块中心径向渐变
    drawSquareRadialGradient(s, ICE_CENTER_COL, ICE_EDGE_COL, ICE_GRAD_STEPS);

    // 淡描边（可注释掉）
    noFill();
    stroke(255, 100);
    strokeWeight(1.2);
    rectMode(CENTER);
    rect(0, 0, s, s, s * ICE_ROUND_FRAC);
    rectMode(CORNER);

    popMatrix();
  }
}

/* ---------- 气泡 ---------- */
class Bubble {
  float x, y, vx, vy, r, baseR, grow;
  float birthMs, lifeMs;

  Bubble(float sx, float sy) {
    x = sx;
    y = sy;
    vx = random(-0.25, 0.25);
    vy = random(BUBBLE_UP_MIN, BUBBLE_UP_MAX);
    baseR = random(glassW*BUBBLE_R_MIN, glassW*BUBBLE_R_MAX);
    r  = baseR;
    grow = glassW * BUBBLE_GROW_K * random(0.8, 1.2);
    birthMs = millis();
    lifeMs  = int(random(BUBBLE_LIFE_MIN_MS, BUBBLE_LIFE_MAX_MS));
  }

  void update() {
    vx += random(-0.02, 0.02);
    vy -= 0.01;
    x += vx;
    y += vy;

    float age = millis() - birthMs;
    float wobble = 1.0 + BUBBLE_WOBBLE_A * sin(TWO_PI * (age/1000.0) * BUBBLE_WOBBLE_F);
    r = (baseR + grow * (age/1000.0)) * wobble;

    if (x < glassX+2) { x = glassX+2; vx *= -0.6; }
    if (x > glassX+glassW-2) { x = glassX+glassW-2; vx *= -0.6; }
  }

  boolean dead() {
    float age = millis() - birthMs;
    if (age >= lifeMs) return true;       // 寿命到
    if (y <= topLiq + 1) return true;     // 到液面消失
    return false;
  }

  void display() {
    float age = millis() - birthMs;
    float t = constrain(age / lifeMs, 0, 1);
    float alphaFill = (1.0 - t) * BUBBLE_FILL_ALPHA;
    float alphaRim  = (1.0 - t) * BUBBLE_RIM_ALPHA;

    noStroke();
    fill(255, alphaFill);
    ellipse(x, y, r*2, r*2);

    stroke(255, alphaRim);
    strokeWeight(max(1, BUBBLE_RIM_THICK * (r / (glassW*0.008))));
    noFill();
    ellipse(x, y, r*2, r*2);

    noStroke();
    fill(255, alphaRim);
    ellipse(x - r*0.35, y - r*0.35, r*0.55, r*0.55);
  }
}

/* ---------- 更新/绘制合辑 ---------- */
void updateAndDrawIceAndBubbles() {
  for (int i = ices.size()-1; i >= 0; i--) {
    Ice ic = ices.get(i);
    ic.update();
    ic.display();
  }
  for (int i = bubbles.size()-1; i >= 0; i--) {
    Bubble b = bubbles.get(i);
    b.update();
    b.display();
    if (b.dead()) bubbles.remove(i);
  }
}

/* ---------- 交互 ---------- */
void mousePressed() {
  ices.add(new Ice(mouseX, mouseY));
}
