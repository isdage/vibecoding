/**
 * Dreamy Radial Background + Bottle Base — v1.0 (Hollow Radial Bubbles + Bounce)
 * - 泡泡中心透明、边缘亮：无描边，仅径向渐变
 * - 更分散：更大的水平随机 + 轻微防重叠分散力
 * - 边缘弹回：撞到画布边缘弹性反弹（带阻尼）
 * - 其余交互与 v0.9 保持一致（先蘸膜→吹→停吹后清膜）
 */

import processing.sound.*;

// ========== 逻辑画布 + 自适应 ==========
int LOGIC_W = 1024, LOGIC_H = 1236;
float SF = 1.0;

void settings(){
  int ww = min(LOGIC_W, displayWidth  - 80);
  int hh = min(LOGIC_H, displayHeight - 120);
  float sx = ww/(float)LOGIC_W, sy = hh/(float)LOGIC_H;
  SF = min(1.0, min(sx, sy));
  size(int(LOGIC_W*SF), int(LOGIC_H*SF), P2D);
  smooth(8);
}

// ========== 声音（吹气滞回） ==========
AudioIn mic; Amplitude amp;
float level = 0, levelSmooth = 0;
float BLOW_ON  = 0.065, BLOW_OFF = 0.045;
boolean blowing = false;
boolean showDebug = false;

void setup(){
  surface.setTitle("Radial BG + Bottle + Wand + Hollow Bubbles (v1.0)");
  frameRate(60);
  mic = new AudioIn(this, 0);
  amp = new Amplitude(this);
  mic.start(); amp.input(mic);
}

// ========== 背景/瓶/水（与你版本一致，可继续调） ==========
int RINGS = 100;
float BG_CX = LOGIC_W * 0.5, BG_CY = LOGIC_H * 0.50;
float BG_R  = max(LOGIC_W, LOGIC_H) * 0.4;
color BG_IN = color(255), BG_OUT = color(115, 190, 230);

float BTL_W = LOGIC_W * 0.28, BTL_H = LOGIC_H * 0.29;
float BTL_X = LOGIC_W * 0.50, BTL_Y = LOGIC_H * 0.70;
float CORNER = 0;

float NECK_W = BTL_W * 0.70, NECK_H = BTL_H * 0.14;

float WATER_LEVEL = 0.85;
float WAVE_A = 6, WAVE_LEN = 140, WAVE_SPEED = 1.2;
color WATER_TOP = color(140, 205, 255, 180);
color WATER_BOT = color(77, 20, 0, 11);
float WATER_ALPHA = 0.4;
int   WATER_STRIPS = 90;

// 瓶内装饰小气泡
int   N_BUB = 10;
float BUBBLE_MIN = 3, BUBBLE_MAX = 6;
class MiniBubble { float x,y,r,vy; MiniBubble(float x,float y,float r){this.x=x; this.y=y; this.r=r; vy=random(0.2,0.5);} }
ArrayList<MiniBubble> bubz = new ArrayList<>();
void initBubbles(){
  bubz.clear();
  for(int i=0;i<N_BUB;i++){
    float bx = BTL_X - BTL_W*0.48 + random(BTL_W*0.96);
    float by = BTL_Y + BTL_H*0.5 - random(BTL_H*WATER_LEVEL*0.96);
    float br = random(BUBBLE_MIN, BUBBLE_MAX);
    bubz.add(new MiniBubble(bx, by, br));
  }
}

// ========== 泡泡棒 ==========
float WAND_CX = LOGIC_W * 0.22, WAND_CY = LOGIC_H * 0.26;
float WAND_RING_R = LOGIC_W * 0.05;
float WAND_RING_STROKE = 5;
float WAND_RING_GLOW = 0.75;
int   WAND_GLOW_RINGS = 36;
float WAND_STICK_W = 10, WAND_STICK_H = LOGIC_H * 0.15;
color WAND_STICK_COL = color(255);
float WAND_EASE = 0.18;

// 瓶口判定区
float mouthCx, mouthCy, mouthW, mouthH;

// 膜状态
boolean filmAvailable = false;
boolean filmConsumed  = false;

// ========== 泡泡样式（中心透明 + 边缘亮） ==========
boolean BUBBLE_USE_ASPECT = true;
float   BUBBLE_ASPECT_BREATH = 0.08;
float   BUBBLE_ASPECT_SPEED  = 0.6;

int     RADIAL_RINGS = 60;
// 关键：中心透明（alpha 0），边缘带亮度（alpha 可调）
color   BUBBLE_CENTER = color(255, 255, 255, 0);     // 中心完全透明
color   BUBBLE_EDGE   = color(255, 255, 255, 10);   // 边缘淡蓝发亮

