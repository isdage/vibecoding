// 西瓜插画（果肉&果皮渐变 + 椭圆籽）+ 牙印“咬一口” + 方案2：弧线溅射（克制版）
// R 重置；S 保存
// 重要优化：背景渐变缓存到离屏图层，提升帧率；Retina 上 pixelDensity(1)

 /* ===== 可调参数 ===== */
color SEED_COLOR = color(25, 20, 15); // 籽颜色
float SEED_W = 8;
float SEED_H = 18;
int   SEED_COUNT = 15;

float R = 250;                        // 西瓜半径（果肉外缘）
float OFFSET_Y = -100;                // 西瓜垂直偏移（负=向上）

// 背景渐变
color BG_INNER = color(255, 200, 120);
color BG_OUTER = color(255);

PVector CENTER = new PVector();       // 西瓜中心（世界坐标）

/* ===== 数据结构：籽 & 咬痕 ===== */
class Seed {
  float x, y, rot, s;
  Seed(float x, float y, float rot, float s) { this.x=x; this.y=y; this.rot=rot; this.s=s; }
}
ArrayList<Seed> seeds = new ArrayList<Seed>();

class Bite {
  float x, y, r; int lobes; ArrayList<PVector> offsets = new ArrayList<PVector>();
  Bite(float x, float y, float r, int lobes) {
    this.x=x; this.y=y; this.r=r; this.lobes=lobes;
    for (int i=0;i<lobes;i++){
      float ang = random(TWO_PI);
      float rr  = random(r*0.20, r*0.55);
      offsets.add(new PVector(cos(ang)*rr, sin(ang)*rr));
    }
  }
}
ArrayList<Bite> bites = new ArrayList<Bite>();

/* ===== 方案2：弧线溅射粒子 & 触地淡渍 ===== */
class ArcDrop {
  // 阶段1：沿圆弧短距离飞行；阶段2：重力下落
  PVector center;     float Rarc;  float a0, a1;  float t, dur;
  boolean falling = false;  PVector p, v;  float rad;  float alpha = 220;

  ArcDrop(float cx, float cy, float Rarc, float a0, float a1, float dur, float rad){
    center = new PVector(cx, cy); this.Rarc = Rarc; this.a0 = a0; this.a1 = a1;
    this.dur = max(2, dur); this.rad = rad; t = 0;
  }
  boolean update(){
    if (!falling){
      t += 1.0/dur;
      float a = lerp(a0, a1, constrain(t,0,1));
      p = new PVector(center.x + cos(a)*Rarc, center.y + sin(a)*Rarc);
      if (t >= 1.0){
        falling = true;
        float da = a1 - a0;
        float tangA = a1 + (da>0 ? HALF_PI : -HALF_PI);
        v = new PVector(cos(tangA)*random(0.9,1.6), sin(tangA)*random(0.2,1.0));
      }
    }else{
      v.mult(0.992);          // 空气阻力
      v.y += 0.28;            // 重力稍大一点，掉得更利索
      p.add(v);
      alpha *= 0.992;
      if (p.y > height-10 || alpha < 6){
        spawnSplat(p.x, min(p.y, height-8), max(4, rad*3));
        return false;
      }
    }
    return true;
  }
  void render(){
    noStroke();
    fill(255, 90, 70, alpha);
    ellipse(p.x, p.y, rad*2, rad*2);
  }
}

class Splat {
  PVector p; float baseR; float life = 48;
  Splat(float x, float y, float R0){ p=new PVector(x,y); baseR=R0; }
  boolean update(){ life--; return life>0; }
  void render(){
    float t = life/48.0;
    noStroke();
    fill(255, 100, 80, 60*t);
    ellipse(p.x, p.y, baseR*1.0, baseR*0.7);
    fill(255, 100, 80, 40*t);
    ellipse(p.x + baseR*0.25, p.y, baseR*0.4, baseR*0.28);
  }
}

ArrayList<ArcDrop> drops = new ArrayList<ArcDrop>();
ArrayList<Splat>   splats = new ArrayList<Splat>();

