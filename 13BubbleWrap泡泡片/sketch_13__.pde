/**
 * Bubble Wrap
 * - 透明圆 + 椭圆高光
 * - 悬停轻凹；按住加压→爆裂
 * - 波纹：向外扩散并逐渐淡出后消失
 * - SHIFT+Click 修复；R 重置
 * Processing 4+, Java mode
 */

// ===== 设计基础 =====
final float BASE_W = 768;
final float BASE_H = 1098;
final int   COLS0  = 8;
final int   ROWS0  = 12;
final float DIAM0  = 50;
final float GAP0   = 20;

// 背景渐变（中心→边缘）
color BG_CENTER = #FFB23C;
color BG_EDGE   = #FFF3E0;

// 交互参数
float PRESSURE_RATE = 0.9;   // 按住增长速率（每秒）
float POP_THRESHOLD = 1.0;   // 爆阈值
float HOVER_DENT    = 0.08;  // 悬停轻凹比例

// 运行时缩放
int   COLS, ROWS;
float DIAM, GAP, STROKE_W, SCALE;
float step, blockW, blockH, ox, oy;

ArrayList<Bubble> bubbles;
float lastTime;

void settings() {
  size(768, 1098, P2D);     // 可改 fullScreen(P2D);
  smooth(8);
}

void setup() {
  surface.setResizable(true);
  COLS = COLS0;
  ROWS = ROWS0;
  initGrid();
  lastTime = millis()/1000.0;
}

void initGrid() {
  bubbles = new ArrayList<Bubble>();
  updateLayoutParams();
  for (int j=0; j<ROWS; j++) {
    for (int i=0; i<COLS; i++) {
      float x = ox + i*step + DIAM*0.5;
      float y = oy + j*step + DIAM*0.5;
      bubbles.add(new Bubble(x, y, DIAM*0.5));
    }
  }
}

void updateLayoutParams() {
  SCALE    = min(width/BASE_W, height/BASE_H);
  DIAM     = DIAM0 * SCALE;
  GAP      = GAP0  * SCALE;
  STROKE_W = 3     * SCALE;
  step   = DIAM + GAP;
  blockW = (COLS-1)*step + DIAM;
  blockH = (ROWS-1)*step + DIAM;
  ox = (width  - blockW) * 0.5;
  oy = (height - blockH) * 0.5;
}

void draw() {
  // 时间
  float now = millis()/1000.0;
  float dt  = constrain(now - lastTime, 0, 0.05);
  lastTime  = now;

  // 响应式更新位置/半径
  updateLayoutParams();
  int idx = 0;
  for (int j=0; j<ROWS; j++) {
    for (int i=0; i<COLS; i++) {
      Bubble b = bubbles.get(idx++);
      b.x = ox + i*step + DIAM*0.5;
      b.y = oy + j*step + DIAM*0.5;
      b.r0 = DIAM*0.5;
    }
  }

  // 背景
  background(BG_EDGE);
  drawRadialGradient(width*0.5, height*0.48, max(width, height)*0.65, BG_CENTER, BG_EDGE);

  // 悬停目标
  Bubble hovered = null;
  for (Bubble b : bubbles) { if (b.hit(mouseX, mouseY)) { hovered = b; break; } }
  boolean pressing = mousePressed && (mouseButton == LEFT);

  // 更新&绘制
  for (Bubble b : bubbles) b.update(dt, b==hovered, pressing && b==hovered);
  for (Bubble b : bubbles) b.render();
}

/* ============ 单个泡泡类 ============ */
final int INFLATED = 0;
final int POPPED   = 2;

class Bubble {
  float x, y;
  float r0;     // 基准半径
  float r;      // 当前显示半径
  float dent;   // 压陷量（0..1）
  float dentV;  // 压陷速度

  int state = INFLATED;
  float pressure = 0;

  // 爆裂视觉
  float popAnim = 0;   // 核心塌陷进度（0..1）
  float ringT   = 0;   // 波纹时间（0..1，0→1）
  float ringA   = 0;   // 波纹不透明度（0..1，随时间衰减）

  Bubble(float x, float y, float r) {
    this.x=x; this.y=y; this.r0=r; this.r=r;
  }

  boolean hit(float mx, float my) {
    return dist(mx, my, x, y) <= r0 + GAP*0.5;
  }