// 漂浮/扩散/边界
float   LINGER_FADE_TOP  = 0.003;  // 顶端消散
float   LINGER_FADE_BODY = 0.0013;  // 途中消散
float   BASE_UP_SPEED    = 0.65;   // 上升速度
float   NOISE_DRIFT      = 0.2;   // 噪声漂移更大 → 更分散
float   GROW_RATE        = 1.002;
float   MAX_R            = 190;
float   EDGE_BOUNCE_DAMP = 0.82;   // 碰边阻尼（0~1）

// 轻微“防重叠”分散力（让泡泡散开）
float   SEPARATION_RADIUS = 30;
float   SEPARATION_FORCE  = 0.06;

// ========== 泡泡类 ==========
class Bubble {
  float x, y, r, vx, vy, life, wobbleT, seed;

  Bubble(float x, float y, float baseR, float pow){
    this.x=x; this.y=y;
    this.r = max(6, baseR * (0.8 + pow * 1.8));
    // 更分散：更大的随机水平初速度
    this.vx = random(-0.6, 0.6);
    this.vy = -(BASE_UP_SPEED + pow * 1.4);
    this.life = 1.0;
    this.wobbleT = random(TWO_PI);
    this.seed = random(1000);
  }

  void update(ArrayList<Bubble> all){
    wobbleT += 0.04;

    // 噪声风漂
    float nx = noise(seed, frameCount*0.008) - 0.5;
    float ny = noise(seed+77, frameCount*0.008) - 0.5;
    vx += nx * 0.01;
    vy += ny * 0.006;

    // 轻微防重叠：相互分开
    PVector sep = new PVector(0,0);
    for (Bubble o : all){
      if (o == this) continue;
      float dx = x - o.x, dy = y - o.y;
      float d2 = dx*dx + dy*dy;
      if (d2 > 1 && d2 < SEPARATION_RADIUS*SEPARATION_RADIUS){
        float d = sqrt(d2);
        float w = (SEPARATION_RADIUS - d) / SEPARATION_RADIUS;
        sep.add(dx/d * w, dy/d * w);
      }
    }
    sep.mult(SEPARATION_FORCE);
    vx += sep.x;
    vy += sep.y * 0.5;

    x += vx * NOISE_DRIFT;
    y += vy;

    r *= GROW_RATE;

    // 边界弹回（基于逻辑画布）
    if (x - r < 0){ x = r; vx = abs(vx) * EDGE_BOUNCE_DAMP; }
    if (x + r > LOGIC_W){ x = LOGIC_W - r; vx = -abs(vx) * EDGE_BOUNCE_DAMP; }
    if (y - r < 0){ y = r; vy = abs(vy) * EDGE_BOUNCE_DAMP; }
    if (y + r > LOGIC_H){ y = LOGIC_H - r; vy = -abs(vy) * EDGE_BOUNCE_DAMP; }

    // 更慢消散
    if (y < LOGIC_H*0.10) life -= LINGER_FADE_TOP;
    else                  life -= LINGER_FADE_BODY;

    // 轻微阻尼
    vx *= 0.996;
  }

  boolean dead(){ return life <= 0.02 || r > MAX_R; }

  void draw(){
    pushMatrix();
    translate(x, y);

    if (BUBBLE_USE_ASPECT){
      float breath = BUBBLE_ASPECT_BREATH * sin(wobbleT * BUBBLE_ASPECT_SPEED);
      float ax = 1.0 + breath;
      float ay = 1.0 / (1.0 + breath);
      scale(ax, ay);
    }

    // 无描边的径向渐变：中心透明，外缘亮
    noStroke();
    for (int i = RADIAL_RINGS; i >= 0; --i){
      float t = i/(float)RADIAL_RINGS;                 // 1 → 0
      color c = lerpColor(BUBBLE_EDGE, BUBBLE_CENTER, 1.0 - pow(t, 1.3));
      fill(red(c), green(c), blue(c), alpha(c) * life);
      float rr = r * (0.20 + 0.80 * t);
      ellipse(0, 0, rr*2, rr*2);
    }

    // 细小高光（保持自然）
    noStroke();
    fill(255, 90 * life);
    ellipse(+ r*0.30, - r*0.32, r*0.22, r*0.16);

    popMatrix();
  }
}

ArrayList<Bubble> bubbles = new ArrayList<>();
int spawnCooldown = 0;
int COOLDOWN_MIN = 2, COOLDOWN_MAX = 8;

