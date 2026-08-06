/**
 * Dandelion — elegant gradient + slow grow + mic blow + glow since grow & after scatter
 * + Responsive / 4:3 toggle
 *
 * 操作：
 *  - 吹气（麦克风）或 [Space]：吹散
 *  - [R]：重置并触发生长动画
 *  - [S]：保存一帧
 *  - 可拖拽改变窗口尺寸（RESPONSIVE=true 时）
 */

import processing.sound.*;

// ==== Config ====
final boolean RESPONSIVE = true;   // ← 改为 false 切固定 4:3
final int FIXED_W = 1200, FIXED_H = 900; // 4:3

// ==== Mic ====
AudioIn mic;
Amplitude amp;
float lvlSmooth = 0;
float THRESH = 0.06; // 触发阈值（按设备 0.04~0.10 调）

// ==== Visual ====
color BG_TOP = #FDF7EF, BG_BTM = #A5D9D2;
color GLOW_WARM = #FFFFFF, GLOW_COOL = #FDF7EF;
color STEM_COL  = #FFFFFF, NODE_COL  = #FFFFFF;

// ==== Glow（从生长开始渐显，吹散后继续）====
float glowPhase = 0;        // 呼吸相位
float glowAlpha = 0;        // 光晕整体透明度 0..1（渐显用）
float glowFadeSpeed = 0.02; // 每帧渐显速度（越小越慢）

// ==== Geometry ratios (相对尺寸，便于响应式) ====
// 以初始 900×1200 的最小边为 900、height 为 1200 估算得出：
final float HEADR_FRAC    = 120f / 900f;   // 头半径 ≈ 0.133 * min(width,height)
final float STEMLEN_FRAC  = 340f / 1200f;  // 茎长    ≈ 0.283 * height
final float CY_FRAC       = 0.58f;         // 花心 y 比例（x 始终 0.5）

// ==== State ====
Dandelion flower;
int prevW, prevH;

void settings(){
  if (RESPONSIVE) {
    size(1200, 900, P2D); // 初始仍给 4:3，之后可拖拽
  } else {
    size(FIXED_W, FIXED_H, P2D); // 固定 4:3
  }
  smooth(8);
}

void setup(){
  if (RESPONSIVE) surface.setResizable(true);
  initMic();
  flower = new Dandelion(width*0.5, height*CY_FRAC, min(width,height)*HEADR_FRAC, height*STEMLEN_FRAC);
  prevW = width; prevH = height;
}

void draw(){
  // 尺寸变化监听（RESPONSIVE 时）
  if (RESPONSIVE && (width != prevW || height != prevH)) {
    onResize(prevW, prevH, width, height);
    prevW = width; prevH = height;
  }

  drawBg();

  // 麦克风音量（平滑）
  float lvl = amp.analyze();
  lvlSmooth = lerp(lvlSmooth, lvl, 0.18);

  // 吹散
  if (!flower.scattered && lvlSmooth > THRESH) {
    float power = map(constrain(lvlSmooth, 0, 0.25), 0, 0.25, 8.5, 18.0);
    flower.scatter(power);
  }

  flower.update();

  // —— 发光策略：从生长开始就渐显；吹散后也继续呼吸 —— //
  glowAlpha = min(1.0, glowAlpha + glowFadeSpeed); // 持续向 1 过渡
  glowPhase += 0.06; // 呼吸相位推进（无论是否散开都闪动）

  flower.render();
  hud();
}

/* ==================== Dandelion ==================== */
class Dandelion {
  float cx, cy;   // 中心
  float headR;    // 头半径
  float stemLen;  // 茎长

  ArrayList<Seed> seeds = new ArrayList<Seed>();
  boolean scattered = false;

  // 生长（放慢）
  boolean growing = true;
  int growStartMillis;
  int growDur = 2600;      // 单支生长时长（慢）
  int growDelayMax = 1500; // 分支错峰最大延迟（慢）

  // 记录旧几何，供 resize 时比例换算
  float prevHeadR, prevCX, prevCY;

  Dandelion(float cx, float cy, float headR, float stemLen){
    this.cx = cx; this.cy = cy; this.headR = headR; this.stemLen = stemLen;
    buildSeeds();
    startGrow();
    prevHeadR = headR; prevCX = cx; prevCY = cy;
  }