void spawnArcSplash(float bx, float by){
  // 出射方向：由西瓜中心指向咬点（外法线），在其两侧做小扇形
  PVector n = new PVector(bx - CENTER.x, by - CENTER.y);
  if (n.magSq() < 1) n.set(0, -1);
  float baseA = atan2(n.y, n.x);

  int N = (int)random(6, 12);           // 粒子数量（克制）
  for (int i=0;i<N;i++){
    float spread = radians(60);          // 扇形±28°
    float aStart = baseA + random(-spread, spread);
    float sweep  = random(PI/8, PI/4);   // 1/6~1/4 圈
    if (random(1) < 0.5) sweep = -sweep;

    float radius = random(16, 40);       // 弧半径
    float dur    = random(6, 10);        // 弧线时长（帧）——足够短但不卡
    float rad    = random(2.5, 4.5);     // 粒子大小

    ArcDrop d = new ArcDrop(bx, by, radius, aStart, aStart + sweep, dur, rad);
    d.update(); // 把起点挪到弧线上，避免与咬点重叠
    drops.add(d);
  }
  loop();  // 开始动画
}

void spawnSplat(float x, float y, float R0){
  splats.add(new Splat(x, y, R0));
  loop();
}

/* ===== 离屏图层 ===== */
PGraphics fruitPG;   // 西瓜层
PGraphics bgPG;      // 背景缓存
boolean dirty = true;        // 需要重建果层？
boolean animating = false;   // 是否需要继续循环

/* ===== 生命周期 ===== */
void setup() {
  size(800, 1100);           // Java2D 渲染器最稳
  pixelDensity(1);           // 避免高分屏像素翻倍导致掉帧
  frameRate(60);
  noLoop();

  CENTER.set(width/2.0, height/2.0 + OFFSET_Y);

  buildBG();                 // 背景只算一次
  generateSeeds();
  buildFruitPG();
}

void draw() {
  // 背景直接贴缓存图（极快）
  image(bgPG, 0, 0);

  if (dirty) {
    rebuildFruitLayer();
    dirty = false;
  }
  imageMode(CORNER);
  image(fruitPG, 0, 0);

  // 渲染地面淡渍
  for (int i=splats.size()-1; i>=0; i--){
    if (!splats.get(i).update()) splats.remove(i);
    else splats.get(i).render();
  }

  // 更新 & 渲染弧线溅射
  animating = !drops.isEmpty() || !splats.isEmpty();
  for (int i=drops.size()-1; i>=0; i--){
    ArcDrop d = drops.get(i);
    if (!d.update()) drops.remove(i);
    else d.render();
  }

  if (!animating && !dirty) noLoop();
}

/* ===== 交互 ===== */
void mousePressed() {
  if (!pointInsideWatermelon(mouseX, mouseY)) return;

  float biteR = random(42, 58);       // 每口主半径
  int   lobes = (int)random(2, 4);    // 小瓣数量（2~3）
  bites.add(new Bite(mouseX, mouseY, biteR, lobes));

  spawnArcSplash(mouseX, mouseY);     // 弧线溅射（克制）
  dirty = true;
  loop();
}

void keyPressed() {
  if (key=='r' || key=='R') {
    bites.clear(); drops.clear(); splats.clear();
    dirty = true; loop();
  }
  if (key=='s' || key=='S') { saveFrame("watermelon_bite_####.png"); }
}

/* ===== 构建/重建 ===== */
void buildFruitPG() {
  if (fruitPG != null) fruitPG.dispose();
  fruitPG = createGraphics(width, height); // Java2D
}

void rebuildFruitLayer() {
  fruitPG.beginDraw();
  fruitPG.clear();                // 全透明
  drawWatermelon(fruitPG);        // 画完整西瓜（含籽）
  applyBites(fruitPG);            // 像素级抠除牙印
  fruitPG.endDraw();
}

/* ===== 背景（缓存一次） ===== */
void buildBG() {
  if (bgPG != null) bgPG.dispose();
  bgPG = createGraphics(width, height);
  bgPG.beginDraw();
  bgPG.background(255);
  bgPG.noStroke();
  // 径向渐变分段少一点即可（比如 220 段），肉眼观感一致、性能提升巨大
  float BG_RADIUS = max(width, height)/2.0;
  for (float rr = BG_RADIUS; rr > 0; rr -= 2) { // 步长 2
    float t = map(rr, 0, BG_RADIUS, 0, 1);
    bgPG.fill(lerpColor(BG_INNER, BG_OUTER, t));
    bgPG.ellipse(width/2.0, height/2.0, rr*2, rr*2);
  }
  bgPG.endDraw();
}