void draw(){
  background(255);
  pushMatrix();
  translate((width - LOGIC_W*SF)/2, (height - LOGIC_H*SF)/2);
  scale(SF);

  // 背景/瓶/水
  drawRadialGradient(BG_CX, BG_CY, BG_R, BG_IN, BG_OUT, RINGS);
  drawRadialRect(BTL_X, BTL_Y - BTL_H*0.5 - NECK_H*0.5, NECK_W, NECK_H, CORNER, BG_IN, BG_OUT, RINGS);
  drawRadialRect(BTL_X, BTL_Y, BTL_W, BTL_H, CORNER, BG_IN, BG_OUT, RINGS);
  drawWaterInBottle(BTL_X, BTL_Y, BTL_W, BTL_H);

  // 麦克风滞回
  level = amp.analyze();
  levelSmooth = lerp(levelSmooth, level, 0.35);
  if (!blowing && levelSmooth > BLOW_ON) blowing = true;
  if (blowing  && levelSmooth < BLOW_OFF) blowing = false;

  // 棒随鼠标
  PVector m = mouseInLogic();
  WAND_CX = lerp(WAND_CX, m.x, WAND_EASE);
  WAND_CY = lerp(WAND_CY, m.y, WAND_EASE);

  // 瓶口矩形（蘸膜）
  mouthCx = BTL_X;
  mouthCy = BTL_Y - BTL_H*0.5 - NECK_H*0.5;
  mouthW  = NECK_W * 1.00;
  mouthH  = NECK_H * 1.20;

  boolean ringTouchMouth = circleIntersectsRect(WAND_CX, WAND_CY, WAND_RING_R, mouthCx, mouthCy, mouthW, mouthH);

  if (ringTouchMouth) { filmAvailable = true; filmConsumed = false; }

  // 生成泡泡（有膜 + 吹气 + 冷却）
  if (spawnCooldown > 0) spawnCooldown--;
  if (filmAvailable && blowing && spawnCooldown == 0){
    float over = constrain(map(levelSmooth, BLOW_ON, BLOW_ON+0.12, 0, 1), 0, 1);
    int n = 1 + (over > 0.55 ? 1 : 0);
    for (int i=0; i<n; i++){
      float jitterX = random(-WAND_RING_R*0.20, WAND_RING_R*0.20);
      float jitterY = random(-WAND_RING_R*0.12, WAND_RING_R*0.12);
      bubbles.add(new Bubble(WAND_CX + jitterX, WAND_CY + jitterY, WAND_RING_R*0.25, over));
    }
    spawnCooldown = int(lerp(COOLDOWN_MAX, COOLDOWN_MIN, over));
    filmConsumed  = true;
  }

  // 停吹后清膜
  if (!blowing && filmConsumed) { filmAvailable = false; filmConsumed = false; }

  // 更新 & 绘制泡泡
  for (int i=bubbles.size()-1; i>=0; --i){
    Bubble b = bubbles.get(i);
    b.update(bubbles);
    b.draw();
    if (b.dead()) bubbles.remove(i);
  }

  // 画泡泡棒（showGlow 取决于是否有膜）
  boolean showMembrane = filmAvailable;
  drawBubbleWand(WAND_CX, WAND_CY, WAND_RING_R, WAND_RING_STROKE,
                 WAND_STICK_W, WAND_STICK_H, WAND_STICK_COL,
                 WAND_RING_GLOW, WAND_GLOW_RINGS,
                 showMembrane);

  if (showDebug) drawDebug();
  popMatrix();
}

// ========== Helpers ==========
PVector mouseInLogic(){
  float ox = (width  - LOGIC_W*SF)/2.0;
  float oy = (height - LOGIC_H*SF)/2.0;
  float lx = (mouseX - ox) / SF;
  float ly = (mouseY - oy) / SF;
  return new PVector(constrain(lx,0,LOGIC_W), constrain(ly,0,LOGIC_H));
}

boolean circleIntersectsRect(float cx, float cy, float r, float rcx, float rcy, float rw, float rh){
  float halfW = rw * 0.5, halfH = rh * 0.5;
  float nx = constrain(cx, rcx - halfW, rcx + halfW);
  float ny = constrain(cy, rcy - halfH, rcy + halfH);
  float dx = cx - nx, dy = cy - ny;
  return (dx*dx + dy*dy) <= r*r;
}

void drawRadialGradient(float cx, float cy, float r, color inner, color outer, int rings){
  noStroke();
  for (int i = rings; i >= 0; --i){
    float t = i/(float)rings;
    color c = lerpColor(inner, outer, 1.0 - pow(t, 1.2));
    fill(c);
    float rr = r * (0.20 + 0.80 * t);
    ellipse(cx, cy, rr*2, rr*2);
  }
}