  void buildSeeds(){
    seeds.clear();
    int rings = 4;
    for (int r=0; r<rings; r++){
      float rr = map(r, 0, rings-1, headR*0.55, headR*0.98);
      int count = int(map(r, 0, rings-1, 18, 30));
      for (int i=0; i<count; i++){
        float a = TWO_PI*(i+0.2)/count + random(-0.04,0.04);
        float fx = cx + cos(a)*rr;
        float fy = cy + sin(a)*rr;
        Seed s = new Seed(fx, fy, a, cx, cy);
        s.growDelay = int(random(growDelayMax)); // 冒出节奏
        seeds.add(s);
      }
    }
  }

  void startGrow(){
    scattered = false;
    growing = true;
    glowAlpha = 0; // 新一轮生长从“未点亮”开始 → 渐显
    growStartMillis = millis();
    for (Seed s : seeds){ s.attached = true; s.grow = 0; s.grown = false; }
  }

  void scatter(float strength){
    scattered = true;
    growing = false;
    // 不清零 glowAlpha → 吹散后仍发光
    for (Seed s : seeds){
      PVector dir = PVector.sub(s.currentAttachPos(cx,cy), new PVector(cx, cy));
      if (dir.magSq()<1) dir = new PVector(0,-1);
      dir.normalize();
      dir.y -= 0.25; dir.normalize();
      s.detach(dir.mult(strength), cx, cy);
    }
  }

  void update(){
    // 生长推进（慢速）
    if (growing){
      int now = millis();
      boolean allGrown = true;
      for (Seed s : seeds){
        if (!s.grown){
          float t = (now - growStartMillis - s.growDelay) / (float)growDur;
          s.grow = constrain(t, 0, 1);
          if (s.grow < 1.0) allGrown = false;
          else s.grown = true;
        }
      }
      if (allGrown) growing = false;
    }
    // 飞行动力学
    for (Seed s:seeds) s.update();
  }

  void render(){
    // 茎
    stroke(STEM_COL, 180);
    strokeWeight(max(2, min(width,height)*0.004));
    line(cx, cy+headR*0.12, cx, cy+stemLen);

    // 头部：柔光 + 扇形
    pushMatrix(); translate(cx, cy);
    drawHeadGradient(headR);
    drawHeadSlices(headR);
    popMatrix();

    // 分支线 & 端点
    for (Seed s:seeds) s.renderBranch(cx, cy);
    for (Seed s:seeds) s.renderCap(cx, cy);
  }

  // —— 响应式：尺寸变化时调用 —— //
  void onResize(int oldW, int oldH, int newW, int newH){
    // 更新几何（按比例）
    prevHeadR = headR; prevCX = cx; prevCY = cy;

    cx = newW * 0.5;
    cy = newH * CY_FRAC;
    headR   = min(newW, newH) * HEADR_FRAC;
    stemLen = newH * STEMLEN_FRAC;

    float sx = newW / (float)oldW;
    float sy = newH / (float)oldH;

    // 1) 附着终点：按“角度 + 半径比”重算（更稳）
    for (Seed s : seeds){
      // 旧半径与方向
      float rOld = dist(prevCX, prevCY, s.axFinal, s.ayFinal);
      float rFrac = (prevHeadR>0)? (rOld/prevHeadR) : 1;
      float rNew = rFrac * headR;
      s.axFinal = cx + cos(s.a) * rNew;
      s.ayFinal = cy + sin(s.a) * rNew;

      // 花心点更新
      s.cx0 = cx; s.cy0 = cy;

      // 2) 已经在飞的粒子：用窗口缩放比例仿射
      if (!s.attached){
        s.p.x = (s.p.x - prevCX) * (headR/prevHeadR) + cx; // 以中心为参考（更自然）
        s.p.y = (s.p.y - prevCY) * (headR/prevHeadR) + cy;
        // 速度不缩放也可以，保持动感；如需更严谨可乘以 headR/prevHeadR
      }
    }
  }
}

/* ====================== Seed ====================== */
class Seed {
  // 最终附着点
  float axFinal, ayFinal;
  float a; // 方向角
  boolean attached = true;

  // 生长：从中心 -> 最终点
  float cx0, cy0;
  float grow = 0;      // 0..1
  boolean grown = false;
  int growDelay = 0;