/* ===== 西瓜绘制（到指定图层） ===== */
void drawWatermelon(PGraphics pg) {
  pg.pushMatrix();
  pg.translate(CENTER.x, CENTER.y);
  pg.rotate(PI); // 倒过来

  // 外皮渐变（绿）
  arcGradient(pg, 0, 0, R*2+20, R*2+20, PI, TWO_PI, color(21,136,79), color(84,170,73));
  // 白皮
  pg.noStroke();
  pg.fill(250, 245, 200);
  pg.arc(0, 0, R*2, R*2, PI, TWO_PI, CHORD);
  // 果肉渐变（红）
  arcGradient(pg, 0, 0, R*2-40, R*2-40, PI, TWO_PI, color(253,85,59), color(239,58,36));

  // 籽
  pg.noStroke();
  pg.fill(SEED_COLOR);
  for (Seed s : seeds) {
    pg.pushMatrix();
    pg.translate(s.x, s.y);
    pg.rotate(s.rot);
    pg.ellipse(0, 0, SEED_W * s.s, SEED_H * s.s);
    pg.popMatrix();
  }
  pg.popMatrix();
}

/* 弧形渐变（指定图层） */
void arcGradient(PGraphics pg, float x, float y, float w, float h,
                 float start, float stop, color c1, color c2) {
  int steps = 80;
  pg.noStroke();
  for (int i = 0; i < steps; i++) {
    float t = map(i, 0, steps-1, 0, 1);
    pg.fill(lerpColor(c1, c2, t));
    float ww = lerp(w, 0, float(i)/steps);
    float hh = lerp(h, 0, float(i)/steps);
    pg.arc(x, y, ww, hh, start, stop, CHORD);
  }
}

/* 生成固定籽（西瓜本地坐标） */
void generateSeeds() {
  seeds.clear();
  randomSeed(2025);
  for (int i = 0; i < SEED_COUNT; i++) {
    float ang = random(PI+0.25, TWO_PI-0.25);
    float rr  = (R-80) * random(0.3, 0.9);
    float sx = cos(ang) * rr;
    float sy = sin(ang) * rr;
    float rot = random(-PI/8, PI/8);
    float sc  = random(0.9, 1.1);
    seeds.add(new Seed(sx, sy, rot, sc));
  }
}

/* 命中判断（世界坐标） */
boolean pointInsideWatermelon(float x, float y) {
  float dx = x - CENTER.x;
  float dy = y - CENTER.y;
  float outer = R + 12;                  // 包含绿皮
  boolean inCircle = (dx*dx + dy*dy) <= outer*outer;
  boolean inLowerHalfWithTolerance = y >= CENTER.y - 24;  // 倒置→可咬区域在下侧
  return inCircle && inLowerHalfWithTolerance;
}

/* 像素级抠除牙印 */
void applyBites(PGraphics g) {
  g.loadPixels();
  int w = g.width, h = g.height;

  for (Bite b : bites) {
    int Rpx = int(b.r);
    int cx = int(b.x), cy = int(b.y);
    int x0 = max(0, cx - Rpx*2), x1 = min(w-1, cx + Rpx*2);
    int y0 = max(0, cy - Rpx*2), y1 = min(h-1, cy + Rpx*2);

    for (int yy = y0; yy <= y1; yy++) {
      for (int xx = x0; xx <= x1; xx++) {
        boolean cut = dist(xx, yy, cx, cy) < b.r;
        if (!cut) {
          for (PVector off : b.offsets) {
            if (dist(xx, yy, cx + off.x, cy + off.y) < b.r * 0.7) { cut = true; break; }
          }
        }
        if (cut) {
          int idx = yy * w + xx;
          int c = g.pixels[idx];
          g.pixels[idx] = c & 0x00FFFFFF; // 置 alpha=0（真正抠除）
        }
      }
    }
  }
  g.updatePixels();
}