  void update(float dt, boolean hovered, boolean pressing) {
    // 目标压陷
    float targetDent = 0;
    if (hovered && state != POPPED) targetDent += HOVER_DENT;

    if (pressing && state != POPPED) {
      pressure += PRESSURE_RATE * dt;
      targetDent += min(0.6, pressure*0.7);
      if (pressure >= POP_THRESHOLD) pop();
    } else {
      pressure = max(0, pressure - 0.6*dt);
    }

    // 弹簧到目标压陷（无抖动/无噪声）
    float k = 18, c = 5;
    float a = k*(targetDent - dent) - c*dentV;
    dentV += a*dt;
    dent  += dentV*dt;
    dent  = constrain(dent, 0, 0.75);

    // 半径：仅由压陷决定（无抖动项）
    r = max(2, r0 - dent * r0 * 0.45);

    // 爆裂动画 & 波纹淡出
    if (state == POPPED) {
      popAnim = min(1, popAnim + dt*2.0);

      if (ringA > 0) {
        ringT = min(1, ringT + dt*1.6);      // 向外扩散
        ringA = max(0, 1.0 - ringT);         // 线性淡出（可换成 ease）
      }
    } else {
      popAnim = max(0, popAnim - dt*1.2);
      // 未爆时不画波纹
      ringT = 0;
      ringA = 0;
    }
  }

  void pop() {
    if (state == POPPED) return;
    state = POPPED;
    pressure = 0;
    dentV = 0;
    // 初始化一次性波纹
    ringT = 0;
    ringA = 1;   // 从不透明开始，随后衰减至 0
  }

  void repair() {
    if (state != POPPED) return;
    state = INFLATED;
    popAnim = 0;
    dent = dentV = 0;
    ringT = 0;
    ringA = 0;
  }

  void render() {
    pushMatrix();
    translate(x, y);

    // ===== 未爆/爆初期主体 =====
    if (state != POPPED || popAnim < 0.85) {
      // 主体
      fill(255, 90);
      stroke(255, 220);
      strokeWeight(STROKE_W);
      ellipse(0, 0, r*2, r*2);

      // 椭圆高光
      pushMatrix();
      rotate(radians(-18));
      noStroke();
      fill(255, 140);
      ellipse(-r*0.26, -r*0.28, r*0.46, r*0.22);
      fill(255, 110);
      ellipse(-r*0.08, -r*0.40, r*0.20, r*0.10);
      popMatrix();
    }

    // ===== 残膜与波纹 =====
    if (state == POPPED) {
      // 扁塌残膜
      float base = r0 * (1.0 - 0.65*popAnim);
      float rim  = base * 1.06;
      noStroke();
      fill(255, 70);
      ellipse(0, 0, rim*2.0, rim*2.0*0.96);
      fill(0, 30);
      ellipse(0, base*0.10, base*1.25, base*0.55);

      // 扩散并淡出的波纹
      if (ringA > 0) {
        float rr = lerp(r0*0.9, r0*2.2, easeOutQuad(ringT));
        noFill();
        stroke(255, 160 * ringA);
        strokeWeight(1.5*SCALE);
        ellipse(0, 0, rr*2, rr*2);
        stroke(255, 90 * ringA);
        strokeWeight(1*SCALE);
        ellipse(0, 0, rr*2.6, rr*2.6);
      }
    }

    popMatrix();
  }
}

/* ============ 输入 ============ */
void mousePressed() {
  if (mouseButton == LEFT) {
    for (Bubble b : bubbles) {
      if (b.hit(mouseX, mouseY)) {
        if (keyPressed && keyCode == SHIFT) b.repair();
        break;
      }
    }
  }
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    initGrid();
  }
}

/* ============ 渐变 & 工具 ============ */
void drawRadialGradient(float cx, float cy, float radius, color cInner, color cOuter) {
  noStroke();
  int steps = 180;
  for (int i=steps; i>=0; i--) {
    float t = i/(float)steps;
    float rr = lerp(0, radius, t);
    fill( lerpColor(cOuter, cInner, pow(1.0 - t, 1.4)) );
    ellipse(cx, cy, rr*2, rr*2);
  }
}

float easeOutQuad(float t){ return 1 - (1 - t)*(1 - t); }