  // 飞行
  PVector p = new PVector();
  PVector v = new PVector();
  PVector acc = new PVector();
  float mass = random(0.9, 1.2);

  // 造型
  float len = random(38, 52);
  float cap = random(6, 9);

  // 发光相位差（避免同频）
  float pulseOffset = random(TWO_PI);

  Seed(float axf,float ayf,float dir,float cx0,float cy0){
    this.axFinal=axf; this.ayFinal=ayf; this.a=dir; this.cx0=cx0; this.cy0=cy0;
    p.set(axf, ayf);
  }

  // 当前附着点（带缓出曲线）
  PVector currentAttachPos(float cx, float cy){
    float g = constrain(grow, 0, 1);
    g = 1 - pow(1 - g, 3); // easeOutCubic
    float x = lerp(cx, axFinal, g);
    float y = lerp(cy, ayFinal, g);
    return new PVector(x, y);
  }

  PVector pos(float cx, float cy){ return attached ? currentAttachPos(cx,cy) : p.copy(); }

  void detach(PVector v0, float cx, float cy){
    attached = false;
    PVector at = currentAttachPos(cx,cy);
    p.set(at.x, at.y);
    v.set(v0);
  }

  void update(){
    if (attached) return;
    // 空气/浮力/噪声风
    PVector drag = v.copy().mult(-0.035);
    PVector buoy = new PVector(0, -0.05);
    float n = noise(p.x*0.004, p.y*0.004, frameCount*0.01);
    PVector gust = new PVector(map(n,0,1,-0.12,0.12), map(n,0,1,-0.06,0.04));
    acc.set(0,0);
    acc.add(drag).add(buoy).add(gust).div(mass);
    v.add(acc); v.limit(8);
    p.add(v);
  }

  // 分支线
  void renderBranch(float cx, float cy){
    if (attached){
      PVector at = currentAttachPos(cx,cy);
      float g = constrain(grow, 0, 1);
      g = 1 - pow(1 - g, 3);
      float L = len * (0.15 + 0.85*g);
      float ex = at.x + cos(a)*L;
      float ey = at.y + sin(a)*L;

      // 光：生长期间就开始 + 渐显 + 呼吸
      if (glowAlpha > 0.01){
        float pulse = 0.5 + 0.5*sin(glowPhase + pulseOffset);
        float alphaF = glowAlpha;
        stroke(255, (26 + 22*pulse) * alphaF); strokeWeight(10); line(at.x, at.y, ex, ey);
        stroke(255, (40 + 32*pulse) * alphaF); strokeWeight(6);  line(at.x, at.y, ex, ey);
      }

      // 主线
      stroke(STEM_COL); strokeWeight(2.2);
      line(at.x, at.y, ex, ey);
    } else {
      float dir = atan2(v.y, v.x);
      float ex = p.x + cos(dir)*len;
      float ey = p.y + sin(dir)*len;

      // 光：吹散后仍保留呼吸光（稍淡）
      if (glowAlpha > 0.01){
        float pulse = 0.5 + 0.5*sin(glowPhase + pulseOffset);
        float alphaF = glowAlpha * 0.8; // 飞行时略淡
        stroke(255, (20 + 18*pulse) * alphaF); strokeWeight(8); line(p.x, p.y, ex, ey);
        stroke(255, (30 + 24*pulse) * alphaF); strokeWeight(5); line(p.x, p.y, ex, ey);
      }

      // 主线 + 拖影
      stroke(STEM_COL, 170); strokeWeight(2.2);
      line(p.x, p.y, ex, ey);
      stroke(STEM_COL, 70); line(p.x - v.x*0.4, p.y - v.y*0.4, ex - v.x*0.2, ey - v.y*0.2);
      stroke(STEM_COL, 40); line(p.x - v.x*0.8, p.y - v.y*0.8, ex - v.x*0.4, ey - v.y*0.4);
    }
  }

