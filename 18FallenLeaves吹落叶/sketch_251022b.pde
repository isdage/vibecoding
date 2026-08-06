import processing.sound.*;

/**
 * Falling Leaves Forest — v1.5 (Clean + Stable)
 * 点击种树 · 吹气落叶 · R 清空 · 仅秋色
 */

// ====== 画布与配色（DIY：在此区调色） ======
int W = 1024, H = 768;
color SKY_TOP = #DDE8F5;   // 天空顶色
color SKY_BOT = #F8FCFF;   // 天空底色
color GROUND  = #E9F4E1;   // 地面色带

// 仅秋色调色板（去掉绿色）
color[] PAL_AUTUMN = { #FFD17A, #FFB14D, #FF8A3C, #D95E2C }; // 金黄→橘红

// ====== 数据结构 ======
ArrayList<Branch> branches = new ArrayList<>();    // 所有树的所有枝
ArrayList<Leaf>   leaves   = new ArrayList<>();    // 所有树的所有叶
ArrayList<TreeInfo> trees  = new ArrayList<>();    // 每棵树的信息

class Range { int start, end; Range(int s, int e){ start=s; end=e; } }
class TreeInfo {
  PVector root; Range range;
  int depthMax; float angleSpread, lenDecayMin, lenDecayMax, height;
  TreeInfo(PVector root, Range range, int dMax, float aSpread, float ldMin, float ldMax, float h){
    this.root=root; this.range=range; this.depthMax=dMax; this.angleSpread=aSpread;
    this.lenDecayMin=ldMin; this.lenDecayMax=ldMax; this.height=h;
  }
}

// 地面落叶层
PGraphics groundLayer;

// —— 风与麦克风（更垂直的落叶效果） ——
float windT = 0;          // 噪声时间（微风）
PVector wind = new PVector(0, 0);
AudioIn mic; Amplitude amp;
float level = 0, levelSmooth = 0;    // 麦克风音量
float blowThreshold = 0.06;          // 触发吹动阈值（可调）

// —— 当前树生成参数（在种树时写入，subdivide 使用） ——
int   curDepthMax = 4;        // 分支深度
float curAngleSpread = 28;    // 分叉角度（度）
float curLenDecayMin = 0.62;  // 子枝长度衰减范围
float curLenDecayMax = 0.78;

void settings(){ size(W, H, P2D); smooth(8); }

void setup(){
  surface.setTitle("Falling Leaves Forest — v1.5");
  groundLayer = createGraphics(W, H, P2D);
  drawSky();

  // 麦克风
  mic = new AudioIn(this, 0);
  amp = new Amplitude(this);
  mic.start();
  amp.input(mic);
}

void draw(){
  drawSky();
  image(groundLayer, 0, 0);
  updateWind();
  drawTreesAndBranches();

  for (Leaf lf : leaves){ lf.update(); lf.display(); }
}

// ====== 背景/地面（DIY：形状/颜色在此改） ======
void drawSky(){
  noStroke();
  for (int y=0; y<H; y++){
    stroke(lerpColor(SKY_TOP, SKY_BOT, y/(float)H));
    line(0, y, W, y);
  }
  noStroke(); fill(GROUND);             // 地面色带高度可改（例如 H*0.84）
  rect(0, H*0.7, W, H*0.34);
}

// ====== 交互 ======
void mousePressed(){ plantTree(mouseX); }  // 点击种树（x 定位）

void keyPressed(){
  if (key=='R' || key=='r'){
    branches.clear(); leaves.clear(); trees.clear();
    groundLayer.beginDraw(); groundLayer.clear(); groundLayer.endDraw();
  }
}

// ====== 种树 / 造型随机 ======
void plantTree(float x){
  PVector root = new PVector(constrain(x, 60, W-60), H*0.82);
  // 每棵树一套随机“造型参数”
  float treeH = random(240, 460);
  curDepthMax    = int(random(4, 6));      // 4–5 层
  curAngleSpread = random(20, 46);         // 分叉角度
  curLenDecayMin = random(0.60, 0.70);
  curLenDecayMax = random(0.72, 0.82);

  int start = branches.size();
  buildTreeAt(root, treeH);
  int end   = branches.size()-1;
  trees.add(new TreeInfo(root, new Range(start, end), curDepthMax, curAngleSpread, curLenDecayMin, curLenDecayMax, treeH));

  int branchCount = end - start + 1;
  growLeavesOnRange(start, end, int(branchCount*1.0));
}

// 生成枝干（主干 + 递归分叉）
void buildTreeAt(PVector root, float treeH){
  Branch trunk = new Branch(root.copy(), PVector.fromAngle(radians(-90)).mult(treeH*0.36), 8);
  branches.add(trunk);
  subdivide(trunk, 0);
}

void subdivide(Branch b, int depth){
  if (depth > curDepthMax) return;
  int n = (depth < 2) ? int(random(2,4)) : int(random(1,3));
  for (int i=0; i<n; i++){
    float ang = radians(random(-curAngleSpread, curAngleSpread)) + map(depth,0,curDepthMax,0.0,0.12)*(i-0.5);
    float len = b.dir.mag() * random(curLenDecayMin, curLenDecayMax);
    PVector dir = b.dir.copy().rotate(ang).setMag(len);
    Branch c = new Branch(PVector.add(b.base, b.dir), dir, max(2, b.thick*0.7));
    branches.add(c);
    subdivide(c, depth + 1);
  }
}

// 在指定分支范围长叶（仅秋色）
void growLeavesOnRange(int start, int end, int n){
  for(int i=0;i<n;i++){
    int bi = int(lerp(start, end, pow(random(1), 2.2))); // 偏向末端但覆盖全树
    Branch b = branches.get(constrain(bi, start, end));
    PVector anchor = PVector.add(b.base, b.dir).copy();
    anchor.add(random(-8,8), random(-8,8));
    float size = random(10, 22);
    color col = pickAutumnColor();
    leaves.add(new Leaf(anchor, size, col));
  }
}

color pickAutumnColor(){
  int i = int(random(PAL_AUTUMN.length-1));
  float u = random(1);
  return lerpColor(PAL_AUTUMN[i], PAL_AUTUMN[i+1], u);
}

// ====== 风：噪声 + 吹气（横向分量少，使落叶更垂直） ======
void updateWind(){
  level = amp.analyze();
  levelSmooth = lerp(levelSmooth, level, 0.35);
  float over = max(0, levelSmooth - blowThreshold);
  float strength = constrain(map(over, 0, 0.18, 0, 2.8), 0, 2.8);
  windT += 0.01; float n = noise(windT) - 0.5;
  PVector breeze = new PVector(n*0.10, -0.02);
  wind = PVector.add(breeze, new PVector(strength*0.30, 0));
}

// ====== 绘制树（影子 + 枝干） ======
void drawTreesAndBranches(){
  noStroke(); fill(0,10);
  for (TreeInfo t : trees){ ellipse(t.root.x, t.root.y+16, 160, 40); }
  stroke(#6E4C3A); strokeCap(ROUND);
  for (Branch b : branches){ strokeWeight(b.thick); line(b.base.x, b.base.y, b.base.x+b.dir.x, b.base.y+b.dir.y); }
}

// ====== 类定义 ======
class Branch{ PVector base, dir; float thick; Branch(PVector base, PVector dir, float thick){ this.base=base; this.dir=dir; this.thick=thick; } }

class Leaf{
  static final int ATTACHED=0, FALLING=1, LANDED=2; int state = ATTACHED;
  PVector anchor, p, v; float angle, spin, size, flex, hold; color col;
  Leaf(PVector anchor, float size, color col){ this.anchor=anchor; this.size=size; this.col=col; p=anchor.copy(); v=new PVector(); angle=random(TWO_PI); flex=random(0.06,0.16); hold=random(0.5,1.4);}  
  void update(){
    if (state==ATTACHED){
      angle += wind.x*0.02 + (noise(p.x*0.01, frameCount*0.01)-0.5)*0.03;
      float pull = abs(wind.x)*(0.9+random(0,0.2));
      float over = max(0, levelSmooth - blowThreshold);
      float prob = constrain(map(over, 0, 0.18, 0.05, 0.9), 0, 0.95);
      if (pull > 0.28*hold && random(1) < prob) detach();
      p = PVector.add(anchor, new PVector(sin(angle)*2.0, cos(angle)*1.2));
    } else if (state==FALLING){
      v.y += 0.05;           // 垂直重力
      v.x += wind.x*0.02;    // 少量水平
      spin += (noise(frameCount*0.02, hash(this))*0.4 - 0.2);
      angle += spin*0.06 + wind.x*0.02;
      v.mult(0.992); p.add(v);
      if (p.y > H*0.86 - 4) land();
    }
  }
  float hash(Leaf l){ return (l.anchor.x*0.13 + l.anchor.y*0.37) % 10.0; }
  void detach(){ state=FALLING; v=new PVector(wind.x*0.6+random(-0.3,0.3), random(-0.6,-1.2)); spin=random(-0.6,0.6); }
  void land(){ state=LANDED; groundLayer.beginDraw(); groundLayer.pushMatrix(); groundLayer.translate(p.x, H*0.86 - 2 + random(-1,1)); groundLayer.rotate(angle*0.5); drawLeafShape(groundLayer, size, col, 150); groundLayer.popMatrix(); groundLayer.endDraw(); }
  void display(){ if (state==LANDED) return; pushMatrix(); translate(p.x, p.y); rotate(angle*0.5); drawLeafShape(g, size, col, (state==ATTACHED?220:200)); popMatrix(); }
}

// 叶片造型（DIY：换贝塞尔点可做不同叶形）
void drawLeafShape(PGraphics g, float s, color c, float alpha){
  g.noStroke(); g.fill(red(c),green(c),blue(c),alpha);
  g.beginShape();
  g.vertex(0,0);
  g.bezierVertex(s*0.6,-s*0.2, s*0.7,-s*0.9, 0,-s*1.2);
  g.bezierVertex(-s*0.7,-s*0.9, -s*0.6,-s*0.2, 0,0);
  g.endShape(CLOSE);
  // 叶脉
  g.stroke(0,40); g.strokeWeight(1); g.line(0,-s*1.05, 0,-s*0.05);
  g.stroke(0,28); g.line(0,-s*0.7,  s*0.32,-s*0.46); g.line(0,-s*0.7, -s*0.32,-s*0.46);
}