void drawRadialRect(float cx, float cy, float w, float h, float corner, color inner, color outer, int rings){
  rectMode(CENTER);
  noStroke();
  for (int i = rings; i >= 0; --i){
    float t = i/(float)rings;
    color c = lerpColor(inner, outer, 1.0 - pow(t, 1.2));
    fill(c);
    float rw = w * (0.2 + 0.8 * t);
    float rh = h * (0.2 + 0.8 * t);
    rect(cx, cy, rw, rh, corner);
  }
}

void drawWaterInBottle(float cx, float cy, float w, float h){
  float topY = cy + h*0.5 - h*WATER_LEVEL;
  float left = cx - w*0.5, right = cx + w*0.5;
  float t = frameCount * 0.016f * WAVE_SPEED;

  noStroke();
  for(int i=0;i<=WATER_STRIPS;i++){
    float k = i/(float)WATER_STRIPS;
    float y1 = lerp(topY, cy + h*0.5, k);
    float y2 = lerp(topY, cy + h*0.5, k + 1.0/WATER_STRIPS);
    color c = lerpColor(WATER_TOP, WATER_BOT, pow(k, 1.2));
    fill(red(c), green(c), blue(c), alpha(c) * WATER_ALPHA);
    rectMode(CORNERS);
    rect(left, y1, right, y2);
  }

  beginShape();
  int segs = max(40, int(w/6));
  for(int i=0;i<=segs;i++){
    float x = lerp(left, right, i/(float)segs);
    float a = TWO_PI * (x-left)/WAVE_LEN + t;
    float y = topY + sin(a) * WAVE_A * (0.85 + 0.15*sin(t*0.7));
    vertex(x, y);
  }
  vertex(right, cy + h*0.5);
  vertex(left,  cy + h*0.5);
  endShape(CLOSE);

  if (bubz.isEmpty()) initBubbles();
  noStroke();
  fill(255, 255, 255, 130 * WATER_ALPHA);
  for (MiniBubble b : bubz){
    ellipse(b.x, b.y, b.r*2, b.r*2);
    b.y -= b.vy;
    if (b.y < topY + 10){
      b.y = cy + h*0.5 - random(10, BTL_H*WATER_LEVEL*0.9);
      b.x = cx - w*0.45 + random(w*0.9);
      b.r = random(BUBBLE_MIN, BUBBLE_MAX);
      b.vy = random(0.2, 0.5);
    }
  }

  stroke(255, 255, 255, 90 * WATER_ALPHA);
  strokeWeight(1.5);
  noFill();
  beginShape();
  for(int i=0;i<=segs;i++){
    float x = lerp(left, right, i/(float)segs);
    float a = TWO_PI * (x-left)/WAVE_LEN + t;
    float y = topY + sin(a) * WAVE_A * (0.85 + 0.15*sin(t*0.7));
    vertex(x, y);
  }
  endShape();
}

// 泡泡棒（showGlow 控制膜）
void drawBubbleWand(float cx, float cy, float r, float ringStroke,
                    float stickW, float stickH, color stickColor,
                    float glowWhere, int glowRings,
                    boolean showGlow){
  rectMode(CENTER);
  noStroke(); fill(stickColor);
  rect(cx, cy + r + stickH*0.5, stickW, stickH);

  stroke(255); strokeWeight(ringStroke); noFill();
  ellipse(cx, cy, r*2, r*2);

  if (showGlow){
    noFill();
    for (int i = 0; i < glowRings; i++){
      float t = i/(float)(glowRings-1);
      float rr = r * (1.0 - glowWhere * t);
      float a  = 110 * (1.0 - t);
      stroke(255, a);
      strokeWeight(max(1, ringStroke * (1.0 - t*0.85)));
      ellipse(cx, cy, rr*2, rr*2);
    }
  }
}

void keyPressed(){
  if (key=='v' || key=='V') showDebug = !showDebug;
}

void drawDebug(){
  pushStyle();
  fill(0, 120); noStroke();
  rect(16, 16, 260, 110, 10);
  fill(255);
  text("mic level: " + nf(level,1,3), 26, 44);
  text("smooth:    " + nf(level,1,3), 26, 64);
  text("blowing:   " + (blowing?"YES":"no"), 26, 84);
  text("film: " + (filmAvailable?"available":"(none)"), 26, 104);
  float bar = map(levelSmooth, 0, 0.2, 0, 200);
  fill(120,200,255); rect(26, 126, bar, 8, 4);
  stroke(255,120,120);
  float thrOn  = map(BLOW_ON,  0, 0.2, 0, 200);
  float thrOff = map(BLOW_OFF, 0, 0.2, 0, 200);
  line(26+thrOn,  126, 26+thrOn,  134);
  line(26+thrOff, 126, 26+thrOff, 134);
  popStyle();
}