  // 端点圆
  void renderCap(float cx, float cy){
    if (attached){
      PVector at = currentAttachPos(cx,cy);
      float g = constrain(grow, 0, 1);
      g = 1 - pow(1 - g, 3);
      float L = len * (0.15 + 0.85*g);
      float ex = at.x + cos(a)*L;
      float ey = at.y + sin(a)*L;
      float c  = cap * (0.2 + 0.8*g);

      // 光晕（生长即有 + 渐显 + 呼吸）
      if (glowAlpha > 0.01){
        float pulse = 0.5 + 0.5*sin(glowPhase + pulseOffset);
        float alphaF = glowAlpha;
        noStroke(); fill(255, (40 + 25*pulse) * alphaF); circle(ex, ey, c*2.6);
        fill(255, (22 + 16*pulse) * alphaF); circle(ex, ey, c*3.6);
      }

      noStroke(); fill(NODE_COL, 200 * g + 30);
      circle(ex, ey, c);
    } else {
      float dir = atan2(v.y, v.x);
      float ex = p.x + cos(dir)*len;
      float ey = p.y + sin(dir)*len;

      // 飞行中的端点光晕（保持呼吸）
      if (glowAlpha > 0.01){
        float pulse = 0.5 + 0.5*sin(glowPhase + pulseOffset);
        float alphaF = glowAlpha * 0.85;
        noStroke(); fill(255, (36 + 22*pulse) * alphaF); circle(ex, ey, cap*2.6);
        fill(255, (20 + 14*pulse) * alphaF); circle(ex, ey, cap*3.6);
      }

      noStroke(); fill(NODE_COL, 230);
      circle(ex, ey, cap);
      fill(255, 40); circle(ex, ey, cap*2.2);
    }
  }
}

/* =============== Head (gradient + slices) =============== */
void drawHeadGradient(float R){
  noStroke();
  for (int i=0;i<100;i++){
    float k = i/99.0;
    float r = lerp(R*0.15, R, k);
    color c = lerpColor(GLOW_WARM, GLOW_COOL, pow(k, 1.6));
    fill(c, map(1-k, 0,1, 10, 160));
    circle(0, 0, r*2);
  }
  fill(255, 110); circle(0,0, R*0.4);
}
void drawHeadSlices(float R){
  float[] starts = { radians(-20), radians(30), radians(95), radians(170), radians(235), radians(300) };
  float[] spans  = { radians(24),  radians(18), radians(22), radians(26),  radians(20), radians(18) };
  for (int i=0;i<starts.length;i++){
    fill(255, 28 + (i%2==0?14:6));
    arc(0, 0, R*1.85, R*1.85, starts[i], starts[i]+spans[i], PIE);
  }
}

/* =============== Background & HUD =============== */
void drawBg(){
  for(int y=0;y<height;y++){
    float k = map(y,0,height,0,1);
    stroke(lerpColor(BG_TOP, BG_BTM, k));
    line(0,y,width,y);
  }
  noStroke(); fill(255,18);
  rect(0, height*0.8, width, height*0.2);
}
void hud(){
  int m=16,w=220,h=16;
  noStroke(); fill(0,25); rect(m,m,w,h,6);
  float volW = map(constrain(lvlSmooth,0,0.25),0,0.25,0,w);
  fill(255,180); rect(m,m,volW,h,6);
  stroke(255,200); float tx = m + THRESH/0.25*w; line(tx,m,tx,m+h);
  noStroke(); fill(#345, 160); textSize(12);
  text(
    (RESPONSIVE? "Responsive" : "Fixed 4:3") + 
    "  |  Space:散开  R:重生长  S:保存\nGlowFade="+nf(glowFadeSpeed,1,2)+"  PhaseSpeed=0.06", 
    m, m+h+6
  );
}

/* =============== Resize hook =============== */
void onResize(int oldW, int oldH, int newW, int newH){
  // 更新 flower 的几何与粒子分布
  flower.onResize(oldW, oldH, newW, newH);
}

/* =============== Mic & Keys =============== */
void initMic(){
  mic = new AudioIn(this, 0); mic.start();
  amp = new Amplitude(this);   amp.input(mic);
}
void keyPressed(){
  if (key==' ') { if (!flower.scattered) flower.scatter(14); }
  if (key=='r'||key=='R') {
    // 重置为当前窗口尺寸对应的几何
    flower = new Dandelion(width*0.5, height*CY_FRAC, min(width,height)*HEADR_FRAC, height*STEMLEN_FRAC);
  }
  if (key=='s'||key=='S') saveFrame("dandelion_responsive_####.png");
}
